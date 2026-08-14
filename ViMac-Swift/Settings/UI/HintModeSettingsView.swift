import SwiftUI

struct HintModeSettingsView: View {
    @Bindable var model: SettingsModel

    var body: some View {
        Form {
            Section {
                LabeledContent("Characters:") {
                    TextField(HintCharacters.defaultValue, text: $model.hintCharacters)
                        .frame(width: 200)
                }
                ValidationMessage(model.hintCharactersProblem?.message)
            } footer: {
                Text("The characters hints are drawn from. At least \(HintCharacters.minimumCount), each used once.")
                    .foregroundStyle(.secondary)
            }

            Section {
                LabeledContent("Text Size:") {
                    HStack(spacing: 6) {
                        TextField(HintTextSize.defaultValue, text: $model.hintTextSize)
                            .frame(width: 80)
                        Text("points")
                            .foregroundStyle(.secondary)
                    }
                }
                ValidationMessage(model.hintTextSizeProblem?.message)
            }
        }
        .formStyle(.grouped)
    }
}
