import SwiftUI

struct ContentView: View {
    @ObservedObject private var wsManager = WebSocketManager.shared
    @ObservedObject private var audioEngine = AudioEngineManager.shared
    
    @State private var serialNumber: String = "加载中..."
    @State private var activationCode: String = "未获取"
    @State private var isActivating: Bool = false
    @State private var errorMessage: String?
    @State private var isFullyActivated: Bool = false

    var body: some View {
        VStack(spacing: 25) {
            headerSection
            
            if !isFullyActivated {
                identitySection
                activationSection
            } else {
                dialogueSection
            }
            
            if let error = errorMessage {
                Text(error).font(.caption).foregroundColor(.red).padding(.horizontal)
            }
            Spacer()
            footerSection
        }
        .padding()
        .onAppear { loadInitialData() }
    }

    private var dialogueSection: some View {
        VStack(spacing: 20) {
            Image(systemName: "waveform.and.mic")
                .font(.system(size: 60))
                .foregroundColor(audioEngine.isRecording ? .red : .green)
                .padding(.top)
            
            VStack(alignment: .leading, spacing: 15) {
                if !wsManager.userText.isEmpty {
                    VStack(alignment: .trailing) {
                        Text("我:").font(.caption).foregroundColor(.secondary).frame(maxWidth: .infinity, alignment: .trailing)
                        Text(wsManager.userText).padding(10).background(Color.accentColor.opacity(0.1)).cornerRadius(10)
                    }
                }
                
                if !wsManager.aiText.isEmpty {
                    VStack(alignment: .leading) {
                        Text("小智:").font(.caption).foregroundColor(.secondary)
                        Text(wsManager.aiText).padding(10).background(Color.secondary.opacity(0.1)).cornerRadius(10)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(RoundedRectangle(cornerRadius: 15).stroke(Color.secondary.opacity(0.2)))
            
            Button(action: { self.toggleAudio() }) {
                Label(audioEngine.isRecording ? "说完了" : "点击说话", systemImage: audioEngine.isRecording ? "checkmark.circle.fill" : "mic.fill")
                    .font(.headline).padding()
            }
            .buttonStyle(BorderedProminentButtonStyle())
        }
    }

    private var headerSection: some View {
        VStack(spacing: 10) {
            Image(systemName: "bolt.shield.fill").font(.system(size: 60)).foregroundColor(.accentColor)
            Text("小智 AI 助手").font(.title).fontWeight(.bold)
        }.padding(.top, 20)
    }

    private var identitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("设备身份").font(.headline).foregroundColor(.secondary)
            HStack {
                Text("序列号 (SN):")
                Spacer()
                Text(serialNumber).font(.system(.body, design: .monospaced))
            }.padding().background(Color.secondary.opacity(0.1)).cornerRadius(12)
        }.padding(.horizontal)
    }

    private var activationSection: some View {
        VStack(spacing: 15) {
            Text(activationCode).font(.system(size: 48, weight: .heavy, design: .monospaced)).foregroundColor(.accentColor)
            Button(action: { self.performOTAHandshake() }) {
                if isActivating { ProgressView() }
                else { Label("获取新激活码", systemImage: "arrow.clockwise") }
            }.buttonStyle(BorderedProminentButtonStyle())
        }.padding(.horizontal)
    }

    private var footerSection: some View {
        Text("版本 0.0.4 (Text Visualizer Enabled)").font(.caption2).foregroundColor(.secondary)
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
        Task {
            do {
                let response = try await OTAService.shared.handshake()
                await MainActor.run {
                    if let act = response.activation { self.activationCode = act.code }
                    else if let ws = response.websocket {
                        withAnimation { self.isFullyActivated = true }
                        wsManager.connect(url: ws.url, token: ws.token)
                    }
                    self.isActivating = false
                }
            } catch {
                await MainActor.run { self.errorMessage = "错误: \(error.localizedDescription)"; self.isActivating = false }
            }
        }
    }
}
