import Foundation

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let role: String // "user" or "ai"
    var text: String
}

class WebSocketManager: NSObject, ObservableObject, URLSessionWebSocketDelegate {
    static let shared = WebSocketManager()
    @Published var isConnected = false
    @Published var isConnecting = false
    @Published var errorMessage: String?
    
    @Published var messages: [ChatMessage] = []
    private var sessionId: String?
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var lastURL: String?
    private var lastToken: String?
    
    var onHandshakeComplete: (() -> Void)?
    var onConnectionLost: (() -> Void)?

    private lazy var session: URLSession = {
        return URLSession(configuration: .default, delegate: self, delegateQueue: .main)
    }()
    
    func connect(url: String, token: String) {
        self.lastURL = url
        self.lastToken = token
        print("📥 已保存服务器凭据，等待语音唤醒后连接...")
    }
    
    func reconnect() {
        guard let urlStr = lastURL, let token = lastToken else { return }
        var cleanURL = urlStr
        if cleanURL.hasSuffix("/") { cleanURL.removeLast() }
        guard let serverURL = URL(string: cleanURL) else { return }
        if isConnected || isConnecting { return }
        
        isConnecting = true
        errorMessage = nil
        print(">>> 正在建立 WebSocket 业务连接: \(cleanURL)")
        
        var request = URLRequest(url: serverURL)
        request.timeoutInterval = 10
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("1", forHTTPHeaderField: "Protocol-Version")
        request.addValue(DeviceFingerprint.shared.getOrGenerateMAC(), forHTTPHeaderField: "Device-Id")
        request.addValue(DeviceFingerprint.shared.getOrGenerateClientID(), forHTTPHeaderField: "Client-Id")
        
        webSocketTask = session.webSocketTask(with: request)
        webSocketTask?.resume()
        
        receiveMessage()
        setupPing()
    }

    func disconnect() {
        print(">>> 手动关闭 WebSocket 连接")
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        self.isConnected = false
        self.isConnecting = false
        self.onConnectionLost?()
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("✅ WebSocket 链路已连接，等待业务 hello...")
        self.sendHello()
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled { return }
            print("!!! WebSocket 链路异常 [Code \(nsError.code)]: \(nsError.localizedDescription)")
            DispatchQueue.main.async {
                self.isConnected = false
                self.isConnecting = false
                self.errorMessage = error.localizedDescription
                self.onConnectionLost?()
            }
        }
    }

    private func setupPing() {
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.webSocketTask?.sendPing { error in
                if let _ = error { print("!!! Ping 失败") }
            }
        }
    }

    private func sendHello() {
        let hello: [String: Any] = [
            "type": "hello",
            "version": 1,
            "transport": "websocket",
            "audio_params": ["format": "opus", "sample_rate": 16000, "channels": 1, "frame_duration": 20]
        ]
        sendJson(hello)
    }
    
    func sendListenStart() {
        guard isConnected else { return }
        sendJson(["type": "listen", "state": "start", "mode": "auto"])
    }
    
    func sendText(_ text: String) {
        guard isConnected else { return }
        let msg: [String: Any] = ["type": "listen", "state": "detect", "text": text, "source": "text"]
        sendJson(msg)
        
        // 关键：将发送的文字立即显示在 UI
        DispatchQueue.main.async {
            self.messages.append(ChatMessage(role: "user", text: text))
        }
    }
    
    func sendAudioData(_ data: Data) {
        guard isConnected else { return }
        webSocketTask?.send(.data(data)) { error in
            if let error = error { print("!!! 音频发送失败: \(error.localizedDescription)") }
        }
    }
    
    private func sendJson(_ dict: [String: Any]) {
        if let data = try? JSONSerialization.data(withJSONObject: dict),
           let str = String(data: data, encoding: .utf8) {
            print(">>> [TX JSON] \(str)")
            webSocketTask?.send(.string(str)) { error in
                if let error = error { print("!!! JSON 发送失败") }
            }
        }
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            if case .success(let message) = result {
                switch message {
                case .string(let text): self.handleJson(text)
                case .data(let data): self.handleAudio(data)
                @unknown default: break
                }
                self.receiveMessage()
            }
        }
    }
    
    private func handleJson(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else { return }
              
        DispatchQueue.main.async {
            if type == "hello" {
                print("🎉 小智业务握手成功")
                self.isConnected = true
                self.isConnecting = false
                self.onHandshakeComplete?()
            } else if type == "stt" {
                if let content = json["text"] as? String {
                    print("<<< [RX STT] \(content)")
                    // 更新或添加用户消息
                    if self.messages.last?.role == "user" {
                        self.messages[self.messages.count - 1].text = content
                    } else {
                        self.messages.append(ChatMessage(role: "user", text: content))
                    }
                }
            } else if type == "tts" {
                let state = json["state"] as? String
                if state == "start" { 
                    AudioEngineManager.shared.setAISpeaking(true)
                    AudioEngineManager.shared.resetPlayback() 
                }
                
                if let content = json["text"] as? String, !content.isEmpty {
                    if state == "sentence_start" || state == "sentence_end" {
                        if state == "sentence_end" { print("<<< [RX TTS] \(content)") }
                        // 更新或添加 AI 消息
                        if self.messages.last?.role == "ai" {
                            self.messages[self.messages.count - 1].text = content
                        } else {
                            self.messages.append(ChatMessage(role: "ai", text: content))
                        }
                    }
                }
                
                if state == "stop" {
                    // 只有收到全局 stop 标志时，才延迟开启下一轮监听
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        if self.isConnected {
                            print("🔄 AI 播报彻底结束，开启下一轮监听...")
                            AudioEngineManager.shared.setAISpeaking(false)
                            self.sendListenStart()
                        }
                    }
                }
            }
        }
    }
    
    private func handleAudio(_ data: Data) {
        AudioEngineManager.shared.playAIResponse(data: data)
    }
}
