//
//  SectionTile.swift
//  Resume-ATS
//
//  Created by ROLAND Sébastien on 21/09/2025.
//

import SwiftUI

struct DashboardTile: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: systemImage)
                    .font(.largeTitle)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 120)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .shadow(radius: isHovered ? 8 : 4)
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovered = hovering
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
