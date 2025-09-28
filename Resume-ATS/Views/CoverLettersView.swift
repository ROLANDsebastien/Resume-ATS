//
//  CoverLettersView.swift
//  Resume-ATS
//
//  Created by ROLAND Sébastien on 27/09/2025.
//

import SwiftData
import SwiftUI

struct CoverLettersView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var coverLetters: [CoverLetter]
    @Query private var profiles: [Profile]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Gestion des Lettres de Motivation")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 20) {
                        NavigationLink(destination: AddCoverLetterView()) {
                            VStack(spacing: 10) {
                                Image(systemName: "plus")
                                    .font(.largeTitle)
                                    .foregroundColor(.blue)
                                Text("Nouvelle Lettre")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("Créer une nouvelle lettre de motivation")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity, minHeight: 120)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)

                    if !coverLetters.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Lettres de Motivation")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .padding(.horizontal)

                            List {
                                ForEach(coverLetters) { coverLetter in
                                    NavigationLink(
                                        destination: EditCoverLetterView(coverLetter: coverLetter)
                                    ) {
                                        CoverLetterRow(
                                            coverLetter: coverLetter,
                                            onDelete: {
                                                modelContext.delete(coverLetter)
                                            }
                                        )
                                    }
                                    .listRowSeparator(.hidden)
                                }
                            }
                            .listStyle(.plain)
                            .frame(height: min(CGFloat(coverLetters.count) * 80, 400))  // Adjust height as needed
                        }
                    } else {
                        Text("Aucune lettre de motivation trouvée.")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle("Lettres de Motivation")
        }
    }
}

struct CoverLetterRow: View {
    var coverLetter: CoverLetter
    var onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(coverLetter.title)
                    .font(.headline)
                if let profile = coverLetter.profile {
                    Text("Profil: \(profile.name)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Text(
                    "Créée le: \(coverLetter.creationDate.formatted(date: .abbreviated, time: .omitted))"
                )
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .swipeActions {
            Button(role: .destructive, action: onDelete) {
                Label("Supprimer", systemImage: "trash")
            }
        }
    }
}

struct AddCoverLetterView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [Profile]

    @State private var title = ""
    @State private var contentAttributedString = NSAttributedString()
    @State private var selectedProfile: Profile?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Nouvelle Lettre de Motivation")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)

                Form {
                    TextField("Titre", text: $title)
                    Picker("Profil associé", selection: $selectedProfile) {
                        Text("Aucun").tag(nil as Profile?)
                        ForEach(profiles) { profile in
                            Text(profile.name).tag(profile as Profile?)
                        }
                    }
                    RichTextEditorWithToolbar(attributedString: $contentAttributedString)
                        .frame(minHeight: 400)
                }
                .frame(minWidth: 600, minHeight: 500)

                HStack {
                    Spacer()
                    Button("Ajouter") {
                        let newCoverLetter = CoverLetter(
                            title: title,
                            content: contentAttributedString.rtf(
                                from: NSRange(location: 0, length: contentAttributedString.length))
                                ?? Data(),
                            profile: selectedProfile
                        )
                        modelContext.insert(newCoverLetter)
                        // Navigate back
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(title.isEmpty)
                }
                .padding(.horizontal)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle("Nouvelle Lettre")
    }
}

struct EditCoverLetterView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [Profile]
    var coverLetter: CoverLetter

    @State private var title: String
    @State private var contentAttributedString: NSAttributedString
    @State private var selectedProfile: Profile?

    init(coverLetter: CoverLetter) {
        self.coverLetter = coverLetter
        _title = State(initialValue: coverLetter.title)
        _contentAttributedString = State(initialValue: coverLetter.contentAttributedString)
        _selectedProfile = State(initialValue: coverLetter.profile)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Modifier Lettre de Motivation")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)

                Form {
                    TextField("Titre", text: $title)
                    Picker("Profil associé", selection: $selectedProfile) {
                        Text("Aucun").tag(nil as Profile?)
                        ForEach(profiles) { profile in
                            Text(profile.name).tag(profile as Profile?)
                        }
                    }
                    RichTextEditorWithToolbar(attributedString: $contentAttributedString)
                        .frame(minHeight: 400)
                }
                .frame(minWidth: 600, minHeight: 500)

                HStack {
                    Spacer()
                    Button("Sauvegarder") {
                        coverLetter.title = title
                        coverLetter.contentAttributedString = contentAttributedString
                        coverLetter.profile = selectedProfile
                        // Navigate back
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(title.isEmpty)
                }
                .padding(.horizontal)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle("Modifier Lettre")
    }
}

#Preview {
    NavigationStack {
        CoverLettersView()
    }
    .modelContainer(for: [Profile.self, Application.self, CoverLetter.self], inMemory: true)
}
