import Foundation
import AVFoundation

class AudioEngineManager: ObservableObject {
    static let shared = AudioEngineManager()
    private var audioEngine = AVAudioEngine()
    private var playerNode = AVAudioPlayerNode()
    @Published var isRecording = false
    
    private let targetPcmFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 24000, channels: 1, interleaved: false)!
    private let opusFormat: AVAudioFormat = {
        var asbd = AudioStreamBasicDescription(
            mSampleRate: 24000, mFormatID: kAudioFormatOpus, mFormatFlags: 0,
            mBytesPerPacket: 0, mFramesPerPacket: 480, mBytesPerFrame: 0,
            mChannelsPerFrame: 1, mBitsPerChannel: 0, mReserved: 0
        )
        return AVAudioFormat(streamDescription: &asbd)!
    }()
    
    private var encoder: AVAudioConverter?
    private var decoder: AVAudioConverter?

    init() {
        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: targetPcmFormat)
        decoder = AVAudioConverter(from: opusFormat, to: targetPcmFormat)
    }

    func start() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
            
            let inputNode = audioEngine.inputNode
            let inputFormat = inputNode.outputFormat(forBus: 0)
            
            print("🎙️ 录音尝试启动，格式: \(inputFormat.sampleRate)Hz")
            
            // 还原：先安装 Tap
            inputNode.removeTap(onBus: 0)
            encoder = AVAudioConverter(from: inputFormat, to: opusFormat)
            
            inputNode.installTap(onBus: 0, bufferSize: 4800, format: inputFormat) { [weak self] buffer, _ in
                guard let self = self, let enc = self.encoder else { return }
                let outBuffer = AVAudioCompressedBuffer(format: self.opusFormat, packetCapacity: 8, maximumPacketSize: 1024)
                var error: NSError?
                let status = enc.convert(to: outBuffer, error: &error) { _, outStatus in
                    outStatus.pointee = .haveData
                    return buffer
                }
                if status == .haveData && outBuffer.byteLength > 0 {
                    let data = Data(bytes: outBuffer.data, count: Int(outBuffer.byteLength))
                    if WebSocketManager.shared.isConnected {
                        WebSocketManager.shared.sendAudioData(data)
                    }
                }
            }
            
            // 后启动引擎
            audioEngine.prepare()
            try audioEngine.start()
            isRecording = true
        } catch {
            print("!!! 引擎启动失败: \(error)")
        }
    }
    
    func stop() {
        audioEngine.inputNode.removeTap(onBus: 0)
        isRecording = false
    }
    
    func playAIResponse(data: Data) {
        guard let dec = decoder else { return }
        
        let inBuffer = AVAudioCompressedBuffer(format: opusFormat, packetCapacity: 1, maximumPacketSize: data.count)
        inBuffer.byteLength = UInt32(data.count); inBuffer.packetCount = 1
        data.copyBytes(to: inBuffer.data.assumingMemoryBound(to: UInt8.self), count: data.count)
        inBuffer.packetDescriptions?.pointee = AudioStreamPacketDescription(mStartOffset: 0, mVariableFramesInPacket: 480, mDataByteSize: UInt32(data.count))
        
        let outBuffer = AVAudioPCMBuffer(pcmFormat: targetPcmFormat, frameCapacity: 1024)!
        var error: NSError?
        
        if dec.convert(to: outBuffer, error: &error, withInputFrom: { _, outStatus in 
            outStatus.pointee = .haveData
            return inBuffer 
        }) == .haveData {
            if !audioEngine.isRunning { try? audioEngine.start() }
            if !playerNode.isPlaying { playerNode.play() }
            playerNode.scheduleBuffer(outBuffer, at: nil, options: [])
            print("🔊 正在播放分片: \(outBuffer.frameLength) 采样")
        }
    }
}
