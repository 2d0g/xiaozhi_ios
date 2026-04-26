import Foundation
import AVFoundation

class AudioEngineManager: ObservableObject {
    static let shared = AudioEngineManager()
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    
    @Published var isRecording = false
    private var isAISpeaking = false

    private let nativeFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 48000, channels: 1, interleaved: false)!
    private let wakeFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16000, channels: 1, interleaved: false)!
    
    private var opusDecoder: AVAudioConverter?
    private var wakeResampler: AVAudioConverter?
    private let audioQueue = DispatchQueue(label: "com.xiaozhi.audio.pro", qos: .userInteractive)
    
    private var rollingBuffer: [Float] = [] 
    private let bufferLimit = 16000 * 2
    private var lastDetectedKeyword: String = ""
    private var txCount = 0
    
    private let opusEncoder = OpusEncoder()
    private var accumulationBuffer: [Float] = []
    private let opusFrameSize = 320 // 20ms @ 16kHz

    init() {
        self.setupAudioEngine()
        WebSocketManager.shared.onHandshakeComplete = { [weak self] in
            DispatchQueue.main.async { self?.flushBufferToServer() }
        }
        WebSocketManager.shared.onConnectionLost = { [weak self] in
            DispatchQueue.main.async {
                print("🔄 业务断开，重启唤醒")
                self?.stopRecording()
                WakeWordManager.shared.startEngine()
            }
        }
        WakeWordManager.shared.onWakeWordDetected = { [weak self] keyword in
            print("🎯 唤醒: \(keyword)")
            DispatchQueue.main.async {
                self?.lastDetectedKeyword = keyword
                self?.triggerAIConversation()
            }
        }
    }

    private func setupAudioEngine() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setPreferredIOBufferDuration(0.02)
            try session.setActive(true)
            let engine = AVAudioEngine()
            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: nativeFormat)
            var asbd = AudioStreamBasicDescription(mSampleRate: 48000, mFormatID: kAudioFormatOpus, mFormatFlags: 0, mBytesPerPacket: 0, mFramesPerPacket: 960, mBytesPerFrame: 0, mChannelsPerFrame: 1, mBitsPerChannel: 0, mReserved: 0)
            self.opusDecoder = AVAudioConverter(from: AVAudioFormat(streamDescription: &asbd)!, to: nativeFormat)
            self.audioEngine = engine; self.playerNode = player
            self.startPassiveListening()
            engine.prepare(); try engine.start(); player.play()
        } catch { print("!!! 引擎失败: \(error)") }
    }

    private func startPassiveListening() {
        guard let engine = self.audioEngine else { return }
        let inputNode = engine.inputNode
        let hwFormat = inputNode.outputFormat(forBus: 0)
        self.wakeResampler = AVAudioConverter(from: hwFormat, to: wakeFormat)
        inputNode.installTap(onBus: 0, bufferSize: 4800, format: hwFormat) { [weak self] buffer, _ in
            self?.audioQueue.async { self?.handleMicInput(buffer) }
        }
    }

    private func handleMicInput(_ buffer: AVAudioPCMBuffer) {
        guard let resampler = wakeResampler else { return }
        let ratio = 16000.0 / buffer.format.sampleRate
        let outCapacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 100
        guard let outBuffer = AVAudioPCMBuffer(pcmFormat: wakeFormat, frameCapacity: outCapacity) else { return }
        var error: NSError?
        resampler.convert(to: outBuffer, error: &error) { _, outStatus in outStatus.pointee = .haveData; return buffer }
        let samples = Array(UnsafeBufferPointer(start: outBuffer.floatChannelData![0], count: Int(outBuffer.frameLength)))
        
        if WakeWordManager.shared.isActive {
            WakeWordManager.shared.processAudio(samples: samples)
        }
        
        if self.isRecording && WebSocketManager.shared.isConnected && !self.isAISpeaking {
            self.accumulationBuffer.append(contentsOf: samples)
            while self.accumulationBuffer.count >= opusFrameSize {
                let frame = Array(self.accumulationBuffer[0..<opusFrameSize])
                self.accumulationBuffer.removeFirst(opusFrameSize)
                let boostedFrame = frame.map { max(-1.0, min(1.0, $0 * 3.0)) }
                if let encodedData = opusEncoder.encode(pcm: boostedFrame) {
                    WebSocketManager.shared.sendAudioData(encodedData)
                    self.txCount += 1
                }
            }
            if self.txCount % 60 == 0 && self.txCount > 0 { print(">>> [Streaming] 已发送帧 #\(self.txCount)") }
        } else {
            if !self.accumulationBuffer.isEmpty { self.accumulationBuffer.removeAll() }
        }
    }
    
    func setAISpeaking(_ speaking: Bool) {
        DispatchQueue.main.async {
            self.isAISpeaking = speaking
            if speaking { print("🤫 AI 播音中...") }
        }
    }

    private func triggerAIConversation() {
        self.resetPlayback()
        self.isRecording = false
        WakeWordManager.shared.stopEngine()
        if !WebSocketManager.shared.isConnected {
            WebSocketManager.shared.reconnect()
        } else {
            self.flushBufferToServer()
        }
    }
    
    private func flushBufferToServer() {
        print("🚀 链路就绪，补发文字并开启流...")
        
        // 先发送控制指令
        WebSocketManager.shared.sendListenStart()
        
        // 紧接着发送刚才识别到的词（不再等待）
        if !self.lastDetectedKeyword.isEmpty {
            let kw = self.lastDetectedKeyword
            print(">>> [TX Text] 发送文字: \(kw)")
            WebSocketManager.shared.sendText(kw)
            self.lastDetectedKeyword = ""
        }
        
        self.txCount = 0
        self.isRecording = true
        print(">>> 开启实时流传输")
    }

    func resetPlayback() { self.playerNode?.stop(); self.playerNode?.play() }
    func stopRecording() { self.isRecording = false }

    func playAIResponse(data: Data) {
        audioQueue.async {
            guard let dec = self.opusDecoder, let player = self.playerNode else { return }
            let inBuffer = AVAudioCompressedBuffer(format: dec.inputFormat, packetCapacity: 1, maximumPacketSize: data.count)
            inBuffer.byteLength = UInt32(data.count); inBuffer.packetCount = 1
            data.copyBytes(to: inBuffer.data.assumingMemoryBound(to: UInt8.self), count: data.count)
            inBuffer.packetDescriptions?.pointee = AudioStreamPacketDescription(mStartOffset: 0, mVariableFramesInPacket: 960, mDataByteSize: UInt32(data.count))
            let outBuffer = AVAudioPCMBuffer(pcmFormat: self.nativeFormat, frameCapacity: 1024)!
            var error: NSError?
            if dec.convert(to: outBuffer, error: &error, withInputFrom: { _, outStatus in outStatus.pointee = .haveData; return inBuffer }) == .haveData {
                player.scheduleBuffer(outBuffer, at: nil, options: [], completionHandler: nil)
                if !player.isPlaying { player.play() }
            }
        }
    }
}
