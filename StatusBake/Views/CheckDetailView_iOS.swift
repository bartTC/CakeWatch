import SwiftUI

#if os(iOS)
extension CheckDetailView {
    @ViewBuilder
    var nameField: some View {
        editableNavigationLink(label: "Name", value: detail.name, field: "name")
    }

    @ViewBuilder
    func editableField(label: String, value: String, field: String) -> some View {
        editableNavigationLink(label: label, value: value, field: field)
    }

    @ViewBuilder
    var statusCodesField: some View {
        chipsNavigationLink(label: "Status Codes", values: detail.statusCodes ?? [], field: "status_codes_csv")
    }

    @ViewBuilder
    var tagsField: some View {
        chipsNavigationLink(label: "Tags", values: detail.tags, field: "tags")
    }

    @ViewBuilder
    private func editableNavigationLink(label: String, value: String, field: String) -> some View {
        NavigationLink {
            EditFieldView(label: label, field: field, initialValue: value) { f, v in
                if v != value {
                    onUpdate?(f, v)
                }
            }
        } label: {
            LabeledContent(label) {
                Text(value.isEmpty ? "—" : value)
                    .foregroundStyle(value.isEmpty ? .tertiary : .primary)
            }
        }
    }

    @ViewBuilder
    private func chipsNavigationLink(label: String, values: [String], field: String) -> some View {
        NavigationLink {
            EditChipsView(label: label, field: field, initialValues: values) { f, v in
                onUpdate?(f, v)
            }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text(label)
                    .foregroundStyle(.primary)
                if values.isEmpty {
                    Text("—").foregroundStyle(.tertiary)
                } else {
                    FlowLayout(spacing: 4) {
                        ForEach(values, id: \.self) { value in
                            Text(value)
                                .font(.system(.caption, design: .monospaced))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))
                        }
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }
}
#endif
