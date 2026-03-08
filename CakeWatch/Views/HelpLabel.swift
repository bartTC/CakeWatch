import SwiftUI

struct HelpLabel: View {
    let title: String
    let helpText: String
    @State private var showPopover = false

    var body: some View {
        HStack(spacing: 4) {
            Text(title)
            Button {
                showPopover.toggle()
            } label: {
                Image(systemName: "questionmark.circle")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showPopover, arrowEdge: .trailing) {
                Text(helpText)
                    .font(.callout)
                    .padding(10)
                    .frame(maxWidth: 250)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
