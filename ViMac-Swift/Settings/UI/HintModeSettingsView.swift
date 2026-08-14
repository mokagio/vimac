import SwiftUI

struct HintModeSettingsView: View {
    @Bindable var model: SettingsModel

    var body: some View {
        Form {
            Section {
                DefaultableTextField(
                    title: "Characters:",
                    placeholder: HintCharacters.defaultValue,
                    text: $model.hintCharacters
                )
                ValidationMessage(model.hintCharactersProblem?.message)
            } footer: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("The characters hints are drawn from. At least \(HintCharacters.minimumCount), each used once.")
                    Text("An empty field uses the default, which is the greyed-out text.")
                }
                .foregroundStyle(.secondary)
            }

            Section {
                DefaultableTextField(
                    title: "Text Size:",
                    placeholder: HintTextSize.defaultValue,
                    text: $model.hintTextSize,
                    width: 90,
                    unit: "points"
                )
                ValidationMessage(model.hintTextSizeProblem?.message)
            }
        }
        .formStyle(.grouped)
    }
}
