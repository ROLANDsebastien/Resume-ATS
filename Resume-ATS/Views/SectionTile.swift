//
//  SectionTile.swift
//  Resume-ATS
//
//  Created by ROLAND Sébastien on 21/09/2025.
//

import SwiftUI

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
