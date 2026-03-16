import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @State private var launchAtLogin = false

    var body: some View {
        Form {
            Section {
                Toggle("Launch at startup", isOn: Binding(
                    get: { launchAtLogin },
                    set: { newValue in
                        launchAtLogin = newValue
                        setLaunchAtLogin(newValue)
                    }
                ))
            }

            Section("About") {
                LabeledContent("Version", value: "0.1.0")
                LabeledContent("Speed Test", value: "Cloudflare")
            }

            Section {
                Button(role: .destructive, action: { NSApp.terminate(nil) }) {
                    Label("Quit NetPulse", systemImage: "power")
                }
            }
        }
        .formStyle(.grouped)
        .onAppear {
            readLaunchAtLoginState()
        }
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
                // Revert toggle on failure
                launchAtLogin = !enabled
            }
        }
    }
}
