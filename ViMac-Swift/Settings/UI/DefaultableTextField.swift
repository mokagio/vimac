import SwiftUI

/// A settings field whose default shows through as the placeholder, with a
/// button back to it.
///
/// Emptying the field is what restores the default, so the button only has to
/// do that — and being disabled on an empty field is what says the value on
/// show is the default rather than something someone typed.
struct DefaultableTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var width: CGFloat = 200
    var unit: String?

    var body: some View {
        LabeledContent(title) {
            HStack(spacing: 8) {
                // `prompt` rather than the title argument: inside a
                // `LabeledContent` the title renders as a second label beside
                // the field instead of as placeholder text within it.
                TextField("", text: $text, prompt: Text(placeholder))
                    .labelsHidden()
                    .textFieldStyle(.roundedBorder)
                    .multilineTextAlignment(.leading)
                    .frame(width: width)

                if let unit {
                    Text(unit)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                Button("Restore Default") { text = "" }
                    .disabled(text.isEmpty)
            }
        }
    }
}
