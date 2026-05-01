import Foundation
import Accelerate

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
        // 降低复杂度：从 10 降到 5，在移动端大幅节省 CPU，且对语音音质几乎无影响
        swift_opus_set_complexity(enc, 5)
    }
    
    deinit {
        if let enc = encoder {
            opus_encoder_destroy(enc)
        }
    }
    
    func encode(pcm: [Float]) -> Data? {
        guard let enc = encoder else { return nil }
        
        // 1. 使用 Accelerate vDSP 批量转换 Float32 -> Int16
        // 这种向量化操作比 pcm.map 循环快 10-20 倍
        var int16Samples = [Int16](repeating: 0, count: pcm.count)
        var factor: Float = 32767.0
        var mutablePcm = pcm
        
        // 批量放大
        vDSP_vsmul(mutablePcm, 1, &factor, &mutablePcm, 1, vDSP_Length(pcm.count))
        // 批量裁剪并转换为 Int16
        vDSP_vfix16(mutablePcm, 1, &int16Samples, 1, vDSP_Length(pcm.count))
        
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
