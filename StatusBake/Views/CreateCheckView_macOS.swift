import SwiftUI

#if os(macOS)
extension CreateCheckView {
    var body: some View {
        VStack(spacing: 0) {
            Form {
                formContent
            }
            .formStyle(.grouped)

            Divider()
            HStack {
                Button("Cancel", role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Create") { create() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!isValid || isCreating)
            }
            .padding()
        }
        .frame(width: 500, height: 600)
        .onAppear { initializeAccountSelection() }
    }
}
#endif
