import SwiftUI

struct GeneralSettingsView: View {
    @Bindable var model: SettingsModel

    var body: some View {
        Form {
            Section {
                Picker("Force Keyboard Layout:", selection: $model.forcedKeyboardLayoutID) {
                    Text("Off").tag("")
                    Divider()
                    ForEach(model.keyboardLayouts) { layout in
                        Text(layout.name).tag(layout.id)
                    }
                }
            } footer: {
                Text("Switches to this layout while a mode is active, then puts the previous one back. Useful when your usual layout does not type the hint characters.")
                    .foregroundStyle(.secondary)
            }

            Section {
                Toggle("Launch Vimac at login", isOn: $model.launchAtLogin)

                if model.loginItemStatus == .requiresApproval {
                    LabeledContent {
                        Button("Open Login Items…") { model.openLoginItemsSettings() }
                    } label: {
                        Label("Vimac is turned off in System Settings.", systemImage: "exclamationmark.triangle.fill")
                            .font(.callout)
                            .foregroundStyle(.orange)
                    }
                }

                ValidationMessage(model.loginItemFailure)
            }
        }
        .formStyle(.grouped)
    }
}
