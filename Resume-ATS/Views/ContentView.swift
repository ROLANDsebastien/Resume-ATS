//
//  ContentView.swift
//  Resume-ATS
//
//  Created by ROLAND Sébastien on 21/09/2025.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @State private var selectedSection: String? = "Dashboard"

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedSection) {
                NavigationLink(value: "Profile") {
                    Label("Profile", systemImage: "person")
                }
                NavigationLink(value: "Applications") {
                    Label("Applications", systemImage: "briefcase")
                }
                NavigationLink(value: "Templates") {
                    Label("Templates", systemImage: "doc")
                }
                NavigationLink(value: "Settings") {
                    Label("Settings", systemImage: "gear")
                }
            }
            .navigationTitle("Sections")
        } detail: {
            switch selectedSection {
            case "Dashboard":
                Text("Dashboard View")
            case "Profile":
                ProfileView()
            case "Applications":
                Text("Applications Tracking View")
            case "Templates":
                Text("CV Templates View")
            case "Settings":
                SettingsView()
            default:
                Text("Select a section")
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Item.self, Profile.self], inMemory: true)
}
