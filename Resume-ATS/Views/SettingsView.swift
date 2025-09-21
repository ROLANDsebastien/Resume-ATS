//
//  SettingsView.swift
//  Resume-ATS
//
//  Created by ROLAND Sébastien on 21/09/2025.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var expandedSection: String? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                SectionTile(title: "Appearance", isExpanded: expandedSection == "appearance") {
                    expandedSection = expandedSection == "appearance" ? nil : "appearance"
                } expandedContent: {
                    Toggle(isOn: $isDarkMode) {
                        HStack {
                            Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                                .foregroundColor(isDarkMode ? .yellow : .orange)
                            Text("Dark Mode")
                        }
                    }
                    .padding()
                }
            }
            .padding()
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    SettingsView()
}
