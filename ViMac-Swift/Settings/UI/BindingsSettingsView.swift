import SwiftUI

struct BindingsSettingsView: View {
    @Bindable var model: SettingsModel

    var body: some View {
        Form {
            Section {
                Toggle("Hold Space to activate Hint Mode", isOn: $model.holdSpaceForHintMode)
            }

            Section {
                ForEach(ShortcutStore.Shortcut.allCases) { shortcut in
                    LabeledContent("\(shortcut.title):") {
                        HStack(spacing: 8) {
                            stateBadge(for: model.shortcutSetting(for: shortcut))
                            ShortcutRecorder(shortcut: shortcut) { model.refreshShortcuts() }
                                .frame(width: 130, height: 22)
                            Button("Restore Default") { model.restoreDefaultShortcut(shortcut) }
                                .disabled(model.shortcutSetting(for: shortcut) == .unset)
                        }
                    }
                }
            } header: {
                Text("Shortcut Activation")
            } footer: {
                Text("Clearing a shortcut turns it off for good — it is not handed the default back on the next launch.")
                    .foregroundStyle(.secondary)
            }

            Section {
                keySequenceRow(
                    title: "Hint Mode",
                    placeholder: "fd",
                    enabled: $model.hintModeKeySequenceEnabled,
                    sequence: $model.hintModeKeySequence,
                    problem: model.hintModeKeySequenceProblem?.message
                )

                keySequenceRow(
                    title: "Scroll Mode",
                    placeholder: "jk",
                    enabled: $model.scrollModeKeySequenceEnabled,
                    sequence: $model.scrollModeKeySequence,
                    problem: model.scrollModeKeySequenceProblem?.message
                )

                DefaultableTextField(
                    title: "Reset Delay:",
                    placeholder: ResetDelay.defaultValue,
                    text: $model.keySequenceResetDelay,
                    width: 90,
                    unit: "seconds"
                )
                ValidationMessage(model.keySequenceResetDelayProblem?.message)
            } header: {
                Text("Key Sequence Activation")
            } footer: {
                Text("Activate Vimac by typing a sequence of keys in quick succession. The reset delay is how long a partly typed sequence is remembered.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    @ViewBuilder
    private func keySequenceRow(
        title: String,
        placeholder: String,
        enabled: Binding<Bool>,
        sequence: Binding<String>,
        problem: String?
    ) -> some View {
        Toggle(title, isOn: enabled)

        LabeledContent("Sequence:") {
            HStack(spacing: 8) {
                TextField("", text: sequence, prompt: Text(placeholder))
                    .labelsHidden()
                    .textFieldStyle(.roundedBorder)
                    .multilineTextAlignment(.leading)
                    .frame(width: 130)
                    .disabled(!enabled.wrappedValue)

                // Keeps the field on the same line as the ones that carry a
                // Restore Default button, instead of hard against the edge.
                Spacer(minLength: 8)
            }
        }

        ValidationMessage(problem)
    }

    @ViewBuilder
    private func stateBadge(for setting: ShortcutSetting) -> some View {
        switch setting {
        case .unset:
            badge("Default", tint: .secondary)
        case .disabled:
            badge("Off", tint: .orange)
        case .custom:
            badge("Custom", tint: .accentColor)
        }
    }

    private func badge(_ text: String, tint: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(tint.opacity(0.12), in: .capsule)
            .frame(width: 60)
    }
}
