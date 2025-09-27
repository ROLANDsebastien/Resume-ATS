import SwiftData
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Main Profile View
struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [Profile]

    @State private var selectedProfile: Profile?
    @State private var newProfileName: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Profil")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .padding(.top)

                profileSelector

                if let profile = selectedProfile {
                    VStack(spacing: 20) {
                        StyledSection(title: "Informations Personnelles") {
                            PersonalInfoForm(profile: profile)
                        }

                        StyledSection(title: "Résumé") {
                            TextEditor(
                                text: Binding(
                                    get: { profile.summary }, set: { profile.summary = $0 })
                            )
                            .modifier(StyledTextEditorModifier())
                        }

                        StyledSection(title: "Expériences") {
                            ForEach(profile.experiences) { experience in
                                ExperienceForm(experience: experience)
                                .padding(.bottom, 10)
                                Button(action: { 
                                    if let index = profile.experiences.firstIndex(where: { $0.id == experience.id }) {
                                        profile.experiences.remove(at: index)
                                    }
                                }) {
                                    Image(systemName: "trash.fill")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                                if experience.id != profile.experiences.last?.id {
                                    Divider().background(Color.secondary)
                                }
                            }
                            StyledButton(
                                title: "Ajouter une expérience", systemImage: "plus",
                                action: {
                                    profile.experiences.append(
                                        Experience(
                                            company: "", startDate: Date(), details: ""))
                                })
                        }

                        StyledSection(title: "Formations") {
                            ForEach(profile.educations) { education in
                                EducationForm(education: education)
                                .padding(.bottom, 10)
                                Button(action: { 
                                    if let index = profile.educations.firstIndex(where: { $0.id == education.id }) {
                                        profile.educations.remove(at: index)
                                    }
                                }) {
                                    Image(systemName: "trash.fill")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                                if education.id != profile.educations.last?.id {
                                    Divider().background(Color.secondary)
                                }
                            }
                            StyledButton(
                                title: "Ajouter une formation", systemImage: "plus",
                                action: {
                                    profile.educations.append(
                                        Education(
                                            institution: "", degree: "", startDate: Date(),
                                            details: ""))
                                })
                        }

                        StyledSection(title: "Références") {
                            ForEach(profile.references) { reference in
                                ReferenceForm(reference: reference)
                                .padding(.bottom, 10)
                                Button(action: { 
                                    if let index = profile.references.firstIndex(where: { $0.id == reference.id }) {
                                        profile.references.remove(at: index)
                                    }
                                }) {
                                    Image(systemName: "trash.fill")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                                if reference.id != profile.references.last?.id {
                                    Divider().background(Color.secondary)
                                }
                            }
                            StyledButton(
                                title: "Ajouter une référence", systemImage: "plus",
                                action: {
                                    profile.references.append(
                                        Reference(
                                            name: "", position: "", company: "", email: "",
                                            phone: ""))
                                })
                        }

                         StyledSection(title: "Compétences") {
                             ForEach(profile.skills.indices, id: \.self) { index in
                                 HStack {
                                     TextField(
                                         "Compétence",
                                         text: Binding(
                                             get: { profile.skills[index] },
                                             set: { profile.skills[index] = $0 })
                                     )
                                     .textFieldStyle(StyledTextField())
                                     Button(action: { profile.skills.remove(at: index) }) {
                                         Image(systemName: "trash.fill")
                                             .foregroundColor(.red)
                                     }
                                     .buttonStyle(.plain)
                                 }
                             }
                             StyledButton(
                                 title: "Ajouter une compétence", systemImage: "plus",
                                 action: {
                                     profile.skills.append("")
                                 })
                         }
                    }
                } else {
                    VStack {
                        Spacer()
                        Text("Veuillez sélectionner ou créer un profil.")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle("Profil")
        .toolbarBackground(.hidden, for: .windowToolbar)
    }

    private var profileSelector: some View {
        VStack(alignment: .leading) {
            if selectedProfile == nil {
                HStack {
                    TextField("Nom du nouveau profil", text: $newProfileName)
                        .textFieldStyle(StyledTextField())
                        .foregroundColor(.primary)
                    StyledButton(title: "Créer", action: createProfile)
                }
            }

            Picker("Profil", selection: $selectedProfile) {
                Text("Nouveau Profil").tag(nil as Profile?)
                ForEach(profiles) { profile in
                    Text(profile.name).tag(profile as Profile?)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .modifier(StyledPickerModifier())
        }
    }

    private func createProfile() {
        if !newProfileName.isEmpty {
            let newProfile = Profile(name: newProfileName)
            modelContext.insert(newProfile)
            selectedProfile = newProfile
            newProfileName = ""
        }
    }
}

// MARK: - Reusable Styled Components
extension Color {
    fileprivate static var darkBackground: Color {
        Color.gray.opacity(0.1)
    }

    fileprivate static var sectionBackground: Color {
        Color.gray.opacity(0.1)
    }
}

private struct StyledSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    @State private var isExpanded: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.primary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                content
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .top)),
                            removal: .opacity.combined(with: .move(edge: .top))))
            }
        }
        .padding()
        .background(Color.sectionBackground)
        .cornerRadius(10)
    }
}

private struct StyledButton: View {
    let title: String
    var systemImage: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                if let systemImage = systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
            .foregroundColor(.primary)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.accentColor)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

private struct StyledTextField: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(10)
            .background(Color.darkBackground)
            .cornerRadius(8)
            .foregroundColor(.primary)
    }
}

private struct StyledTextEditorModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(10)
            .scrollContentBackground(.hidden)
            .background(Color.darkBackground)
            .cornerRadius(8)
            .foregroundColor(.primary)
            .frame(minHeight: 100)
    }
}

private struct StyledPickerModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(10)
            .background(Color.sectionBackground)
            .cornerRadius(8)
            .foregroundColor(.primary)
    }
}

// MARK: - Form Views (to be restyled)
struct ExperienceForm: View {
    @Bindable var experience: Experience

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Entreprise", text: $experience.company)
                .foregroundColor(.primary)
            HStack {
                DatePicker("Date de début", selection: $experience.startDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                Spacer()
                DatePicker(
                    "Date de fin",
                    selection: Binding(get: { experience.endDate ?? Date() }, set: { experience.endDate = $0 }),
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
            }
            TextEditor(text: $experience.details)
                .modifier(StyledTextEditorModifier())
        }
        .textFieldStyle(StyledTextField())
    }
}

struct EducationForm: View {
    @Bindable var education: Education

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Institution", text: $education.institution)
                .foregroundColor(.primary)
            TextField("Diplôme", text: $education.degree)
                .foregroundColor(.primary)
            HStack {
                DatePicker("Date de début", selection: $education.startDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                Spacer()
                DatePicker(
                    "Date de fin",
                    selection: Binding(get: { education.endDate ?? Date() }, set: { education.endDate = $0 }),
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
            }
            TextEditor(text: $education.details)
                .modifier(StyledTextEditorModifier())
        }
        .textFieldStyle(StyledTextField())
    }
}

struct ReferenceForm: View {
    @Bindable var reference: Reference

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Nom", text: $reference.name)
                .foregroundColor(.primary)
            TextField("Poste", text: $reference.position)
                .foregroundColor(.primary)
            TextField("Entreprise", text: $reference.company)
            TextField("Email", text: $reference.email)
                .foregroundColor(.primary)
            TextField("Téléphone", text: $reference.phone)
                .foregroundColor(.primary)
        }
        .textFieldStyle(StyledTextField())
    }
}

struct PersonalInfoForm: View {
    @Bindable var profile: Profile

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Photo section
            if let photoData = profile.photo, let nsImage = NSImage(data: photoData) {
                VStack(spacing: 8) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .cornerRadius(8)
                        .clipped()
                    Button(action: {
                        profile.photo = nil
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Supprimer")
                        }
                        .foregroundColor(.red)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray, lineWidth: 2)
                        .frame(width: 100, height: 100)
                    Text("Glissez une photo ici")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(4)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .onDrop(of: [.image], isTargeted: nil) { providers in
                    for provider in providers {
                        provider.loadDataRepresentation(forTypeIdentifier: "public.image") {
                            data, error in
                            if let data = data {
                                DispatchQueue.main.async {
                                    profile.photo = data
                                }
                            }
                        }
                    }
                    return true
                }
             }

             Toggle("Afficher la photo dans le PDF", isOn: $profile.showPhotoInPDF)
                 .toggleStyle(.switch)

             TextField(
                 "Prénom",
                 text: Binding(get: { profile.firstName ?? "" }, set: { profile.firstName = $0.isEmpty ? nil : $0 }))
            TextField(
                "Nom",
                text: Binding(get: { profile.lastName ?? "" }, set: { profile.lastName = $0.isEmpty ? nil : $0 }))
            TextField(
                "Email",
                text: Binding(get: { profile.email ?? "" }, set: { profile.email = $0.isEmpty ? nil : $0 }))
            TextField(
                "Téléphone",
                text: Binding(get: { profile.phone ?? "" }, set: { profile.phone = $0.isEmpty ? nil : $0 }))
            TextField(
                "Localisation",
                text: Binding(get: { profile.location ?? "" }, set: { profile.location = $0.isEmpty ? nil : $0 }))
            TextField(
                "GitHub",
                text: Binding(get: { profile.github ?? "" }, set: { profile.github = $0.isEmpty ? nil : $0 }))
            TextField(
                "GitLab",
                text: Binding(get: { profile.gitlab ?? "" }, set: { profile.gitlab = $0.isEmpty ? nil : $0 }))
            TextField(
                "LinkedIn",
                text: Binding(get: { profile.linkedin ?? "" }, set: { profile.linkedin = $0.isEmpty ? nil : $0 }))
        }
        .textFieldStyle(StyledTextField())
    }
}

// MARK: - Preview
#Preview {
    ProfileView()
        .modelContainer(for: Profile.self, inMemory: true)
}
