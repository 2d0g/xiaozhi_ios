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
        VStack(spacing: 25) {
            headerSection
            
            if !isFullyActivated {
                identitySection
                activationSection
            } else {
                activatedBusinessSection
            }
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            footerSection
        }
        .padding()
        .onAppear {
            loadInitialData()
        }
    }

    private var headerSection: some View {
        VStack(spacing: 10) {
            Image(systemName: "bolt.shield.fill")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            Text("小智 AI 助手").font(.title).fontWeight(.bold)
        }
        .padding(.top, 40)
    }

    private var identitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("设备身份").font(.headline).foregroundColor(.secondary)
            HStack {
                Text("序列号 (SN):")
                Spacer()
                Text(serialNumber).font(.system(.body, design: .monospaced))
            }
            .padding().background(Color.secondary.opacity(0.1)).cornerRadius(12)
        }
        .padding(.horizontal)
    }

    private var activationSection: some View {
        VStack(spacing: 15) {
            Text("激活状态").font(.headline).frame(maxWidth: .infinity, alignment: .leading)
            VStack(spacing: 5) {
                Text(activationCode).font(.system(size: 48, weight: .heavy, design: .monospaced)).foregroundColor(.accentColor)
                Text("请在管理后台输入此激活码").font(.footnote).foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 30)
            .background(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.accentColor.opacity(0.3), lineWidth: 2).background(Color.accentColor.opacity(0.05)))
            
            Button(action: { self.performOTAHandshake() }) {
                if isActivating { ProgressView() }
                else { Label("获取新激活码", systemImage: "arrow.clockwise") }
            }
            .buttonStyle(BorderedProminentButtonStyle())
        }
        .padding(.horizontal)
    }
    
    private var activatedBusinessSection: some View {
        VStack(spacing: 20) {
            Image(systemName: "waveform.and.mic")
                .font(.system(size: 80))
                .foregroundColor(audioEngine.isRecording ? .red : .green)
            
            Text(audioEngine.isRecording ? "正在听..." : "小智已就绪").font(.headline)
            
            Button(action: { self.toggleAudio() }) {
                Label(audioEngine.isRecording ? "说完了" : "点击说话", systemImage: audioEngine.isRecording ? "checkmark.circle.fill" : "mic.fill")
            }
            .buttonStyle(BorderedProminentButtonStyle())
        }
        .padding(.vertical, 40)
    }

    private var footerSection: some View {
        Text("版本 0.0.3 (Live Audio Enabled)").font(.caption2).foregroundColor(.secondary).padding(.bottom, 10)
    }

    private func toggleAudio() {
        if audioEngine.isRecording {
            audioEngine.stop()
            wsManager.sendListenStop()
        } else {
            wsManager.sendListenStart()
            audioEngine.start()
        }
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
                        wsManager.connect(url: ws.url, token: ws.token)
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
