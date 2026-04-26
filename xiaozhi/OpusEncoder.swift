import Foundation

class OpusEncoder {
    private var encoder: OpaquePointer?
    private let sampleRate: Int32 = 16000
    private let channels: Int32 = 1
    private let frameSize: Int = 320 // 20ms at 16kHz
    
    init() {
        var error: Int32 = 0
        encoder = opus_encoder_create(sampleRate, channels, OPUS_APPLICATION_VOIP, &error)
        guard let enc = encoder, error == OPUS_OK else {
            print("!!! Opus Encoder 开启失败: \(error)")
            return
        }
        
        // 关键配置：设置比特率为 24kbps (16-32kbps 是语音识别黄金区间)
        swift_opus_set_bitrate(enc, 24000)
        // 设置信号类型为语音
        swift_opus_set_signal(enc, OPUS_SIGNAL_VOICE)
        // 复杂度设为最高 10 (Python 默认)，获取最佳音质
        swift_opus_set_complexity(enc, 10)
    }
    
    deinit {
        if let enc = encoder {
            opus_encoder_destroy(enc)
        }
    }
    
    func encode(pcm: [Float]) -> Data? {
        guard let enc = encoder else { return nil }
        
        // 1. Float32 -> Int16 (采用标准 32768 系数)
        let int16Samples = pcm.map { sample -> Int16 in
            let clamped = max(-1.0, min(1.0, sample))
            return Int16(clamped * 32768.0)
        }
        
        // 2. 准备输出缓冲区
        var outputBuffer = [UInt8](repeating: 0, count: 1500)
        
        // 3. 执行编码
        let encodedBytes = int16Samples.withUnsafeBufferPointer { pcmPtr -> Int32 in
            guard let baseAddress = pcmPtr.baseAddress else { return -1 }
            return opus_encode(enc, baseAddress, Int32(frameSize), &outputBuffer, Int32(outputBuffer.count))
        }
        
        if encodedBytes < 0 {
            print("!!! Opus 编码错误: \(encodedBytes)")
            return nil
        }
        
        return Data(outputBuffer[0..<Int(encodedBytes)])
    }
}
