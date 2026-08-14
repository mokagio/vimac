import SwiftUI

/// Says what is wrong with a field without taking the value away.
struct ValidationMessage: View {
    let text: String?

    init(_ text: String?) {
        self.text = text
    }

    var body: some View {
        if let text {
            Label(text, systemImage: "exclamationmark.triangle.fill")
                .font(.callout)
                .foregroundStyle(.orange)
                .transition(.opacity)
        }
    }
}
