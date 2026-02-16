import SwiftUI

struct DeleteConfirmationSheet: View {
    @Bindable var viewModel: UptimeViewModel

    var body: some View {
        let names = viewModel.checks.filter { viewModel.selectedChecks.contains($0.id) }.map(\.name)
        VStack(alignment: .leading, spacing: 12) {
            Text(names.count == 1 ? "Delete Check" : "Delete \(names.count) Checks")
                .font(.headline)
            Text("The following will be permanently deleted:")
                .foregroundStyle(.secondary)
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(names, id: \.self) { name in
                        Text(name)
                        if name != names.last {
                            Divider()
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 300)
            HStack {
                Spacer()
                Button("Cancel", role: .cancel) {
                    viewModel.showDeleteConfirmation = false
                }
                .keyboardShortcut(.cancelAction)
                Button("Delete", role: .destructive) {
                    viewModel.showDeleteConfirmation = false
                    Task { await viewModel.deleteSelected() }
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 350)
    }
}
