//
//  DashboardView.swift
//  Resume-ATS
//
//  Created by ROLAND Sébastien on 26/09/2025.
//

import SwiftUI

struct DashboardView: View {
    @Binding var selectedSection: String?
    var language: String

    var body: some View {
        List {
            VStack(spacing: 30) {
                Text(language == "fr" ? "Dashboard" : "Dashboard")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 40), GridItem(.flexible(), spacing: 40), GridItem(.flexible())], spacing: 60) {
                     DashboardTile(
                         title: language == "fr" ? "Profil" : "Profile",
                         subtitle: language == "fr" ? "Gérer votre profil" : "Manage your profile",
                         systemImage: "person"
                     ) {
                         selectedSection = "Profile"
                     }

                     DashboardTile(
                         title: language == "fr" ? "Candidatures" : "Applications",
                         subtitle: language == "fr" ? "Suivre vos candidatures" : "Track your applications",
                         systemImage: "briefcase"
                     ) {
                         selectedSection = "Candidatures"
                     }

                     DashboardTile(
                         title: language == "fr" ? "Templates" : "Templates",
                         subtitle: language == "fr" ? "Choisir des modèles de CV" : "Choose CV templates",
                         systemImage: "doc"
                     ) {
                         selectedSection = "Templates"
                     }

                     DashboardTile(
                         title: language == "fr" ? "Statistiques" : "Statistics",
                         subtitle: language == "fr" ? "Voir les statistiques" : "View statistics",
                         systemImage: "chart.bar"
                     ) {
                         selectedSection = "Statistiques"
                     }

                      DashboardTile(
                          title: language == "fr" ? "Lettres" : "Letters",
                          subtitle: language == "fr" ? "Gérer vos lettres de motivation" : "Manage your cover letters",
                          systemImage: "doc.text"
                      ) {
                          selectedSection = "Lettres"
                      }

                      DashboardTile(
                          title: language == "fr" ? "CVs" : "CVs",
                          subtitle: language == "fr" ? "Gérer vos CVs PDF" : "Manage your CV PDFs",
                          systemImage: "doc.fill"
                      ) {
                          selectedSection = "CVs"
                      }

                       DashboardTile(
                           title: language == "fr" ? "Réglages" : "Settings",
                           subtitle: language == "fr" ? "Préférences de l'app" : "App preferences",
                           systemImage: "gear"
                       ) {
                          selectedSection = "Settings"
                       }
                }
                .padding(.horizontal, 20)
            }
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
    }
}

#Preview {
    DashboardView(selectedSection: .constant("Dashboard"), language: "fr")
}