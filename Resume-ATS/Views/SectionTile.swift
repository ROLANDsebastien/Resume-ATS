import SwiftUI

struct DashboardTile: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let action: () -> Void
    var isEnabled: Bool = true
    var isSelected: Bool = false

    @Environment(\.colorScheme) var colorScheme
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: systemImage)
                    .font(.largeTitle)
                    .foregroundColor(isEnabled ? (isSelected ? .white : .blue) : .gray)
                Text(title)
                    .font(.headline)
                    .fontWeight(.regular)
                    .foregroundColor(isSelected ? .white : .primary)
                Text(subtitle)
                    .font(.subheadline)
                    .fontWeight(.regular)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 120)
            .background(isSelected ? Color.blue : (colorScheme == .dark ? Color.gray.opacity(0.1) : Color.gray.opacity(0.05)))
            .cornerRadius(12)
            .shadow(radius: colorScheme == .dark ? (isHovered && isEnabled ? 8 : 4) : 0)
            .scaleEffect(isHovered && isEnabled ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isEnabled)
        .onHover { hovering in
            if isEnabled {
                isHovered = hovering
            }
        }
    }
}

struct SectionTile<Content: View>: View {
    let title: String
    let isExpanded: Bool
    let action: () -> Void
    let expandedContent: () -> Content

    var body: some View {
        VStack {
            Button(action: action) {
                HStack {
                    Text(title)
                        .font(.headline)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                }
                .padding()
                .cornerRadius(10)
            }
            if isExpanded {
                expandedContent()
                    .padding(.horizontal)
                    .transition(.slide)
            }
        }
    }
}
