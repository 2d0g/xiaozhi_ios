import SwiftUI

struct ContentView: View {
    @State private var serialNumber: String = "加载中..."
    @State private var activationCode: String = "未获取"
    @State private var isActivating: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 25) {
            headerSection
            
            identitySection
            
            activationSection
            
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

    // MARK: - UI Components
    
    private var headerSection: some View {
        VStack(spacing: 10) {
            Image(systemName: "bolt.shield.fill")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            Text("小智 AI 助手")
                .font(.title)
                .fontWeight(.bold)
        }
        .padding(.top, 40)
    }

    private var identitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("设备身份")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack {
                Text("序列号 (SN):")
                Spacer()
                Text(serialNumber)
                    .font(.system(.body, design: .monospaced))
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }

    private var activationSection: some View {
        VStack(spacing: 15) {
            Text("激活状态")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 5) {
                Text(activationCode)
                    .font(.system(size: 48, weight: .heavy, design: .monospaced))
                    .foregroundColor(.accentColor)
                
                Text("请在管理后台输入此激活码")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 30)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.accentColor.opacity(0.3), lineWidth: 2)
                    .background(Color.accentColor.opacity(0.05))
            )
            
            Button(action: performOTAHandshake) {
                if isActivating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Label("获取新激活码", systemImage: "arrow.clockwise")
                }
            }
            .disabled(isActivating)
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(.horizontal)
    }

    private var footerSection: some View {
        Text("版本 1.0.0 (OTA Ready)")
            .font(.caption2)
            .foregroundColor(.secondary)
            .padding(.bottom, 10)
    }

    // MARK: - Logic
    
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
                        self.errorMessage = nil
                    } else if response.websocket != nil {
                        self.activationCode = "已激活"
                        self.errorMessage = "设备已就绪，请进行下一步"
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

#Preview {
    ContentView()
}
