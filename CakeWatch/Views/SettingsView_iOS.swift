import SwiftUI

#if os(iOS)
extension SettingsView {
    var body: some View {
        NavigationStack {
            Form {
                Section("Accounts") {
                    if accounts.isEmpty {
                        Text("No accounts configured.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(accounts) { account in
                        Button {
                            startEdit(account)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(account.name)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text(maskedKey(account.apiKey))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                deleteAccount(account)
                            } label: {
                                Label("Delete", systemImage: "trash")
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
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear { loadAccounts() }
            .sheet(isPresented: $isAddingAccount, onDismiss: {
                editingAccount = nil
            }) {
                accountEditSheet
                    .onAppear {
                        if let account = editingAccount {
                            editName = account.name
                            editApiKey = account.apiKey
                        }
                    }
            }
        }
    }

    @ViewBuilder
    private var accountEditSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Account Name", text: $editName)
                    TextField("API Key", text: $editApiKey)
                }

                Section {
                    Button("Test Connection") {
                        testConnection(apiKey: editApiKey)
                    }
                    .disabled(editApiKey.isEmpty || isTesting)

                    if isTesting {
                        HStack {
                            ProgressView()
                            Text("Testing…")
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let testResult {
                        Text(testResult)
                            .foregroundStyle(testResult.hasPrefix("Error") ? .red : .green)
                            .font(.callout)
                    }
                }
            }
            .navigationTitle(editingAccount == nil ? "Add Account" : "Edit Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isAddingAccount = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveEdit() }
                        .disabled(!isEditValid)
                }
            }
        }
    }
}
#endif
