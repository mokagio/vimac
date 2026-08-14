import SwiftUI

struct ExperimentalSettingsView: View {
    @Bindable var model: SettingsModel

    var body: some View {
        Form {
            Section {
                Toggle("Electron support", isOn: $model.electronSupport)
            } footer: {
                Text("Lets Hint Mode reach into older Electron apps such as Visual Studio Code and Slack, by setting their `AXManualAccessibility` attribute. Can cost performance and CPU.")
                    .foregroundStyle(.secondary)
            }

            Section {
                Toggle("Emulate VoiceOver", isOn: $model.emulateVoiceOver)
            } footer: {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Lets Hint Mode reach into non-native apps such as Firefox.")
                    Label(
                        "A last resort. Emulating VoiceOver breaks window managers and can change how your apps behave — Rectangle is one that keeps working.",
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .foregroundStyle(.orange)
                }
                .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}
