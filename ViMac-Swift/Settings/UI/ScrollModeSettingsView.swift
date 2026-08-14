import SwiftUI

struct ScrollModeSettingsView: View {
    @Bindable var model: SettingsModel

    var body: some View {
        Form {
            Section {
                DefaultableTextField(
                    title: "Scroll Keys:",
                    placeholder: ScrollKeys.defaultValue,
                    text: $model.scrollKeys,
                    width: 220
                )
                ValidationMessage(model.scrollKeysProblem?.message)
            } footer: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("4, 6, or 8 comma-separated sequences. Holding Shift scrolls by half a page.")
                    roleLegend
                }
                .foregroundStyle(.secondary)
            }

            Section {
                LabeledContent("Sensitivity:") {
                    HStack(spacing: 10) {
                        // Continuous: a `step` would have SwiftUI draw a tick
                        // mark per increment, and 100 of them read as a smear.
                        // The model rounds to a whole number on the way out.
                        Slider(value: $model.scrollSensitivity, in: 0...100)
                            .frame(width: 200)
                        Text(model.scrollSensitivity.formatted(.number.precision(.fractionLength(0))))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .frame(width: 30, alignment: .trailing)
                    }
                }
            }

            Section("Reverse Scrolling") {
                Toggle("Horizontal", isOn: $model.reverseHorizontalScroll)
                Toggle("Vertical", isOn: $model.reverseVerticalScroll)
            }
        }
        .formStyle(.grouped)
    }

    private var roleLegend: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) { legendItems }
            VStack(alignment: .leading, spacing: 2) { legendItems }
        }
        .font(.callout)
    }

    private var legendItems: some View {
        ForEach(model.scrollKeyRoles) { assignment in
            HStack(spacing: 3) {
                Text(assignment.sequence)
                    .monospaced()
                    .foregroundStyle(.primary)
                Text(assignment.role)
            }
        }
    }
}
