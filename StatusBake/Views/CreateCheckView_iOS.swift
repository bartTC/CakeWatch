import SwiftUI

#if os(iOS)
extension CreateCheckView {
    var body: some View {
        NavigationStack {
            Form {
                formContent
            }
            .navigationTitle("New Check")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { create() }
                        .disabled(!isValid || isCreating)
                }
            }
        }
    }
}
#endif
