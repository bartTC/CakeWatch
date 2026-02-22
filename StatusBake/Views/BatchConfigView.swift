import SwiftUI

struct BatchConfigView: View {
    let details: [UptimeCheckDetail]
    var onBatchUpdate: ((_ field: String, _ value: String) -> Void)?
    var onDelete: (() -> Void)?

    private let multipleTag = -999
    private let multipleStringTag = "__multiple__"

    private var spansMultipleAccounts: Bool {
        Set(details.map(\.accountId)).count > 1
    }

    var body: some View {
        Form {
            Section {
                Text("\(details.count) checks selected")
                    .foregroundStyle(.secondary)

                Picker("Enabled", selection: pausedBinding) {
                    if !allSameBool(\.paused) {
                        Text("Multiple Values").tag(multipleStringTag)
                    }
                    Text("Yes").tag("false")
                    Text("No").tag("true")
                }
                .disabled(spansMultipleAccounts)
            }

            Section {
                Picker("Check Rate", selection: binding(for: \.checkRate, field: "check_rate")) {
                    if !allSame(\.checkRate) {
                        Text("Multiple Values").tag(multipleTag)
                    }
                    ForEach(checkRateOptions, id: \.value) { option in
                        Text(option.label).tag(option.value)
                    }
                }

                Picker("Timeout", selection: binding(for: { $0.timeout ?? 15 }, field: "timeout")) {
                    if !allSame({ $0.timeout ?? 15 }) {
                        Text("Multiple Values").tag(multipleTag)
                    }
                    ForEach(timeoutOptions, id: \.self) { sec in
                        Text("\(sec)s").tag(sec)
                    }
                }

                Picker("Trigger Rate", selection: binding(for: { $0.triggerRate ?? 0 }, field: "trigger_rate")) {
                    if !allSame({ $0.triggerRate ?? 0 }) {
                        Text("Multiple Values").tag(multipleTag)
                    }
                    ForEach(triggerRateOptions, id: \.self) { min in
                        Text(min == 0 ? "Immediately" : "\(min) min").tag(min)
                    }
                }

                Picker("Confirmation", selection: binding(for: { $0.confirmation ?? 2 }, field: "confirmation")) {
                    if !allSame({ $0.confirmation ?? 2 }) {
                        Text("Multiple Values").tag(multipleTag)
                    }
                    ForEach(confirmationRange, id: \.self) { count in
                        Text("\(count) server\(count == 1 ? "" : "s")").tag(count)
                    }
                }
            } header: {
                Text("Configuration").font(.headline)
            }
            .disabled(spansMultipleAccounts)

            if spansMultipleAccounts {
                Section {
                    Label("Selected checks belong to different accounts. Batch editing is disabled.", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
            }

            Section {
                Button("Delete \(details.count) Checks", role: .destructive) {
                    onDelete?()
                }
                .disabled(spansMultipleAccounts)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Batch Edit")
    }

    private var pausedBinding: Binding<String> {
        let allMatch = allSameBool(\.paused)
        return Binding(
            get: { allMatch ? String(details.first!.paused) : multipleStringTag },
            set: { newValue in
                if newValue != multipleStringTag {
                    onBatchUpdate?("paused", newValue)
                }
            }
        )
    }

    private func allSameBool(_ keyPath: KeyPath<UptimeCheckDetail, Bool>) -> Bool {
        guard let first = details.first else { return true }
        return details.allSatisfy { $0[keyPath: keyPath] == first[keyPath: keyPath] }
    }

    private func allSame(_ keyPath: KeyPath<UptimeCheckDetail, Int>) -> Bool {
        guard let first = details.first else { return true }
        return details.allSatisfy { $0[keyPath: keyPath] == first[keyPath: keyPath] }
    }

    private func allSame(_ extract: (UptimeCheckDetail) -> Int) -> Bool {
        guard let first = details.first else { return true }
        let firstVal = extract(first)
        return details.allSatisfy { extract($0) == firstVal }
    }

    private func binding(for keyPath: KeyPath<UptimeCheckDetail, Int>, field: String) -> Binding<Int> {
        let allMatch = allSame(keyPath)
        return Binding(
            get: { allMatch ? (details.first?[keyPath: keyPath] ?? multipleTag) : multipleTag },
            set: { newValue in
                if newValue != multipleTag {
                    onBatchUpdate?(field, "\(newValue)")
                }
            }
        )
    }

    private func binding(for extract: @escaping (UptimeCheckDetail) -> Int, field: String) -> Binding<Int> {
        let allMatch = allSame(extract)
        return Binding(
            get: { allMatch ? extract(details.first!) : multipleTag },
            set: { newValue in
                if newValue != multipleTag {
                    onBatchUpdate?(field, "\(newValue)")
                }
            }
        )
    }
}
