//
//  DashboardView.swift
//  Resume-ATS
//
//  Created by ROLAND Sébastien on 26/09/2025.
//

import SwiftUI

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
                        title: "Candidatures",
                        subtitle: "Track your applications",
                        systemImage: "briefcase"
                    ) {
                        selectedSection = "Candidatures"
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
