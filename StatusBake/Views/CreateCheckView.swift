import SwiftUI

struct CreateCheckView: View {
    var onCreate: (([String: String]) async -> Void)?
    @Environment(\.dismiss) private var dismiss

    // Required
    @State private var name = ""
    @State private var testType = "HTTP"
    @State private var websiteUrl = ""
    @State private var checkRate = 300

    // Monitoring
    @State private var timeout = 15
    @State private var triggerRate = 0
    @State private var confirmation = 2
    @State private var paused = false
    @State private var followRedirects = false
    @State private var enableSslAlert = false

    // Content matching
    @State private var findString = ""
    @State private var doNotFind = false
    @State private var includeHeader = false

    // Advanced
    @State private var tags = ""
    @State private var statusCodesCsv = ""
    @State private var userAgent = ""
    @State private var host = ""
    @State private var port = ""
    @State private var basicUsername = ""
    @State private var basicPassword = ""
    @State private var customHeader = ""
    @State private var useJar = false

    // DNS
    @State private var dnsServer = ""
    @State private var dnsIps = ""

    @State private var isCreating = false

    private var isValid: Bool {
        !name.isEmpty && !websiteUrl.isEmpty
    }

    private var showContentMatching: Bool {
        testType == "HTTP" || testType == "HEAD"
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                requiredSection
                monitoringSection
                if showContentMatching { contentMatchingSection }
                advancedSection
                if testType == "DNS" { dnsSection }
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
    }

    @ViewBuilder
    private var requiredSection: some View {
        Section("Required") {
            TextField("Name", text: $name)
            Picker("Test Type", selection: $testType) {
                ForEach(testTypeOptions, id: \.self) { Text($0).tag($0) }
            }
            TextField("Website URL", text: $websiteUrl)
            Picker("Check Rate", selection: $checkRate) {
                ForEach(checkRateOptions, id: \.value) { option in
                    Text(option.label).tag(option.value)
                }
            }
        }
    }

    @ViewBuilder
    private var monitoringSection: some View {
        Section("Monitoring") {
            Toggle("Paused", isOn: $paused)
            Picker("Timeout", selection: $timeout) {
                ForEach(timeoutOptions, id: \.self) { Text("\($0)s").tag($0) }
            }
            Picker("Trigger Rate", selection: $triggerRate) {
                ForEach(triggerRateOptions, id: \.self) { min in
                    Text(min == 0 ? "Immediately" : "\(min) min").tag(min)
                }
            }
            Picker("Confirmation", selection: $confirmation) {
                ForEach(confirmationRange, id: \.self) { count in
                    Text("\(count) server\(count == 1 ? "" : "s")").tag(count)
                }
            }
            Toggle("Follow Redirects", isOn: $followRedirects)
            Toggle("Enable SSL Alert", isOn: $enableSslAlert)
        }
    }

    @ViewBuilder
    private var contentMatchingSection: some View {
        Section("Content Matching") {
            TextField("Find String", text: $findString)
            Toggle("Do Not Find", isOn: $doNotFind)
            Toggle("Include Header", isOn: $includeHeader)
        }
    }

    @ViewBuilder
    private var advancedSection: some View {
        Section("Advanced") {
            TextField("Tags (comma-separated)", text: $tags)
            TextField("Status Codes (comma-separated)", text: $statusCodesCsv)
            TextField("User Agent", text: $userAgent)
            TextField("Host", text: $host)
            if testType == "TCP" {
                TextField("Port", text: $port)
            }
            TextField("Basic Auth Username", text: $basicUsername)
            SecureField("Basic Auth Password", text: $basicPassword)
            TextField("Custom Header (JSON)", text: $customHeader)
            Toggle("Use Cookie Jar", isOn: $useJar)
        }
    }

    @ViewBuilder
    private var dnsSection: some View {
        Section("DNS") {
            TextField("DNS Server", text: $dnsServer)
            TextField("DNS IPs (comma-separated)", text: $dnsIps)
        }
    }

    private func create() {
        isCreating = true
        var fields: [String: String] = [
            "name": name,
            "test_type": testType,
            "website_url": websiteUrl,
            "check_rate": "\(checkRate)",
            "timeout": "\(timeout)",
            "trigger_rate": "\(triggerRate)",
            "confirmation": "\(confirmation)",
        ]
        if paused { fields["paused"] = "true" }
        if followRedirects { fields["follow_redirects"] = "true" }
        if enableSslAlert { fields["enable_ssl_alert"] = "true" }
        if !findString.isEmpty { fields["find_string"] = findString }
        if doNotFind { fields["do_not_find"] = "true" }
        if includeHeader { fields["include_header"] = "true" }
        if !tags.isEmpty { fields["tags"] = tags }
        if !statusCodesCsv.isEmpty { fields["status_codes_csv"] = statusCodesCsv }
        if !userAgent.isEmpty { fields["user_agent"] = userAgent }
        if !host.isEmpty { fields["host"] = host }
        if !port.isEmpty { fields["port"] = port }
        if !basicUsername.isEmpty { fields["basic_username"] = basicUsername }
        if !basicPassword.isEmpty { fields["basic_password"] = basicPassword }
        if !customHeader.isEmpty { fields["custom_header"] = customHeader }
        if useJar { fields["use_jar"] = "true" }
        if !dnsServer.isEmpty { fields["dns_server"] = dnsServer }
        if !dnsIps.isEmpty { fields["dns_ips"] = dnsIps }

        Task {
            await onCreate?(fields)
            dismiss()
        }
    }
}
