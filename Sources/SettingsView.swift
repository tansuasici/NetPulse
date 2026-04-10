import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @State private var launchAtLogin = false

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                // Launch at startup
                HStack {
                    Text("Launch at startup")
                        .font(.system(size: 11))
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { launchAtLogin },
                        set: { newValue in
                            launchAtLogin = newValue
                            setLaunchAtLogin(newValue)
                        }
                    ))
                    .toggleStyle(.switch)
                    .controlSize(.small)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                Rectangle().fill(Color.primary.opacity(0.06)).frame(height: 1)

                // About
                VStack(spacing: 0) {
                    settingsRow(label: "Version", value: "0.2.0")
                    Rectangle().fill(Color.primary.opacity(0.04)).frame(height: 1).padding(.leading, 12)
                    settingsRow(label: "Speed Test", value: "Cloudflare")
                }

                Rectangle().fill(Color.primary.opacity(0.06)).frame(height: 1)
            }

            Spacer()

            // Quit
            Button(action: { NSApp.terminate(nil) }) {
                HStack(spacing: 4) {
                    Image(systemName: "power")
                        .font(.system(size: 9))
                    Text("Quit NetPulse")
                        .font(.system(size: 11, weight: .medium))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
        }
        .onAppear {
            readLaunchAtLoginState()
        }
    }

    private func settingsRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 11))
            Spacer()
            Text(value)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    private func readLaunchAtLoginState() {
        if #available(macOS 13.0, *) {
            launchAtLogin = (SMAppService.mainApp.status == .enabled)
        }
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                launchAtLogin = !enabled
            }
        }
    }
}
