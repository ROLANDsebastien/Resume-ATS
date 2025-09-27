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
                        subtitle: "Gérer votre profil",
                        systemImage: "person"
                    ) {
                        selectedSection = "Profile"
                    }

                    DashboardTile(
                        title: "Candidatures",
                        subtitle: "Suivre vos candidatures",
                        systemImage: "briefcase"
                    ) {
                        selectedSection = "Candidatures"
                    }

                    DashboardTile(
                        title: "Templates",
                        subtitle: "Choisir des modèles de CV",
                        systemImage: "doc"
                    ) {
                        selectedSection = "Templates"
                    }

                    DashboardTile(
                        title: "Statistiques",
                        subtitle: "Voir les statistiques",
                        systemImage: "chart.bar"
                    ) {
                        selectedSection = "Statistiques"
                    }

                    DashboardTile(
                        title: "Settings",
                        subtitle: "Préférences de l'app",
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
