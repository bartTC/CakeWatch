import SwiftUI

#if os(macOS)
extension SettingsView {
    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("Accounts") {
                    if accounts.isEmpty {
                        Text("No accounts configured.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(accounts) { account in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(account.name).font(.headline)
                                Text(maskedKey(account.apiKey))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Edit") { startEdit(account) }
                            Button(role: .destructive) {
                                deleteAccount(account)
                            } label: {
                                Image(systemName: "trash")
                            }
                        }
                    }
                    Button("Add Account") { startAdd() }
                }

                preferencesSection

                Section {
                    Link("Get your API key at StatusCake",
                         destination: URL(string: "https://app.statuscake.com/User.php")!)
                        .font(.callout)
                }
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 500, height: 420)
        .onAppear { loadAccounts() }
        .sheet(isPresented: $isAddingAccount) {
            accountEditSheet
        }
    }

    @ViewBuilder
    private var accountEditSheet: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    TextField("Account Name", text: $editName)
                        .textFieldStyle(.roundedBorder)
                    TextField("API Key", text: $editApiKey)
                        .textFieldStyle(.roundedBorder)

                    HStack {
                        Button("Test Connection") {
                            testConnection(apiKey: editApiKey)
                        }
                        .disabled(editApiKey.isEmpty || isTesting)

                        if isTesting {
                            ProgressView()
                                .controlSize(.small)
                        }

                        if let testResult {
                            Text(testResult)
                                .foregroundStyle(testResult.hasPrefix("Error") ? .red : .green)
                                .font(.callout)
                        }
                    }
                }
            }
            .formStyle(.grouped)

            Divider()
            HStack {
                Button("Cancel", role: .cancel) {
                    isAddingAccount = false
                }
                .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Save") { saveEdit() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!isEditValid)
            }
            .padding()
        }
        .frame(width: 400, height: 250)
    }
}
#endif
