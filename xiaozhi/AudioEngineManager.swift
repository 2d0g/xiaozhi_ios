import Foundation
import AVFoundation

class AudioEngineManager: ObservableObject {
    static let shared = AudioEngineManager()
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    
    // 强制使用 48kHz 原生频率，彻底消灭语速慢和重采样开销
    private let nativeFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 48000, channels: 1, interleaved: false)!
    
    private let opusFormat: AVAudioFormat = {
        var asbd = AudioStreamBasicDescription(
            mSampleRate: 48000, mFormatID: kAudioFormatOpus, mFormatFlags: 0,
            mBytesPerPacket: 0, mFramesPerPacket: 960, // 20ms @ 48kHz = 960
            mBytesPerFrame: 0, mChannelsPerFrame: 1, mBitsPerChannel: 0, mReserved: 0
        )
        return AVAudioFormat(streamDescription: &asbd)!
    }()
    
    private var opusDecoder: AVAudioConverter?
    
    // 高性能音频处理线程
    private let audioQueue = DispatchQueue(label: "com.xiaozhi.audio.pro", qos: .userInteractive)

    init() {
        self.setupNativeEngine()
    }

    private func setupNativeEngine() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
            
            let engine = AVAudioEngine()
            let player = AVAudioPlayerNode()
            engine.attach(player)
            
            // 直接以 48kHz 连接，这是 iPhone 11 的物理舒适区
            engine.connect(player, to: engine.mainMixerNode, format: nativeFormat)
            
            self.opusDecoder = AVAudioConverter(from: opusFormat, to: nativeFormat)
            self.audioEngine = engine
            self.playerNode = player
            
            engine.prepare()
            try engine.start()
            player.play()
            print("🚀 iPhone 11 物理直通播放管线已激活 (48kHz)")
        } catch {
            print("!!! 引擎初始化失败: \(error)")
        }
    }
    
    func resetPlayback() {}
    func flushPlayback() {}
    
    func playAIResponse(data: Data) {
        audioQueue.async {
            guard let dec = self.opusDecoder, let player = self.playerNode else { return }
            
            // 构造输入缓冲区 (告诉系统这是 48k 的包，让它解出 960 帧)
            let inBuffer = AVAudioCompressedBuffer(format: self.opusFormat, packetCapacity: 1, maximumPacketSize: data.count)
            inBuffer.byteLength = UInt32(data.count)
            inBuffer.packetCount = 1
            data.copyBytes(to: inBuffer.data.assumingMemoryBound(to: UInt8.self), count: data.count)
            inBuffer.packetDescriptions?.pointee = AudioStreamPacketDescription(mStartOffset: 0, mVariableFramesInPacket: 960, mDataByteSize: UInt32(data.count))
            
            let outBuffer = AVAudioPCMBuffer(pcmFormat: self.nativeFormat, frameCapacity: 1024)!
            var error: NSError?
            
            let status = dec.convert(to: outBuffer, error: &error) { _, outStatus in 
                outStatus.pointee = .haveData
                return inBuffer 
            }
            
            if status == .haveData && outBuffer.frameLength > 0 {
                // 采用最原始的 scheduleBuffer，不带选项，利用 playerNode 内部的硬件缓冲区进行平滑
                player.scheduleBuffer(outBuffer, at: nil, options: [], completionHandler: nil)
                
                if !player.isPlaying {
                    player.play()
                }
            }
        }
    }
}
