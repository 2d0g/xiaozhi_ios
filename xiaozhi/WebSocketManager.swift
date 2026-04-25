import Foundation

class WebSocketManager: NSObject, ObservableObject, URLSessionWebSocketDelegate {
    static let shared = WebSocketManager()
    @Published var isConnected = false
    @Published var isConnecting = false
    @Published var errorMessage: String?
    
    private var webSocketTask: URLSessionWebSocketTask?
    private lazy var session: URLSession = {
        return URLSession(configuration: .default, delegate: self, delegateQueue: .main)
    }()
    
    func connect(url: String, token: String) {
        var cleanURL = url
        if cleanURL.hasSuffix("/") { cleanURL.removeLast() }
        
        guard let serverURL = URL(string: cleanURL) else { return }
        if isConnected || isConnecting { return }
        
        isConnecting = true
        errorMessage = nil
        print(">>> 正在建立 WebSocket 连接: \(cleanURL)")
        
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
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("✅ WebSocket 链路已成功升级 (HTTP 101)")
        // 链路通了，立刻发业务握手
        self.sendHello()
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            let nsError = error as NSError
            // 过滤掉正常的握手切换状态或取消状态
            if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled { return }
            
            print("!!! WebSocket 链路异常 [Code \(nsError.code)]: \(nsError.localizedDescription)")
            
            DispatchQueue.main.async {
                self.isConnected = false
                self.isConnecting = false
                self.errorMessage = error.localizedDescription
            }
        }
    }

    private func setupPing() {
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.webSocketTask?.sendPing { error in
                if let _ = error { print("!!! Ping 失败，链路可能已断开") }
            }
        }
    }

    private func sendHello() {
        print(">>> 发送业务 hello 报文...")
        let hello: [String: Any] = [
            "type": "hello",
            "version": 1,
            "transport": "websocket",
            "audio_params": ["format": "opus", "sample_rate": 24000, "channels": 1, "frame_duration": 20]
        ]
        sendJson(hello)
    }
    
    func sendListenStart() {
        guard isConnected else { print("!!! 警告：尚未握手成功，拒绝发送 listen.start"); return }
        sendJson(["type": "listen", "state": "start", "mode": "auto"])
    }
    
    func sendListenStop() {
        guard isConnected else { return }
        sendJson(["type": "listen", "state": "stop"])
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
            webSocketTask?.send(.string(str)) { error in
                if let error = error { print("!!! JSON 发送失败: \(error)") }
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
        print("<<< 收到信令: \(text)")
        if text.contains("\"type\":\"hello\"") {
            DispatchQueue.main.async {
                print("🎉 小智业务握手成功，现在可以开始对话了！")
                self.isConnected = true
                self.isConnecting = false
            }
        }
    }
    
    private func handleAudio(_ data: Data) {
        AudioEngineManager.shared.playAIResponse(data: data)
    }
}
