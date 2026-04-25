import Foundation
import AVFoundation

class AudioEngineManager: ObservableObject {
    static let shared = AudioEngineManager()
    private var audioEngine = AVAudioEngine()
    private var playerNode = AVAudioPlayerNode()
    @Published var isRecording = false
    
    // 逻辑层切换到 16kHz，与参考项目一致
    private let logicFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16000, channels: 1, interleaved: false)!
    
    private let opusFormat: AVAudioFormat = {
        var asbd = AudioStreamBasicDescription(
            mSampleRate: 16000, mFormatID: kAudioFormatOpus, mFormatFlags: 0,
            mBytesPerPacket: 0, mFramesPerPacket: 960, // 60ms @ 16kHz = 960 frames
            mBytesPerFrame: 0, mChannelsPerFrame: 1, mBitsPerChannel: 0, mReserved: 0
        )
        return AVAudioFormat(streamDescription: &asbd)!
    }()
    
    private var encoder: AVAudioConverter?
    private var decoder: AVAudioConverter?

    init() {
        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: logicFormat)
        decoder = AVAudioConverter(from: opusFormat, to: logicFormat)
        
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetooth])
        try? session.setActive(true)
        audioEngine.prepare()
    }

    func start() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if granted { DispatchQueue.main.async { self.performStart() } }
        }
    }

    private func performStart() {
        let session = AVAudioSession.sharedInstance()
        try? session.setActive(true)
        
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        
        // 稳健探测
        if inputFormat.sampleRate <= 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { self.performStart() }
            return
        }
        
        inputNode.removeTap(onBus: 0)
        encoder = AVAudioConverter(from: inputFormat, to: opusFormat)
        
        // 采用 16k 识别更准
        inputNode.installTap(onBus: 0, bufferSize: 4800, format: inputFormat) { [weak self] buffer, _ in
            guard let self = self, let enc = self.encoder else { return }
            let outBuffer = AVAudioCompressedBuffer(format: self.opusFormat, packetCapacity: 8, maximumPacketSize: 1024)
            var error: NSError?
            if enc.convert(to: outBuffer, error: &error, withInputFrom: { _, outStatus in outStatus.pointee = .haveData; return buffer }) == .haveData {
                if outBuffer.byteLength > 0 && WebSocketManager.shared.isConnected {
                    WebSocketManager.shared.sendAudioData(Data(bytes: outBuffer.data, count: Int(outBuffer.byteLength)))
                }
            }
        }
        
        if !audioEngine.isRunning { try? audioEngine.start() }
        isRecording = true
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
        // 60ms @ 16kHz = 960
        inBuffer.packetDescriptions?.pointee = AudioStreamPacketDescription(mStartOffset: 0, mVariableFramesInPacket: 960, mDataByteSize: UInt32(data.count))
        
        let outBuffer = AVAudioPCMBuffer(pcmFormat: logicFormat, frameCapacity: 1024)!
        var error: NSError?
        
        if dec.convert(to: outBuffer, error: &error, withInputFrom: { _, outStatus in outStatus.pointee = .haveData; return inBuffer }) == .haveData {
            if !audioEngine.isRunning { try? audioEngine.start() }
            if !playerNode.isPlaying { playerNode.play() }
            playerNode.scheduleBuffer(outBuffer, at: nil, options: [], completionHandler: nil)
        }
    }
}
