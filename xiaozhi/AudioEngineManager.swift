import Foundation
import AVFoundation
import Accelerate

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
                print("🔄 业务断开，重启唤醒并重置状态")
                self?.isAISpeaking = false
                self?.stopRecording()
                WakeWordManager.shared.startEngine()
            }
        }
        WakeWordManager.shared.onWakeWordDetected = { [weak self] keyword in
            print("🎯 命中关键词: \(keyword)")
            DispatchQueue.main.async {
                self?.lastDetectedKeyword = keyword
                self?.triggerAIConversation()
            }
        }
    }

    private func setupAudioEngine() {
        do {
            let session = AVAudioSession.sharedInstance()
            
            // 监听路由变化（蓝牙连接/断开）
            NotificationCenter.default.addObserver(self, selector: #selector(handleRouteChange), name: AVAudioSession.routeChangeNotification, object: nil)
            
            // 监听音频打断（电话、闹钟等）
            NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption), name: AVAudioSession.interruptionNotification, object: nil)
            
            // 尝试：移除 .defaultToSpeaker，看看是否能优先连接蓝牙
            // 如果移除后蓝牙可用了，说明 .defaultToSpeaker 在某些设备上权重过高
            try session.setCategory(.playAndRecord, 
                                  mode: .default, 
                                  options: [.allowBluetooth, .allowBluetoothA2DP])
            
            if session.isInputGainSettable { try? session.setInputGain(1.0) }
            
            // 优化：请求 16kHz 硬件采样率，减少输入端重采样开销
            try? session.setPreferredSampleRate(16000)
            try session.setPreferredIOBufferDuration(0.01)
            try session.setActive(true)
            
            // 检查当前路由，如果既不是蓝牙也不是耳机，再手动切到扬声器
            let currentRoute = session.currentRoute
            let isBluetooth = currentRoute.outputs.contains { $0.portType == .bluetoothA2DP || $0.portType == .bluetoothHFP }
            let isHeadphones = currentRoute.outputs.contains { $0.portType == .headphones }
            
            if !isBluetooth && !isHeadphones {
                print("ℹ️ 未检测到蓝牙或耳机，手动切到扬声器")
                try? session.overrideOutputAudioPort(.speaker)
            }
            
            let engine = AVAudioEngine()
            let player = AVAudioPlayerNode()
            engine.attach(player)
            
            player.volume = 1.0
            engine.mainMixerNode.outputVolume = 1.0
            
            // 播放链路保持 48kHz 以确保在各种音频设备上播放丝滑
            engine.connect(player, to: engine.mainMixerNode, format: nativeFormat)
            
            var asbd = AudioStreamBasicDescription(mSampleRate: 16000, mFormatID: kAudioFormatOpus, mFormatFlags: 0, mBytesPerPacket: 0, mFramesPerPacket: 320, mBytesPerFrame: 0, mChannelsPerFrame: 1, mBitsPerChannel: 0, mReserved: 0)
            self.opusDecoder = AVAudioConverter(from: AVAudioFormat(streamDescription: &asbd)!, to: nativeFormat)
            
            self.audioEngine = engine; self.playerNode = player
            self.startPassiveListening()
            
            engine.prepare(); try engine.start(); player.play()
            print("🚀 音频引擎已启动：混合采样率模式 (Input: 16k, Output: 48k)")
        } catch { print("!!! 引擎失败: \(error)") }
    }

    private func startPassiveListening() {
        guard let engine = self.audioEngine else { return }
        let inputNode = engine.inputNode
        let hwFormat = inputNode.outputFormat(forBus: 0)
        
        // 只有当硬件采样率不等于 16kHz 时才需要重采样器
        if hwFormat.sampleRate != 16000 {
            print("ℹ️ 硬件采样率为 \(hwFormat.sampleRate), 开启软件重采样至 16kHz")
            self.wakeResampler = AVAudioConverter(from: hwFormat, to: wakeFormat)
        } else {
            print("✅ 硬件采样率已成功设为 16kHz, 消灭软件重采样")
            self.wakeResampler = nil
        }
        
        inputNode.installTap(onBus: 0, bufferSize: 1600, format: hwFormat) { [weak self] buffer, _ in
            self?.audioQueue.async { self?.handleMicInput(buffer) }
        }
    }

    private func getResampledSamples(_ buffer: AVAudioPCMBuffer) -> [Float]? {
        // 如果硬件已经是 16kHz，直接提取数据，跳过转换逻辑
        if buffer.format.sampleRate == 16000 {
            guard let channelData = buffer.floatChannelData?[0] else { return nil }
            return Array(UnsafeBufferPointer(start: channelData, count: Int(buffer.frameLength)))
        }
        
        guard let resampler = wakeResampler else { 
            // 理论上不应该走到这里，除非硬件采样率在运行中变化了且没有重置监听
            guard let channelData = buffer.floatChannelData?[0] else { return nil }
            return Array(UnsafeBufferPointer(start: channelData, count: Int(buffer.frameLength)))
        }
        
        let ratio = 16000.0 / buffer.format.sampleRate
        let outCapacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 100
        guard let outBuffer = AVAudioPCMBuffer(pcmFormat: wakeFormat, frameCapacity: outCapacity) else { return nil }
        var error: NSError?
        resampler.convert(to: outBuffer, error: &error) { _, outStatus in outStatus.pointee = .haveData; return buffer }
        return Array(UnsafeBufferPointer(start: outBuffer.floatChannelData![0], count: Int(outBuffer.frameLength)))
    }

    private func processWakeWordDetection(_ buffer: AVAudioPCMBuffer) {
        if !self.accumulationBuffer.isEmpty { self.accumulationBuffer.removeAll() }
        if let samples = getResampledSamples(buffer) {
            if WakeWordManager.shared.isActive {
                WakeWordManager.shared.processAudio(samples: samples)
            }
        }
    }

    private func processRecordingData(_ samples: [Float]) {
        self.accumulationBuffer.append(contentsOf: samples)
        while self.accumulationBuffer.count >= opusFrameSize {
            let frame = Array(self.accumulationBuffer[0..<opusFrameSize])
            self.accumulationBuffer.removeFirst(opusFrameSize)
            
            // 发送端增益：使用 Accelerate vDSP 保持 8.0 倍增益和限幅
            var boostedFrame = frame
            var gain: Float = 8.0
            var low: Float = -1.0
            var high: Float = 1.0
            vDSP_vsmul(boostedFrame, 1, &gain, &boostedFrame, 1, vDSP_Length(boostedFrame.count))
            vDSP_vclip(boostedFrame, 1, &low, &high, &boostedFrame, 1, vDSP_Length(boostedFrame.count))
            
            if let encodedData = opusEncoder.encode(pcm: boostedFrame) {
                WebSocketManager.shared.sendAudioData(encodedData)
                self.txCount += 1
            }
        }
    }

    private func handleMicInput(_ buffer: AVAudioPCMBuffer) {
        // 1. 如果正在 AI 说话，或者正在录音发送到服务器，彻底跳过唤醒检测及其前置计算
        if self.isAISpeaking || self.isRecording {
            // 如果正在录音且连接正常，只处理发送逻辑，不处理唤醒逻辑
            if self.isRecording && WebSocketManager.shared.isConnected && !self.isAISpeaking {
                if let resampledSamples = getResampledSamples(buffer) {
                    processRecordingData(resampledSamples)
                }
            } else {
                // 确保在无法录制时清理堆积的缓冲区
                if !self.accumulationBuffer.isEmpty { self.accumulationBuffer.removeAll() }
            }
            return
        }

        // 2. 只有在空闲待机时，才执行重采样和唤醒词检测
        processWakeWordDetection(buffer)
    }
    
    func setAISpeaking(_ speaking: Bool) {
        DispatchQueue.main.async {
            self.isAISpeaking = speaking
            if speaking { print("🤫 AI 播音中...") }
        }
    }

    func triggerAIConversation() {
        self.resetPlayback()
        self.isRecording = false
        WakeWordManager.shared.stopEngine()
        if !WebSocketManager.shared.isConnected {
            WebSocketManager.shared.reconnect()
        } else {
            self.flushBufferToServer()
        }
    }
    
    // 新增：支持纯文本触发对话，跳过唤醒流程
    func triggerTextConversation(text: String) {
        self.resetPlayback()
        self.isRecording = false
        WakeWordManager.shared.stopEngine()
        
        // 保存文本以便在握手完成后发送
        self.lastDetectedKeyword = text
        
        if !WebSocketManager.shared.isConnected {
            WebSocketManager.shared.reconnect()
        } else {
            self.flushBufferToServer()
        }
    }
    
    func flushBufferToServer() {
        print("🚀 链路就绪，补发文字并开启流...")
        WebSocketManager.shared.sendListenStart()
        if !self.lastDetectedKeyword.isEmpty {
            let kw = self.lastDetectedKeyword
            print(">>> [TX Text] 发送文字: \(kw)")
            WebSocketManager.shared.sendText(kw)
            self.lastDetectedKeyword = ""
        }
        DispatchQueue.main.async {
            self.txCount = 0
            self.isRecording = true
            print(">>> 开启实时流传输")
        }
    }

    func resetPlayback() { 
        self.playerNode?.stop()
        self.playerNode?.volume = 1.0 
        self.playerNode?.play() 
    }
    
    func stopRecording() { self.isRecording = false }

    @objc private func handleRouteChange(notification: Notification) {
        let session = AVAudioSession.sharedInstance()
        let outputs = session.currentRoute.outputs
        let reasonValue = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt
        let reason = reasonValue.map { AVAudioSession.RouteChangeReason(rawValue: $0) }
        
        print("🎧 音频路由变更, 原因: \(String(describing: reason)), 当前输出: \(outputs.map { "\($0.portType.rawValue):\($0.portName)" }.joined(separator: ", "))")
        
        // 如果连接了蓝牙设备，确保取消强制扬声器输出
        let hasBluetooth = outputs.contains { $0.portType == .bluetoothA2DP || $0.portType == .bluetoothHFP }
        if hasBluetooth {
            print("🔵 路由包含蓝牙，确保未强制覆盖到扬声器")
            try? session.overrideOutputAudioPort(.none)
        } else if reason == .oldDeviceUnavailable {
            // 如果蓝牙断开了，切回扬声器
            print("🔈 蓝牙已断开，切回扬声器")
            try? session.overrideOutputAudioPort(.speaker)
        }
    }

    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
        
        if type == .began {
            print("📞 音频打断开始，停止录音与播放")
            self.stopRecording()
            self.playerNode?.stop()
            WebSocketManager.shared.disconnect()
        } else if type == .ended {
            print("📞 音频打断结束")
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    print("▶️ 尝试恢复唤醒引擎")
                    WakeWordManager.shared.startEngine()
                }
            }
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
                
                // --- 终极增强：使用 Accelerate vDSP 5.0 倍数级放大 ---
                if let channelData = outBuffer.floatChannelData?[0] {
                    let frameCount = Int(outBuffer.frameLength)
                    var gain: Float = 5.0
                    var low: Float = -1.0
                    var high: Float = 1.0
                    vDSP_vsmul(channelData, 1, &gain, channelData, 1, vDSP_Length(frameCount))
                    vDSP_vclip(channelData, 1, &low, &high, channelData, 1, vDSP_Length(frameCount))
                }
                
                player.scheduleBuffer(outBuffer, at: nil, options: [], completionHandler: nil)
                if !player.isPlaying { player.play() }
            }
        }
    }
}
