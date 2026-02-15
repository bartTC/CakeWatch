import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("apiKey") private var apiKey = ""
    @AppStorage("maxRequestsPerSecond") private var maxRequestsPerSecond = 4
    @State private var testResult: String?
    @State private var isTesting = false

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("API Key") {
                    SecureField("API Key", text: $apiKey)
                        .textFieldStyle(.roundedBorder)

                    Link("Get your API key at StatusCake",
                         destination: URL(string: "https://app.statuscake.com/User.php")!)
                        .font(.callout)

                    HStack {
                        Button("Test Connection") {
                            isTesting = true
                            testResult = nil
                            Task {
                                do {
                                    let checks = try await StatusCakeAPI.shared.listChecks()
                                    testResult = "Connected — \(checks.count) checks found."
                                } catch {
                                    testResult = "Error: \(error.localizedDescription)"
                                }
                                isTesting = false
                            }
                        }
                        .disabled(apiKey.isEmpty || isTesting)

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

                Section("Preferences") {
                    Picker("Max Requests/Second", selection: $maxRequestsPerSecond) {
                        Text("1/s (Free — safest)").tag(1)
                        Text("2/s (Free — recommended)").tag(2)
                        Text("3/s").tag(3)
                        Text("4/s (Paid — recommended)").tag(4)
                        Text("5/s (Paid — maximum)").tag(5)
                    }
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
        .frame(width: 500, height: 320)
    }
}
