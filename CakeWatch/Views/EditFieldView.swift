import SwiftUI

#if os(iOS)
struct EditFieldView: View {
    let label: String
    let field: String
    let initialValue: String
    var onSave: ((_ field: String, _ value: String) -> Void)?
    @FocusState private var isFocused: Bool
    @State private var text: String = ""

    var body: some View {
        Form {
            TextField(label, text: $text)
                .focused($isFocused)
        }
        .navigationTitle(label)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            text = initialValue
            isFocused = true
        }
        .onDisappear {
            if text != initialValue {
                onSave?(field, text)
            }
        }
    }
}
#endif
