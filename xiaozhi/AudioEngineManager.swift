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
            
            engine.connect(player, to: engine.mainMixerNode, format: nativeFormat)
            
            var asbd = AudioStreamBasicDescription(mSampleRate: 48000, mFormatID: kAudioFormatOpus, mFormatFlags: 0, mBytesPerPacket: 0, mFramesPerPacket: 960, mBytesPerFrame: 0, mChannelsPerFrame: 1, mBitsPerChannel: 0, mReserved: 0)
            self.opusDecoder = AVAudioConverter(from: AVAudioFormat(streamDescription: &asbd)!, to: nativeFormat)
            
            self.audioEngine = engine; self.playerNode = player
            self.startPassiveListening()
            
            engine.prepare(); try engine.start(); player.play()
            print("🚀 音频引擎已启动：极限音量增强模式")
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
                
                // 发送端增益：保持 8.0 提高识别灵敏度
                let boostedFrame = frame.map { max(-1.0, min(1.0, $0 * 8.0)) }
                
                if let encodedData = opusEncoder.encode(pcm: boostedFrame) {
                    WebSocketManager.shared.sendAudioData(encodedData)
                    self.txCount += 1
                }
            }
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
                
                // --- 终极增强：5.0 倍数级放大 ---
                if let channelData = outBuffer.floatChannelData?[0] {
                    let frameCount = Int(outBuffer.frameLength)
                    for i in 0..<frameCount {
                        let raw = channelData[i] * 5.0
                        channelData[i] = max(-1.0, min(1.0, raw))
                    }
                }
                
                player.scheduleBuffer(outBuffer, at: nil, options: [], completionHandler: nil)
                if !player.isPlaying { player.play() }
            }
        }
    }
}
