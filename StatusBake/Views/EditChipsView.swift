import SwiftUI

#if os(iOS)
struct EditChipsView: View {
    let label: String
    let field: String
    let initialValues: [String]
    var onSave: ((_ field: String, _ value: String) -> Void)?
    @FocusState private var isFocused: Bool
    @State private var items: [String] = []
    @State private var newItem = ""

    var body: some View {
        Form {
            Section {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .font(.system(.body, design: .monospaced))
                }
                .onDelete { offsets in
                    items.remove(atOffsets: offsets)
                }
                HStack {
                    TextField("Add \(label.lowercased())", text: $newItem)
                        .focused($isFocused)
                        .onSubmit { addItem() }
                    Button {
                        addItem()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.green)
                    }
                    .disabled(newItem.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .navigationTitle(label)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
        }
        .onAppear {
            items = initialValues
            isFocused = true
        }
        .onDisappear {
            let csv = items.joined(separator: ",")
            if csv != initialValues.joined(separator: ",") {
                onSave?(field, csv)
            }
        }
    }

    private func addItem() {
        let trimmed = newItem.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty && !items.contains(trimmed) {
            items.append(trimmed)
            newItem = ""
        }
    }
}
#endif
