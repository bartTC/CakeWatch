import SwiftUI

#if os(macOS)
extension CheckDetailView {
    @ViewBuilder
    var nameField: some View {
        LabeledContent("Name") {
            if isEditingName {
                TextField("", text: $editingName)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        if editingName != detail.name {
                            onUpdate?("name", editingName)
                        }
                        isEditingName = false
                    }
                    .onEscapeKey { isEditingName = false }
            } else {
                HStack(spacing: 4) {
                    Text(detail.name)
                    Image(systemName: "pencil")
                        .foregroundStyle(.tertiary)
                        .font(.caption)
                }
                .onTapGesture(count: 2) {
                    editingName = detail.name
                    isEditingName = true
                }
            }
        }
    }

    @ViewBuilder
    func editableField(label: String, value: String, field: String) -> some View {
        LabeledContent(label) {
            InlineEditableText(value: value, field: field, onUpdate: onUpdate)
        }
    }

    @ViewBuilder
    var statusCodesField: some View {
        let codes = detail.statusCodes ?? []
        if isEditingStatusCodes {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(editingStatusCodes, id: \.self) { code in
                    HStack {
                        Text(code)
                            .font(.system(.body, design: .monospaced))
                        Spacer()
                        Button {
                            editingStatusCodes.removeAll { $0 == code }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                HStack {
                    TextField("Add code", text: $newStatusCode)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                        .onSubmit {
                            let trimmed = newStatusCode.trimmingCharacters(in: .whitespaces)
                            if !trimmed.isEmpty && !editingStatusCodes.contains(trimmed) {
                                editingStatusCodes.append(trimmed)
                                newStatusCode = ""
                            }
                        }
                }
                HStack {
                    Button("Cancel") {
                        isEditingStatusCodes = false
                        newStatusCode = ""
                    }
                    Spacer()
                    Button("Save") {
                        let csv = editingStatusCodes.joined(separator: ",")
                        if csv != codes.joined(separator: ",") {
                            onUpdate?("status_codes_csv", csv)
                        }
                        isEditingStatusCodes = false
                        newStatusCode = ""
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
        } else {
            LabeledContent {
                HStack(alignment: .top) {
                    if codes.isEmpty {
                        Text("—").foregroundStyle(.tertiary)
                    } else {
                        FlowLayout(spacing: 4) {
                            ForEach(codes, id: \.self) { code in
                                Text(code)
                                    .font(.system(.caption, design: .monospaced))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))
                            }
                        }
                    }
                    Spacer(minLength: 4)
                    Button {
                        editingStatusCodes = codes
                        isEditingStatusCodes = true
                    } label: {
                        Image(systemName: "pencil")
                            .foregroundStyle(.tertiary)
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                }
            } label: {
                Text("Status Codes")
            }
        }
    }

    @ViewBuilder
    var tagsField: some View {
        let tags = detail.tags
        if isEditingTags {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(editingTags, id: \.self) { tag in
                    HStack {
                        Text(tag)
                        Spacer()
                        Button {
                            editingTags.removeAll { $0 == tag }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                HStack {
                    TextField("Add tag", text: $newTag)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            let trimmed = newTag.trimmingCharacters(in: .whitespaces)
                            if !trimmed.isEmpty && !editingTags.contains(trimmed) {
                                editingTags.append(trimmed)
                                newTag = ""
                            }
                        }
                }
                HStack {
                    Button("Cancel") {
                        isEditingTags = false
                        newTag = ""
                    }
                    Spacer()
                    Button("Save") {
                        let csv = editingTags.joined(separator: ",")
                        if csv != tags.joined(separator: ",") {
                            onUpdate?("tags", csv)
                        }
                        isEditingTags = false
                        newTag = ""
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
        } else {
            LabeledContent {
                HStack(alignment: .top) {
                    if tags.isEmpty {
                        Text("—").foregroundStyle(.tertiary)
                    } else {
                        FlowLayout(spacing: 4) {
                            ForEach(tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.system(.caption, design: .monospaced))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))
                            }
                        }
                    }
                    Spacer(minLength: 4)
                    Button {
                        editingTags = tags
                        isEditingTags = true
                    } label: {
                        Image(systemName: "pencil")
                            .foregroundStyle(.tertiary)
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                }
            } label: {
                Text("Tags")
            }
        }
    }
}

private struct InlineEditableText: View {
    let value: String
    let field: String
    var onUpdate: ((_ field: String, _ value: String) -> Void)?
    @State private var isEditing = false
    @State private var editingValue = ""

    var body: some View {
        if isEditing {
            TextField("", text: $editingValue)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    if editingValue != value {
                        onUpdate?(field, editingValue)
                    }
                    isEditing = false
                }
                .onEscapeKey { isEditing = false }
        } else {
            HStack(spacing: 4) {
                Text(value.isEmpty ? "—" : value)
                    .foregroundStyle(value.isEmpty ? .tertiary : .primary)
                Image(systemName: "pencil")
                    .foregroundStyle(.tertiary)
                    .font(.caption)
            }
            .onTapGesture(count: 2) {
                editingValue = value
                isEditing = true
            }
        }
    }
}
#endif
