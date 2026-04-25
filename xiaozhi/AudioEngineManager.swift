import Foundation
import AVFoundation

class AudioEngineManager: ObservableObject {
    static let shared = AudioEngineManager()
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    
    @Published var isRecording = false
    @Published var isListening = true // 默认开启常驻监听
    
    private let nativeFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 48000, channels: 1, interleaved: false)!
    private let wakeFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16000, channels: 1, interleaved: false)!
    
    private var opusDecoder: AVAudioConverter?
    private var wakeResampler: AVAudioConverter?
    private let audioQueue = DispatchQueue(label: "com.xiaozhi.audio.pro", qos: .userInteractive)

    init() {
        self.setupAudioEngine()
        
        // 绑定唤醒成功回调
        WakeWordManager.shared.onWakeWordDetected = { keyword in
            if keyword.contains("天猫精灵") || keyword.contains("小智") {
                self.triggerAIConversation()
            }
        }
    }

    private func setupAudioEngine() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetooth, .mixWithOthers])
            try session.setActive(true)
            
            let engine = AVAudioEngine()
            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: nativeFormat)
            
            var asbd = AudioStreamBasicDescription(mSampleRate: 48000, mFormatID: kAudioFormatOpus, mFormatFlags: 0, mBytesPerPacket: 0, mFramesPerPacket: 960, mBytesPerFrame: 0, mChannelsPerFrame: 1, mBitsPerChannel: 0, mReserved: 0)
            self.opusDecoder = AVAudioConverter(from: AVAudioFormat(streamDescription: &asbd)!, to: nativeFormat)
            
            self.audioEngine = engine
            self.playerNode = player
            
            self.startPassiveListening()
            
            engine.prepare()
            try engine.start()
            player.play()
            print("🚀 iPhone 11 双工语音管线已启动")
        } catch {
            print("!!! 引擎初始化失败: \(error)")
        }
    }

    private func startPassiveListening() {
        guard let engine = self.audioEngine else { return }
        let inputNode = engine.inputNode
        let hwFormat = inputNode.outputFormat(forBus: 0)
        
        self.wakeResampler = AVAudioConverter(from: hwFormat, to: wakeFormat)
        
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 4800, format: hwFormat) { [weak self] buffer, _ in
            self?.audioQueue.async {
                self?.handleMicInput(buffer)
            }
        }
    }

    private func handleMicInput(_ buffer: AVAudioPCMBuffer) {
        guard let resampler = wakeResampler else { return }
        
        // 1. 转换到 16kHz
        let outBuffer = AVAudioPCMBuffer(pcmFormat: wakeFormat, frameCapacity: 1024)!
        var error: NSError?
        let status = resampler.convert(to: outBuffer, error: &error) { _, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }
        
        if status == .haveData {
            // 2. 将 16k 数据喂给唤醒管理器
            let array = Array(UnsafeBufferPointer(start: outBuffer.floatChannelData![0], count: Int(outBuffer.frameLength)))
            WakeWordManager.shared.processAudio(samples: array)
            
            // 3. TODO: 如果当前正在通话模式，则同时也发送给 WebSocket
            // if self.isRecording { WebSocketManager.shared.sendAudioData(...) }
        }
    }
    
    private func triggerAIConversation() {
        print("🔊 唤醒词触发！正在建立 AI 对话...")
        // 这里可以播放一个提示音
        WebSocketManager.shared.sendListenStart()
        DispatchQueue.main.async {
            self.isRecording = true
        }
    }

    func resetPlayback() {
        self.playerNode?.stop()
        if let engine = self.audioEngine, engine.isRunning {
            self.playerNode?.play()
        }
    }
    
    func flushPlayback() {
        // 用于流式播放结束时的清理，直通模式下保持空实现
    }

    func stopRecording() {
        DispatchQueue.main.async {
            self.isRecording = false
        }
    }

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
