import AppKit
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Main Profile View
struct ProfileView: View {
    @Binding var selectedSection: String?
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [Profile]
    @AppStorage("appLanguage") private var appLanguage: String = "fr"

    @State private var selectedProfile: Profile?
    @State private var newProfileName: String = ""
    @State private var renameProfileName: String = ""
    @State private var showRenameAlert: Bool = false
    @State private var showDeleteAlert: Bool = false

    private var effectiveLanguage: String {
        selectedProfile?.language ?? appLanguage
    }

    private func localizedTitle(for key: String) -> String {
        let enDict: [String: String] = [
            "personal_info": "Personal Information",
            "summary": "Summary",
            "experiences": "Experiences",
            "educations": "Educations",
            "references": "References",
            "skills": "Skills",
            "show_section": "Show this section in the CV",
            "visible_cv": "Visible in CV",
            "add_experience": "Add an experience",
            "add_education": "Add an education",
            "add_reference": "Add a reference",
            "add_skill": "Add a skill",
            "first_name": "First Name",
            "last_name": "Last Name",
            "email": "Email",
            "phone": "Phone",
            "location": "Location",
            "github": "GitHub",
            "gitlab": "GitLab",
            "linkedin": "LinkedIn",
            "website": "Website",
            "show_photo_pdf": "Show photo in PDF",
            "select_photo": "Select a photo",
            "drag_photo": "Drag a photo here",
            "cv_language": "CV Language",
            "french": "French",
            "english": "English",
            "company": "Company",
            "start_date": "Start Date",
            "end_date": "End Date",
            "institution": "Institution",
            "degree": "Degree",
            "name": "Name",
            "position": "Position",
            "new_profile_name": "New profile name",
            "create": "Create",
            "profile_selected": "Selected profile: ",
            "rename": "Rename",
            "duplicate": "Duplicate",
            "delete": "Delete",
            "select_section": "Please select or create a profile.",
            "rename_profile": "Rename profile",
            "cancel": "Cancel",
            "delete_profile": "Delete profile",
            "delete_confirm": "Are you sure you want to delete this profile? This action is irreversible."
        ]
        let frDict: [String: String] = [
            "personal_info": "Informations Personnelles",
            "summary": "Résumé",
            "experiences": "Expériences",
            "educations": "Formations",
            "references": "Références",
            "skills": "Compétences",
            "show_section": "Afficher cette section dans le CV",
            "visible_cv": "Visible dans le CV",
            "add_experience": "Ajouter une expérience",
            "add_education": "Ajouter une formation",
            "add_reference": "Ajouter une référence",
            "add_skill": "Ajouter une compétence",
            "first_name": "Prénom",
            "last_name": "Nom",
            "email": "Email",
            "phone": "Téléphone",
            "location": "Localisation",
            "github": "GitHub",
            "gitlab": "GitLab",
            "linkedin": "LinkedIn",
            "website": "Site Web",
            "show_photo_pdf": "Afficher la photo dans le PDF",
            "select_photo": "Sélectionner une photo",
            "drag_photo": "Glissez une photo ici",
            "cv_language": "Langue du CV",
            "french": "Français",
            "english": "English",
            "company": "Entreprise",
            "start_date": "Date de début",
            "end_date": "Date de fin",
            "institution": "Institution",
            "degree": "Diplôme",
            "name": "Nom",
            "position": "Poste",
            "new_profile_name": "Nom du nouveau profil",
            "create": "Créer",
            "profile_selected": "Profil sélectionné: ",
            "rename": "Renommer",
            "duplicate": "Dupliquer",
            "delete": "Supprimer",
            "select_section": "Veuillez sélectionner ou créer un profil.",
            "rename_profile": "Renommer le profil",
            "cancel": "Annuler",
            "delete_profile": "Supprimer le profil",
            "delete_confirm": "Êtes-vous sûr de vouloir supprimer ce profil ? Cette action est irréversible."
        ]
        let dict = effectiveLanguage == "en" ? enDict : frDict
        return dict[key] ?? key
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(effectiveLanguage == "fr" ? "Profil" : "Profile")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .padding(.top)

                profileSelector

                if let profile = selectedProfile {
                    VStack(spacing: 20) {
                        StyledSection(title: localizedTitle(for: "personal_info")) {
                             PersonalInfoForm(profile: profile, language: effectiveLanguage)
                        }

                        StyledSection(title: localizedTitle(for: "summary")) {
                            RichTextEditorWithToolbar(
                                attributedString: Binding(
                                    get: { profile.summaryAttributedString },
                                    set: { profile.summaryAttributedString = $0 }
                                ))
                        }

                         StyledSection(title: localizedTitle(for: "experiences")) {
                             VStack(alignment: .leading, spacing: 12) {
                                 // Section visibility toggle
                                 HStack {
                                     Text(localizedTitle(for: "show_section"))
                                         .font(.subheadline)
                                         .foregroundColor(.secondary)
                                     Spacer()
                                     Toggle(
                                         "",
                                         isOn: Binding(
                                             get: { profile.showExperiences },
                                             set: { profile.showExperiences = $0 }
                                         )
                                     )
                                     .labelsHidden()
                                     .toggleStyle(.switch)
                                 }

                                if profile.showExperiences {
                                    ForEach(profile.experiences) { experience in
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack {
                                                 Toggle(
                                                     localizedTitle(for: "visible_cv"),
                                                     isOn: Binding(
                                                         get: { experience.isVisible },
                                                         set: { experience.isVisible = $0 }
                                                     )
                                                 )
                                                .toggleStyle(.switch)
                                                Spacer()
                                                Button(action: {
                                                    DispatchQueue.main.async {
                                                        if let index = profile.experiences
                                                            .firstIndex(where: {
                                                                $0.id == experience.id
                                                            })
                                                        {
                                                            profile.experiences.remove(at: index)
                                                        }
                                                    }
                                                }) {
                                                    Image(systemName: "trash.fill")
                                                        .foregroundColor(.red)
                                                }
                                                .buttonStyle(.plain)
                                            }
                                             ExperienceForm(experience: experience, language: effectiveLanguage)
                                        }
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(Color.gray.opacity(0.05))
                                        .cornerRadius(8)
                                        if experience.id != profile.experiences.last?.id {
                                            Divider().background(Color.secondary.opacity(0.3))
                                        }
                                    }
                                     StyledButton(
                                         title: localizedTitle(for: "add_experience"), systemImage: "plus",
                                         action: {
                                            DispatchQueue.main.async {
                                                profile.experiences.append(
                                                    Experience(
                                                        company: "", startDate: Date(),
                                                        details: Data()))
                                            }
                                        })
                                }
                            }
                        }

                         StyledSection(title: localizedTitle(for: "educations")) {
                             VStack(alignment: .leading, spacing: 12) {
                                 // Section visibility toggle
                                 HStack {
                                     Text(localizedTitle(for: "show_section"))
                                         .font(.subheadline)
                                         .foregroundColor(.secondary)
                                     Spacer()
                                     Toggle(
                                         "",
                                         isOn: Binding(
                                             get: { profile.showEducations },
                                             set: { profile.showEducations = $0 }
                                         )
                                     )
                                     .labelsHidden()
                                     .toggleStyle(.switch)
                                 }

                                if profile.showEducations {
                                    ForEach(profile.educations) { education in
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack {
                                                 Toggle(
                                                     localizedTitle(for: "visible_cv"),
                                                     isOn: Binding(
                                                         get: { education.isVisible },
                                                         set: { education.isVisible = $0 }
                                                     )
                                                 )
                                                .toggleStyle(.switch)
                                                Spacer()
                                                Button(action: {
                                                    DispatchQueue.main.async {
                                                        if let index = profile.educations
                                                            .firstIndex(where: {
                                                                $0.id == education.id
                                                            })
                                                        {
                                                            profile.educations.remove(at: index)
                                                        }
                                                    }
                                                }) {
                                                    Image(systemName: "trash.fill")
                                                        .foregroundColor(.red)
                                                }
                                                .buttonStyle(.plain)
                                            }
                                             EducationForm(education: education, language: effectiveLanguage)
                                        }
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(Color.gray.opacity(0.05))
                                        .cornerRadius(8)
                                        if education.id != profile.educations.last?.id {
                                            Divider().background(Color.secondary.opacity(0.3))
                                        }
                                    }
                                     StyledButton(
                                         title: localizedTitle(for: "add_education"), systemImage: "plus",
                                         action: {
                                            DispatchQueue.main.async {
                                                profile.educations.append(
                                                    Education(
                                                        institution: "", degree: "",
                                                        startDate: Date(),
                                                        details: Data()))
                                            }
                                        })
                                }
                            }
                        }

                         StyledSection(title: localizedTitle(for: "references")) {
                             VStack(alignment: .leading, spacing: 12) {
                                 // Section visibility toggle
                                 HStack {
                                     Text(localizedTitle(for: "show_section"))
                                         .font(.subheadline)
                                         .foregroundColor(.secondary)
                                     Spacer()
                                     Toggle(
                                         "",
                                         isOn: Binding(
                                             get: { profile.showReferences },
                                             set: { profile.showReferences = $0 }
                                         )
                                     )
                                     .labelsHidden()
                                     .toggleStyle(.switch)
                                 }

                                if profile.showReferences {
                                    ForEach(profile.references) { reference in
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack {
                                                 Toggle(
                                                     localizedTitle(for: "visible_cv"),
                                                     isOn: Binding(
                                                         get: { reference.isVisible },
                                                         set: { reference.isVisible = $0 }
                                                     )
                                                 )
                                                .toggleStyle(.switch)
                                                Spacer()
                                                Button(action: {
                                                    DispatchQueue.main.async {
                                                        if let index = profile.references
                                                            .firstIndex(where: {
                                                                $0.id == reference.id
                                                            })
                                                        {
                                                            profile.references.remove(at: index)
                                                        }
                                                    }
                                                }) {
                                                    Image(systemName: "trash.fill")
                                                        .foregroundColor(.red)
                                                }
                                                .buttonStyle(.plain)
                                            }
                                             ReferenceForm(reference: reference, language: effectiveLanguage)
                                        }
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(Color.gray.opacity(0.05))
                                        .cornerRadius(8)
                                        if reference.id != profile.references.last?.id {
                                            Divider().background(Color.secondary.opacity(0.3))
                                        }
                                    }
                                     StyledButton(
                                         title: localizedTitle(for: "add_reference"), systemImage: "plus",
                                         action: {
                                            DispatchQueue.main.async {
                                                profile.references.append(
                                                    Reference(
                                                        name: "", position: "", company: "",
                                                        email: "",
                                                        phone: ""))
                                            }
                                        })
                                }
                            }
                        }

                         StyledSection(title: localizedTitle(for: "skills")) {
                             VStack(alignment: .leading, spacing: 12) {
                                 // Section visibility toggle
                                 HStack {
                                     Text(localizedTitle(for: "show_section"))
                                         .font(.subheadline)
                                         .foregroundColor(.secondary)
                                     Spacer()
                                     Toggle(
                                         "",
                                         isOn: Binding(
                                             get: { profile.showSkills },
                                             set: { profile.showSkills = $0 }
                                         )
                                     )
                                     .labelsHidden()
                                     .toggleStyle(.switch)
                                 }

                                if profile.showSkills {
                                    ForEach(profile.skills.indices, id: \.self) { index in
                                        HStack {
                                             TextField(
                                                 localizedTitle(for: "skills"),
                                                 text: Binding(
                                                     get: { profile.skills[index] },
                                                     set: { profile.skills[index] = $0 })
                                             )
                                            .textFieldStyle(StyledTextField())
                                            Button(action: {
                                                DispatchQueue.main.async {
                                                    profile.skills.remove(at: index)
                                                }
                                            }) {
                                                Image(systemName: "trash.fill")
                                                    .foregroundColor(.red)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                     StyledButton(
                                         title: localizedTitle(for: "add_skill"), systemImage: "plus",
                                         action: {
                                            DispatchQueue.main.async { profile.skills.append("") }
                                        })
                                }
                            }
                        }
                    }
                } else {
                    VStack {
                        Spacer()
                         Text(localizedTitle(for: "select_section"))
                             .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle("Resume-ATS")
        .environment(\.locale, Locale(identifier: selectedProfile?.language ?? "fr"))
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: {
                    selectedSection = "Dashboard"
                }) {
                    Image(systemName: "chevron.left")
                }
            }
        }
        .alert(localizedTitle(for: "rename_profile"), isPresented: $showRenameAlert) {
             TextField(localizedTitle(for: "new_profile_name"), text: $renameProfileName)
             Button(localizedTitle(for: "cancel"), role: .cancel) {}
             Button(localizedTitle(for: "rename")) {
                confirmRenameProfile()
            }
        }
        .alert(localizedTitle(for: "delete_profile"), isPresented: $showDeleteAlert) {
             Button(localizedTitle(for: "cancel"), role: .cancel) {}
             Button(localizedTitle(for: "delete"), role: .destructive) {
                confirmDeleteProfile()
            }
         } message: {
             Text(localizedTitle(for: "delete_confirm"))
         }
    }

    private var profileSelector: some View {
        VStack(alignment: .leading) {
            if selectedProfile == nil {
                HStack {
                    TextField(localizedTitle(for: "new_profile_name"), text: $newProfileName)
                        .textFieldStyle(StyledTextField())
                        .foregroundColor(.primary)
                    StyledButton(title: localizedTitle(for: "create"), action: createProfile)
                }
            } else {
                HStack {
                     Text(localizedTitle(for: "profile_selected") + selectedProfile!.name)
                         .font(.headline)
                    Spacer()
                     StyledButton(title: localizedTitle(for: "rename"), systemImage: "pencil", action: renameProfile)
                     StyledButton(
                         title: localizedTitle(for: "duplicate"), systemImage: "doc.on.doc", action: duplicateProfile)
                     StyledButton(title: localizedTitle(for: "delete"), systemImage: "trash", action: deleteProfile)
                        .foregroundColor(.red)
                }
            }

            Picker(effectiveLanguage == "fr" ? "Profil" : "Profile", selection: $selectedProfile) {
                Text(effectiveLanguage == "fr" ? "Nouveau Profil" : "New Profile").tag(nil as Profile?)
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

    private func renameProfile() {
        guard let profile = selectedProfile else { return }
        renameProfileName = profile.name
        showRenameAlert = true
    }

    private func duplicateProfile() {
        guard let profile = selectedProfile else { return }
        let duplicatedProfile = Profile(
            name: profile.name + " (Copie)",
            language: profile.language,
            firstName: profile.firstName,
            lastName: profile.lastName,
            email: profile.email,
            phone: profile.phone,
            location: profile.location,
            github: profile.github,
            gitlab: profile.gitlab,
            linkedin: profile.linkedin,
            website: profile.website,
            photo: profile.photo,
            showPhotoInPDF: profile.showPhotoInPDF,
            summary: profile.summary,
            showExperiences: profile.showExperiences,
            showEducations: profile.showEducations,
            showReferences: profile.showReferences,
            showSkills: profile.showSkills,
            experiences: profile.experiences.map { exp in
                Experience(
                    company: exp.company, startDate: exp.startDate, endDate: exp.endDate,
                    details: exp.details, isVisible: exp.isVisible)
            },
            educations: profile.educations.map { edu in
                Education(
                    institution: edu.institution, degree: edu.degree, startDate: edu.startDate,
                    endDate: edu.endDate, details: edu.details, isVisible: edu.isVisible)
            },
            references: profile.references.map { ref in
                Reference(
                    name: ref.name, position: ref.position, company: ref.company, email: ref.email,
                    phone: ref.phone, isVisible: ref.isVisible)
            },
            skills: profile.skills
        )
        modelContext.insert(duplicatedProfile)
        selectedProfile = duplicatedProfile
    }

    private func deleteProfile() {
        showDeleteAlert = true
    }

    private func confirmDeleteProfile() {
        guard let profile = selectedProfile else { return }
        modelContext.delete(profile)
        selectedProfile = nil
    }

    private func confirmRenameProfile() {
        guard let profile = selectedProfile, !renameProfileName.isEmpty else { return }
        profile.name = renameProfileName
        showRenameAlert = false
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
    var language: String

    private func localizedTitle(for key: String) -> String {
        let enDict: [String: String] = [
            "company": "Company",
            "start_date": "Start Date",
            "end_date": "End Date"
        ]
        let frDict: [String: String] = [
            "company": "Entreprise",
            "start_date": "Date de début",
            "end_date": "Date de fin"
        ]
        let dict = language == "en" ? enDict : frDict
        return dict[key] ?? key
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
             TextField(localizedTitle(for: "company"), text: $experience.company)
                 .foregroundColor(.primary)
             HStack {
                 DatePicker(
                     localizedTitle(for: "start_date"), selection: $experience.startDate, displayedComponents: .date
                 )
                 .datePickerStyle(.compact)
                 Spacer()
                 DatePicker(
                     localizedTitle(for: "end_date"),
                     selection: Binding(
                         get: { experience.endDate ?? Date() }, set: { experience.endDate = $0 }),
                     displayedComponents: .date
                 )
                 .datePickerStyle(.compact)
             }
            RichTextEditorWithToolbar(
                attributedString: Binding(
                    get: { experience.detailsAttributedString },
                    set: { experience.detailsAttributedString = $0 }
                ))
        }
        .textFieldStyle(StyledTextField())
    }
}

struct EducationForm: View {
    @Bindable var education: Education
    var language: String

    private func localizedTitle(for key: String) -> String {
        let enDict: [String: String] = [
            "institution": "Institution",
            "degree": "Degree",
            "start_date": "Start Date",
            "end_date": "End Date"
        ]
        let frDict: [String: String] = [
            "institution": "Institution",
            "degree": "Diplôme",
            "start_date": "Date de début",
            "end_date": "Date de fin"
        ]
        let dict = language == "en" ? enDict : frDict
        return dict[key] ?? key
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
             TextField(localizedTitle(for: "institution"), text: $education.institution)
                 .foregroundColor(.primary)
             TextField(localizedTitle(for: "degree"), text: $education.degree)
                 .foregroundColor(.primary)
             HStack {
                 DatePicker(
                     localizedTitle(for: "start_date"), selection: $education.startDate, displayedComponents: .date
                 )
                 .datePickerStyle(.compact)
                 Spacer()
                 DatePicker(
                     localizedTitle(for: "end_date"),
                     selection: Binding(
                         get: { education.endDate ?? Date() }, set: { education.endDate = $0 }),
                     displayedComponents: .date
                 )
                 .datePickerStyle(.compact)
             }
            RichTextEditorWithToolbar(
                attributedString: Binding(
                    get: { education.detailsAttributedString },
                    set: { education.detailsAttributedString = $0 }
                ))
        }
        .textFieldStyle(StyledTextField())
    }
}

struct ReferenceForm: View {
    @Bindable var reference: Reference
    var language: String

    private func localizedTitle(for key: String) -> String {
        let enDict: [String: String] = [
            "name": "Name",
            "position": "Position",
            "company": "Company",
            "email": "Email",
            "phone": "Phone"
        ]
        let frDict: [String: String] = [
            "name": "Nom",
            "position": "Poste",
            "company": "Entreprise",
            "email": "Email",
            "phone": "Téléphone"
        ]
        let dict = language == "en" ? enDict : frDict
        return dict[key] ?? key
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
             TextField(localizedTitle(for: "name"), text: $reference.name)
                 .foregroundColor(.primary)
             TextField(localizedTitle(for: "position"), text: $reference.position)
                 .foregroundColor(.primary)
             TextField(localizedTitle(for: "company"), text: $reference.company)
             TextField(localizedTitle(for: "email"), text: $reference.email)
                 .foregroundColor(.primary)
             TextField(localizedTitle(for: "phone"), text: $reference.phone)
                 .foregroundColor(.primary)
         }
        .textFieldStyle(StyledTextField())
    }
}

struct PersonalInfoForm: View {
    @Bindable var profile: Profile
    var language: String
    @State private var tempPhotoData: Data?
    @State private var showCropView = false

    private func localizedTitle(for key: String) -> String {
        let enDict: [String: String] = [
            "cv_language": "CV Language",
            "french": "French",
            "english": "English",
            "first_name": "First Name",
            "last_name": "Last Name",
            "email": "Email",
            "phone": "Phone",
            "location": "Location",
            "github": "GitHub",
            "gitlab": "GitLab",
            "linkedin": "LinkedIn",
            "website": "Website",
            "show_photo_pdf": "Show photo in PDF",
            "select_photo": "Select a photo",
            "drag_photo": "Drag a photo here"
        ]
        let frDict: [String: String] = [
            "cv_language": "Langue du CV",
            "french": "Français",
            "english": "English",
            "first_name": "Prénom",
            "last_name": "Nom",
            "email": "Email",
            "phone": "Téléphone",
            "location": "Localisation",
            "github": "GitHub",
            "gitlab": "GitLab",
            "linkedin": "LinkedIn",
            "website": "Site Web",
            "show_photo_pdf": "Afficher la photo dans le PDF",
            "select_photo": "Sélectionner une photo",
            "drag_photo": "Glissez une photo ici"
        ]
        let dict = language == "en" ? enDict : frDict
        return dict[key] ?? key
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker(localizedTitle(for: "cv_language"), selection: $profile.language) {
                Text(localizedTitle(for: "french")).tag("fr")
                Text(localizedTitle(for: "english")).tag("en")
            }
            .pickerStyle(.menu)

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
                            Text(language == "fr" ? "Supprimer" : "Delete")
                        }
                        .foregroundColor(.red)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            } else {
                VStack(spacing: 8) {
                     Button(localizedTitle(for: "select_photo")) {
                        selectPhoto()
                    }
                    .buttonStyle(.bordered)

                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray, lineWidth: 2)
                            .frame(width: 100, height: 100)
                         Text(localizedTitle(for: "drag_photo"))
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
                                        tempPhotoData = data
                                        showCropView = true
                                    }
                                }
                            }
                        }
                        return true
                    }
                }
            }

            Toggle(localizedTitle(for: "show_photo_pdf"), isOn: $profile.showPhotoInPDF)
                .toggleStyle(.switch)

            TextField(
                localizedTitle(for: "first_name"),
                text: Binding(
                    get: { profile.firstName ?? "" },
                    set: { profile.firstName = $0.isEmpty ? nil : $0 }))
            TextField(
                localizedTitle(for: "last_name"),
                text: Binding(
                    get: { profile.lastName ?? "" },
                    set: { profile.lastName = $0.isEmpty ? nil : $0 }))
            TextField(
                localizedTitle(for: "email"),
                text: Binding(
                    get: { profile.email ?? "" }, set: { profile.email = $0.isEmpty ? nil : $0 }))
            TextField(
                localizedTitle(for: "phone"),
                text: Binding(
                    get: { profile.phone ?? "" }, set: { profile.phone = $0.isEmpty ? nil : $0 }))
            TextField(
                localizedTitle(for: "location"),
                text: Binding(
                    get: { profile.location ?? "" },
                    set: { profile.location = $0.isEmpty ? nil : $0 }))
            TextField(
                localizedTitle(for: "github"),
                text: Binding(
                    get: { profile.github ?? "" }, set: { profile.github = $0.isEmpty ? nil : $0 }))
            TextField(
                localizedTitle(for: "gitlab"),
                text: Binding(
                    get: { profile.gitlab ?? "" }, set: { profile.gitlab = $0.isEmpty ? nil : $0 }))
            TextField(
                localizedTitle(for: "linkedin"),
                text: Binding(
                    get: { profile.linkedin ?? "" },
                    set: { profile.linkedin = $0.isEmpty ? nil : $0 }))
            TextField(
                localizedTitle(for: "website"),
                text: Binding(
                    get: { profile.website ?? "" },
                    set: { profile.website = $0.isEmpty ? nil : $0 }))
        }
        .textFieldStyle(StyledTextField())
        .sheet(isPresented: $showCropView) {
            PhotoCropView(croppedData: $tempPhotoData)
                .onDisappear {
                    if let croppedData = tempPhotoData {
                        profile.photo = croppedData
                    }
                    tempPhotoData = nil
                }
        }
    }

    private func selectPhoto() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            do {
                let data = try Data(contentsOf: url)
                tempPhotoData = data
                showCropView = true
            } catch {
                print("Error loading image: \(error)")
            }
        }
    }
}

// MARK: - Rich Text Editor
struct RichTextEditor: NSViewRepresentable {
    @Binding var attributedString: NSAttributedString
    @Binding var selectedRange: NSRange

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let textView = NSTextView()
        textView.isRichText = true
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.usesRuler = false
        textView.usesInspectorBar = false
        textView.delegate = context.coordinator
        textView.textColor = NSColor.labelColor
        textView.font = NSFont.systemFont(ofSize: 20.0)
        textView.drawsBackground = false
        textView.backgroundColor = NSColor.clear

        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        scrollView.backgroundColor = NSColor.clear

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        if let textView = nsView.documentView as? NSTextView {
            textView.textColor = NSColor.labelColor
            textView.font = NSFont.systemFont(ofSize: 14.0)
            textView.typingAttributes[.font] = NSFont.systemFont(ofSize: 14.0)
            let mutableString = NSMutableAttributedString(attributedString: attributedString)
            mutableString.addAttribute(
                .foregroundColor, value: NSColor.labelColor,
                range: NSRange(location: 0, length: mutableString.length))
            // Update font size in the attributed string
            mutableString.enumerateAttribute(
                .font, in: NSRange(location: 0, length: mutableString.length), options: []
            ) { value, range, _ in
                if let font = value as? NSFont {
                    let newFont =
                        NSFont(descriptor: font.fontDescriptor, size: 14.0)
                        ?? NSFont.systemFont(ofSize: 14.0)
                    mutableString.addAttribute(.font, value: newFont, range: range)
                } else {
                    mutableString.addAttribute(
                        .font, value: NSFont.systemFont(ofSize: 14.0), range: range)
                }
            }
            if textView.attributedString() != mutableString {
                textView.textStorage?.setAttributedString(mutableString)
            }
            let clampedRange = NSRange(
                location: min(selectedRange.location, mutableString.length),
                length: min(
                    selectedRange.length,
                    mutableString.length - min(selectedRange.location, mutableString.length)))
            if textView.selectedRange() != clampedRange {
                textView.setSelectedRange(clampedRange)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: RichTextEditor

        init(_ parent: RichTextEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            if let textView = notification.object as? NSTextView {
                let newString = textView.attributedString()
                DispatchQueue.main.async {
                    self.parent.attributedString = newString
                }
            }
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            if let textView = notification.object as? NSTextView {
                let newRange = textView.selectedRange()
                DispatchQueue.main.async {
                    self.parent.selectedRange = newRange
                }
            }
        }
    }
}

struct RichTextToolbar: View {
    @Binding var attributedString: NSAttributedString
    @Binding var selectedRange: NSRange

    var body: some View {
        HStack(spacing: 8) {
            Button(action: { toggleBold() }) {
                Image(systemName: "bold")
            }
            .buttonStyle(.bordered)

            Button(action: { toggleItalic() }) {
                Image(systemName: "italic")
            }
            .buttonStyle(.bordered)

            Button(action: { insertBullet() }) {
                Image(systemName: "list.bullet")
            }
            .buttonStyle(.bordered)

            Button(action: { insertLineBreak() }) {
                Image(systemName: "arrow.right.to.line")
            }
            .buttonStyle(.bordered)
        }
        .padding(4)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(6)
    }

    private func toggleBold() {
        let mutableString = NSMutableAttributedString(attributedString: attributedString)
        let fontManager = NSFontManager.shared
        let validRange = NSRange(
            location: min(selectedRange.location, attributedString.length),
            length: min(
                selectedRange.length,
                attributedString.length - min(selectedRange.location, attributedString.length)))
        if validRange.length > 0 {
            mutableString.enumerateAttribute(.font, in: validRange, options: []) {
                value, range, _ in
                if let font = value as? NSFont {
                    let newFont = fontManager.convert(font, toHaveTrait: .boldFontMask)
                    mutableString.addAttribute(.font, value: newFont, range: range)
                }
            }
        } else {
            // Apply to current position or whole text if no selection
            let range =
                validRange.length > 0
                ? validRange : NSRange(location: 0, length: mutableString.length)
            mutableString.enumerateAttribute(.font, in: range, options: []) { value, range, _ in
                if let font = value as? NSFont {
                    let newFont = fontManager.convert(font, toHaveTrait: .boldFontMask)
                    mutableString.addAttribute(.font, value: newFont, range: range)
                }
            }
        }
        DispatchQueue.main.async {
            attributedString = mutableString
        }
    }

    private func toggleItalic() {
        let mutableString = NSMutableAttributedString(attributedString: attributedString)
        let fontManager = NSFontManager.shared
        let validRange = NSRange(
            location: min(selectedRange.location, attributedString.length),
            length: min(
                selectedRange.length,
                attributedString.length - min(selectedRange.location, attributedString.length)))
        if validRange.length > 0 {
            mutableString.enumerateAttribute(.font, in: validRange, options: []) {
                value, range, _ in
                if let font = value as? NSFont {
                    let newFont = fontManager.convert(font, toHaveTrait: .italicFontMask)
                    mutableString.addAttribute(.font, value: newFont, range: range)
                }
            }
        } else {
            let range = NSRange(location: 0, length: mutableString.length)
            mutableString.enumerateAttribute(.font, in: range, options: []) { value, range, _ in
                if let font = value as? NSFont {
                    let newFont = fontManager.convert(font, toHaveTrait: .italicFontMask)
                    mutableString.addAttribute(.font, value: newFont, range: range)
                }
            }
        }
        DispatchQueue.main.async {
            attributedString = mutableString
        }
    }

    private func insertBullet() {
        let bullet = "• "
        let mutableString = NSMutableAttributedString(attributedString: attributedString)
        let location = min(selectedRange.location, attributedString.length)
        mutableString.insert(NSAttributedString(string: bullet), at: location)
        DispatchQueue.main.async {
            attributedString = mutableString
        }
    }

    private func insertLineBreak() {
        let lineBreak = "\n"
        let mutableString = NSMutableAttributedString(attributedString: attributedString)
        let location = min(selectedRange.location, attributedString.length)
        mutableString.insert(NSAttributedString(string: lineBreak), at: location)
        DispatchQueue.main.async {
            attributedString = mutableString
        }
    }
}

struct RichTextEditorWithToolbar: View {
    @Binding var attributedString: NSAttributedString

    @State private var selectedRange: NSRange = NSRange(location: 0, length: 0)

    var body: some View {
        VStack(spacing: 0) {
            RichTextToolbar(attributedString: $attributedString, selectedRange: $selectedRange)
            RichTextEditor(attributedString: $attributedString, selectedRange: $selectedRange)
                .frame(minHeight: 100)
                .background(Color.darkBackground)
                .cornerRadius(8)
        }
    }
}

// MARK: - Preview
#Preview {
    ProfileView(selectedSection: .constant(nil))
        .modelContainer(for: Profile.self, inMemory: true)
}
