import SwiftUI
import WaniKaniCore

/// A TextField wrapper that auto-converts romaji input to kana inline as the user types.
struct RomajiTextField: View {
    @Binding var text: String
    let placeholder: String
    let targetScript: RomajiKanaConverter.KanaScript
    var isFocused: FocusState<Bool>.Binding

    var body: some View {
        TextField(placeholder, text: $text)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .keyboardType(.asciiCapable)
            .focused(isFocused)
            .onTapGesture { isFocused.wrappedValue = true }
            .onChange(of: text) { _, newValue in
                let converted = RomajiKanaConverter.convert(newValue, targetScript: targetScript)
                if converted != newValue {
                    text = converted
                }
            }
    }
}
