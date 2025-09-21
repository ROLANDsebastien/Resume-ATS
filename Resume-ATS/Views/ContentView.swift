//
//  ContentView.swift
//  Resume-ATS
//
//  Created by ROLAND Sébastien on 21/09/2025.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @State private var selectedSection: String? = "Profile"

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
            }
            .navigationTitle("Sections")
        } detail: {
            switch selectedSection {
            case "Profile":
                ProfileView()
            case "Applications":
                Text("Applications Tracking View")
            case "Templates":
                Text("CV Templates View")
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
