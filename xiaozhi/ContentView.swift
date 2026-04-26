import SwiftUI

struct ContentView: View {
    @ObservedObject private var wsManager = WebSocketManager.shared
    @ObservedObject private var audioEngine = AudioEngineManager.shared
    
    @State private var serialNumber: String = "加载中..."
    @State private var activationCode: String = "未获取"
    @State private var isActivating: Bool = false
    @State private var errorMessage: String?
    @State private var isFullyActivated: Bool = false
    @State private var webSocketURL: String = ""
    @State private var webSocketToken: String = ""

    var body: some View {
        VStack(spacing: 15) {
            headerSection
            
            if !isFullyActivated {
                identitySection
                activationSection
                Spacer()
            } else {
                chatSection
                activatedBusinessSection
            }
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            footerSection
        }
        .padding()
        .onAppear {
            loadInitialData()
        }
    }

    private var headerSection: some View {
        VStack(spacing: 5) {
            Image(systemName: "bolt.shield.fill")
                .font(.system(size: 40))
                .foregroundColor(.accentColor)
            Text("小智 AI 助手").font(.title2).fontWeight(.bold)
        }
        .padding(.top, 20)
    }

    private var identitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("设备身份").font(.headline).foregroundColor(.secondary)
            HStack {
                Text("序列号 (SN):")
                Spacer()
                Text(serialNumber).font(.system(.caption, design: .monospaced))
            }
            .padding().background(Color.secondary.opacity(0.1)).cornerRadius(12)
        }
        .padding(.horizontal)
    }

    private var activationSection: some View {
        VStack(spacing: 15) {
            Text("激活状态").font(.headline).frame(maxWidth: .infinity, alignment: .leading)
            VStack(spacing: 5) {
                Text(activationCode).font(.system(size: 40, weight: .heavy, design: .monospaced)).foregroundColor(.accentColor)
                Text("请在管理后台输入此激活码").font(.footnote).foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 20)
            .background(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.accentColor.opacity(0.3), lineWidth: 2).background(Color.accentColor.opacity(0.05)))
            
            Button(action: { self.performOTAHandshake() }) {
                if isActivating { ProgressView() }
                else { Label("获取新激活码", systemImage: "arrow.clockwise") }
            }
            .buttonStyle(BorderedProminentButtonStyle())
        }
        .padding(.horizontal)
    }
    
    private var chatSection: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(wsManager.messages) { msg in
                        HStack {
                            if msg.role == "user" {
                                Spacer()
                                Text(msg.text)
                                    .padding(10)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            } else {
                                Text(msg.text)
                                    .padding(10)
                                    .background(Color.gray.opacity(0.2))
                                    .foregroundColor(.primary)
                                    .cornerRadius(12)
                                Spacer()
                            }
                        }
                        .id(msg.id)
                    }
                }
                .padding(.horizontal)
            }
            .onChange(of: wsManager.messages) { _ in
                if let last = wsManager.messages.last {
                    withAnimation {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RoundedRectangle(cornerRadius: 12).stroke(Color.secondary.opacity(0.2)))
    }
    
    @State private var inputText: String = ""

    private var activatedBusinessSection: some View {
        HStack(spacing: 10) {
            TextField("输入消息发送给小智...", text: $inputText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
                .onSubmit {
                    sendMessage()
                }
            
            Button(action: {
                sendMessage()
            }) {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.accentColor)
                    .clipShape(Circle())
            }
            .padding(.trailing)
        }
        .padding(.bottom, 10)
    }

    private func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        wsManager.sendText(inputText)
        inputText = ""
    }

    private var footerSection: some View {
        Text("版本 0.0.3 (Chat History Enabled)").font(.caption2).foregroundColor(.secondary).padding(.bottom, 5)
    }

    private func loadInitialData() {
        serialNumber = DeviceFingerprint.shared.getOrGenerateSN()
    }

    private func performOTAHandshake() {
        isActivating = true
        errorMessage = nil
        Task {
            do {
                let response = try await OTAService.shared.handshake()
                await MainActor.run {
                    if let act = response.activation {
                        self.activationCode = act.code
                    } else if let ws = response.websocket {
                        self.webSocketURL = ws.url
                        self.webSocketToken = ws.token
                        withAnimation { self.isFullyActivated = true }
                        
                        // 1. 仅保存连接信息，不立即发起网络请求
                        wsManager.connect(url: ws.url, token: ws.token)
                        
                        // 2. 仅开启本地语音唤醒引擎
                        WakeWordManager.shared.startEngine()
                    }
                    self.isActivating = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "握手失败: \(error.localizedDescription)"
                    self.isActivating = false
                }
            }
        }
    }
}
