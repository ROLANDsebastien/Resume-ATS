//
//  DashboardView.swift
//  Resume-ATS
//
//  Created by ROLAND Sébastien on 26/09/2025.
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

struct DashboardView: View {
    @Binding var selectedSection: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Dashboard")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 20) {
                    DashboardTile(
                        title: "Profile",
                        subtitle: "Manage your profile",
                        systemImage: "person"
                    ) {
                        selectedSection = "Profile"
                    }

                    DashboardTile(
                        title: "Applications",
                        subtitle: "Track your applications",
                        systemImage: "briefcase"
                    ) {
                        selectedSection = "Applications"
                    }

                    DashboardTile(
                        title: "Templates",
                        subtitle: "Choose CV templates",
                        systemImage: "doc"
                    ) {
                        selectedSection = "Templates"
                    }

                    DashboardTile(
                        title: "Settings",
                        subtitle: "App preferences",
                        systemImage: "gear"
                    ) {
                        selectedSection = "Settings"
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

#Preview {
    DashboardView(selectedSection: .constant("Dashboard"))
}