import SwiftUI

struct ContentView: View {
    var body: some View {
        #if os(macOS)
        MacContentView()
        #else
        IOSContentView()
        #endif
    }
}

func uptimeColor(_ uptime: Double) -> Color {
    if uptime >= 100 { return .green }
    if uptime >= 99 { return .yellow }
    if uptime >= 90 { return .orange }
    return .red
}
