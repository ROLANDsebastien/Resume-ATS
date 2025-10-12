import AppKit
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Profile View
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
            "certifications": "Certifications",
            "languages": "Languages",

            "show_section": "Show this section in the CV",
            "visible_cv": "Visible in CV",
            "add_experience": "Add an experience",
            "add_education": "Add an education",
            "add_reference": "Add a reference",
            "add_skill": "Add a skill",
            "add_certification": "Add a certification",
            "add_language": "Add a language",
            "add_skill_group": "Add a skill group",
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
            "delete_confirm":
                "Are you sure you want to delete this profile? This action is irreversible.",
            "level": "Level",
            "date": "Date",
            "certification_number": "Certification Number",
            "web_link": "Web Link",
        ]
        let frDict: [String: String] = [
            "personal_info": "Informations Personnelles",
            "summary": "Résumé",
            "experiences": "Expériences",
            "educations": "Formations",
            "references": "Références",
            "skills": "Compétences",
            "certifications": "Certifications",
            "languages": "Langues",

            "show_section": "Afficher cette section dans le CV",
            "visible_cv": "Visible dans le CV",
            "add_experience": "Ajouter une expérience",
            "add_education": "Ajouter une formation",
            "add_reference": "Ajouter une référence",
            "add_skill": "Ajouter une compétence",
            "add_certification": "Ajouter une certification",
            "add_language": "Ajouter une langue",
            "add_skill_group": "Ajouter un groupe de compétences",
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
            "delete_confirm":
                "Êtes-vous sûr de vouloir supprimer ce profil ? Cette action est irréversible.",
            "level": "Niveau",
            "date": "Date",
            "certification_number": "Numéro de certification",
            "web_link": "Lien Web",
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
                         StyledSection(title: localizedTitle(for: "personal_info"), section: nil, language: effectiveLanguage) {
                             PersonalInfoForm(profile: profile, language: effectiveLanguage)
                         }



                         VStack(spacing: 0) {
                             ForEach(profile.sectionsOrder.indices, id: \.self) { index in
                                 if index > 0 {
                                     DropZoneView(targetIndex: index, onDrop: handleDrop)
                                 }
                                 StyledSection(title: "", section: profile.sectionsOrder[index], language: effectiveLanguage) {
                                     sectionView(for: profile.sectionsOrder[index], profile: profile)
                                 }
                             }
                         }
                     }
                     .onAppear {
                         if profile.sectionsOrder.isEmpty {
                             profile.sectionsOrder = SectionType.allCases
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

    @ViewBuilder
    private func sectionView(for section: SectionType, profile: Profile) -> some View {
        switch section {
        case .summary:
            RichTextEditorWithToolbar(
                attributedString: Binding(
                    get: { profile.summaryAttributedString },
                    set: { profile.summaryAttributedString = $0 }
                ))
        case .experiences:
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
                            ExperienceForm(
                                experience: experience, language: effectiveLanguage)
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
                        title: localizedTitle(for: "add_experience"),
                        systemImage: "plus",
                        action: {
                            DispatchQueue.main.async {
                                profile.experiences.append(
                                    Experience(
                                        company: "",
                                        startDate: Date(),
                                        details: Data()))
                            }
                        })
                }
            }
        case .educations:
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
                            EducationForm(
                                education: education, language: effectiveLanguage)
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
                        title: localizedTitle(for: "add_education"),
                        systemImage: "plus",
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
        case .references:
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
                            ReferenceForm(
                                reference: reference, language: effectiveLanguage)
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
                        title: localizedTitle(for: "add_reference"),
                        systemImage: "plus",
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
        case .certifications:
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
                            get: { profile.showCertifications },
                            set: { profile.showCertifications = $0 }
                        )
                    )
                    .labelsHidden()
                    .toggleStyle(.switch)
                }

                if profile.showCertifications {
                    ForEach(profile.certifications) { certification in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Toggle(
                                    localizedTitle(for: "visible_cv"),
                                    isOn: Binding(
                                        get: { certification.isVisible },
                                        set: { certification.isVisible = $0 }
                                    )
                                )
                                .toggleStyle(.switch)
                                Spacer()
                                Button(action: {
                                    DispatchQueue.main.async {
                                        if let index = profile.certifications
                                            .firstIndex(where: {
                                                $0.id == certification.id
                                            })
                                        {
                                            profile.certifications.remove(at: index)
                                        }
                                    }
                                }) {
                                    Image(systemName: "trash.fill")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }
                            CertificationForm(
                                certification: certification,
                                language: effectiveLanguage)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(8)
                        if certification.id != profile.certifications.last?.id {
                            Divider().background(Color.secondary.opacity(0.3))
                        }
                    }
                    StyledButton(
                        title: localizedTitle(for: "add_certification"),
                        systemImage: "plus",
                        action: {
                            DispatchQueue.main.async {
                                profile.certifications.append(
                                    Certification(
                                        name: "", date: Date(),
                                        certificationNumber: nil))
                            }
                        })
                }
            }
        case .languages:
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
                            get: { profile.showLanguages },
                            set: { profile.showLanguages = $0 }
                        )
                    )
                    .labelsHidden()
                    .toggleStyle(.switch)
                }

                if profile.showLanguages {
                    ForEach(profile.languages) { languageItem in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Toggle(
                                    localizedTitle(for: "visible_cv"),
                                    isOn: Binding(
                                        get: { languageItem.isVisible },
                                        set: { languageItem.isVisible = $0 }
                                    )
                                )
                                .toggleStyle(.switch)
                                Spacer()
                                Button(action: {
                                    DispatchQueue.main.async {
                                        if let index = profile.languages
                                            .firstIndex(where: {
                                                $0.id == languageItem.id
                                            })
                                        {
                                            profile.languages.remove(at: index)
                                        }
                                    }
                                }) {
                                    Image(systemName: "trash.fill")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }
                            LanguageForm(
                                languageItem: languageItem,
                                language: effectiveLanguage)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(8)
                        if languageItem.id != profile.languages.last?.id {
                            Divider().background(Color.secondary.opacity(0.3))
                        }
                    }
                    StyledButton(
                        title: localizedTitle(for: "add_language"),
                        systemImage: "plus",
                        action: {
                            DispatchQueue.main.async {
                                profile.languages.append(
                                    Language(name: "", level: nil))
                            }
                        })
                }
            }
        case .skills:
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
                    ForEach(profile.skills) { skillGroup in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Spacer()
                                Button(action: {
                                    DispatchQueue.main.async {
                                        if let index = profile.skills
                                            .firstIndex(where: {
                                                $0.id == skillGroup.id
                                            })
                                        {
                                            profile.skills.remove(at: index)
                                        }
                                    }
                                }) {
                                    Image(systemName: "trash.fill")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }
                            SkillGroupForm(
                                skillGroup: skillGroup, language: effectiveLanguage)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(8)
                        if skillGroup.id != profile.skills.last?.id {
                            Divider().background(Color.secondary.opacity(0.3))
                        }
                    }
                    StyledButton(
                        title: localizedTitle(for: "add_skill_group"),
                        systemImage: "plus",
                        action: {
                            DispatchQueue.main.async {
                                profile.skills.append(
                                    SkillGroup(title: "", skills: []))
                            }
                        })
                }
            }
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
                    StyledButton(
                        title: localizedTitle(for: "rename"), systemImage: "pencil",
                        action: renameProfile)
                    StyledButton(
                        title: localizedTitle(for: "duplicate"), systemImage: "doc.on.doc",
                        action: duplicateProfile)
                    StyledButton(
                        title: localizedTitle(for: "delete"), systemImage: "trash",
                        action: deleteProfile
                    )
                    .foregroundColor(.red)
                }
            }

            Picker(effectiveLanguage == "fr" ? "Profil" : "Profile", selection: $selectedProfile) {
                Text(effectiveLanguage == "fr" ? "Nouveau Profil" : "New Profile").tag(
                    nil as Profile?)
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
            showExperiences: !profile.experiences.isEmpty,
            showEducations: !profile.educations.isEmpty,
            showReferences: !profile.references.isEmpty,
            showSkills: !profile.skills.isEmpty,
            showCertifications: !profile.certifications.isEmpty,
            showLanguages: !profile.languages.isEmpty,
            sectionsOrder: profile.sectionsOrder,
            experiences: profile.experiences.map { exp in
                Experience(
                    company: exp.company, position: exp.position, startDate: exp.startDate,
                    endDate: exp.endDate,
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
            skills: profile.skills.map { skillGroup in
                SkillGroup(title: skillGroup.title, skills: skillGroup.skills)
            },
            certifications: profile.certifications.map { cert in
                Certification(
                    name: cert.name, date: cert.date, certificationNumber: cert.certificationNumber,
                    webLink: cert.webLink, isVisible: cert.isVisible)
            },
            languages: profile.languages.map { lang in
                Language(name: lang.name, level: lang.level, isVisible: lang.isVisible)
            }
        )
        modelContext.insert(duplicatedProfile)
        try? modelContext.save()
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

    private func handleDrop(providers: [NSItemProvider], targetIndex: Int) {
        guard let provider = providers.first else { return }
        _ = provider.loadObject(ofClass: NSString.self) { string, error in
            if let sectionRaw = string as? String,
                let draggedSection = SectionType(rawValue: sectionRaw),
                let fromIndex = selectedProfile?.sectionsOrder.firstIndex(of: draggedSection)
            {
                DispatchQueue.main.async {
                    selectedProfile?.sectionsOrder.move(fromOffsets: IndexSet([fromIndex]), toOffset: targetIndex)
                }
            }
        }
    }
}

// MARK: - Reusable Styled Components



private struct StyledSection<Content: View>: View {
    let title: String
    let section: SectionType?
    let language: String
    @ViewBuilder let content: Content
    @State private var isExpanded: Bool = false

    private func localizedTitle(for key: String) -> String {
        let enDict: [String: String] = [
            "summary": "Summary",
            "experiences": "Experiences",
            "educations": "Educations",
            "references": "References",
            "skills": "Skills",
            "certifications": "Certifications",
            "languages": "Languages",
        ]
        let frDict: [String: String] = [
            "summary": "Résumé",
            "experiences": "Expériences",
            "educations": "Formations",
            "references": "Références",
            "skills": "Compétences",
            "certifications": "Certifications",
            "languages": "Langues",
        ]
        let dict = language == "en" ? enDict : frDict
        return dict[key] ?? key
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                if section != nil {
                    Image(systemName: "line.horizontal.3")
                        .foregroundColor(.secondary)
                }
                Text(section != nil ? localizedTitle(for: section!.rawValue) : title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .foregroundColor(.primary)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring()) {
                    isExpanded.toggle()
                }
            }
            .onDrag {
                if let section = section {
                    return NSItemProvider(object: section.rawValue as NSString)
                } else {
                    return NSItemProvider()
                }
            }

            if isExpanded {
                content
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .top)),
                            removal: .opacity.combined(with: .move(edge: .top))))
            }
        }
        .padding()
        .background(.regularMaterial)
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
            .background(.thinMaterial).cornerRadius(8)
            .foregroundColor(.primary)
    }
}

private struct StyledTextEditorModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(10)
            .scrollContentBackground(.hidden)
            .background(.thinMaterial)
            .cornerRadius(8)
            .foregroundColor(.primary)
            .frame(minHeight: 100)
    }
}

private struct StyledPickerModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(10)
            .background(.thinMaterial)
            .cornerRadius(8)
            .foregroundColor(.primary)
    }
}

// MARK: - Form Views (to be restyled)

struct CertificationForm: View {
    @Bindable var certification: Certification
    var language: String

    private func localizedTitle(for key: String) -> String {
        let enDict: [String: String] = [
            "name": "Name",
            "date": "Date",
            "certification_number": "Certification Number",
            "web_link": "Web Link",
        ]
        let frDict: [String: String] = [
            "name": "Nom",
            "date": "Date",
            "certification_number": "Numéro de certification",
            "web_link": "Lien Web",
        ]
        let dict = language == "en" ? enDict : frDict
        return dict[key] ?? key
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField(localizedTitle(for: "name"), text: $certification.name)
                .foregroundColor(.primary)
            DatePicker(
                localizedTitle(for: "date"),
                selection: Binding(
                    get: { certification.date ?? Date() },
                    set: { certification.date = $0 }
                ),
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            TextField(
                localizedTitle(for: "certification_number"),
                text: Binding(
                    get: { certification.certificationNumber ?? "" },
                    set: { certification.certificationNumber = $0.isEmpty ? nil : $0 }
                )
            )
            .foregroundColor(.primary)
            TextField(
                localizedTitle(for: "web_link"),
                text: Binding(
                    get: { certification.webLink ?? "" },
                    set: { certification.webLink = $0.isEmpty ? nil : $0 }
                )
            )
            .foregroundColor(.primary)
        }
        .textFieldStyle(StyledTextField())
    }
}

struct LanguageForm: View {
    @Bindable var languageItem: Language
    var language: String

    private func localizedTitle(for key: String) -> String {
        let enDict: [String: String] = [
            "name": "Name",
            "level": "Level",
        ]
        let frDict: [String: String] = [
            "name": "Nom",
            "level": "Niveau",
        ]
        let dict = language == "en" ? enDict : frDict
        return dict[key] ?? key
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField(localizedTitle(for: "name"), text: $languageItem.name)
                .foregroundColor(.primary)
            TextField(
                localizedTitle(for: "level"),
                text: Binding(
                    get: { languageItem.level ?? "" },
                    set: { languageItem.level = $0.isEmpty ? nil : $0 }
                )
            )
            .foregroundColor(.primary)
        }
        .textFieldStyle(StyledTextField())
    }
}

struct SkillGroupForm: View {
    @Bindable var skillGroup: SkillGroup
    var language: String

    private func localizedTitle(for key: String) -> String {
        let enDict: [String: String] = [
            "title": "Title",
            "skills": "Skills",
            "add_skill": "Add a skill",
        ]
        let frDict: [String: String] = [
            "title": "Titre",
            "skills": "Compétences",
            "add_skill": "Ajouter une compétence",
        ]
        let dict = language == "en" ? enDict : frDict
        return dict[key] ?? key
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField(localizedTitle(for: "title"), text: $skillGroup.title)
                .foregroundColor(.primary)

            ForEach(skillGroup.skills.indices, id: \.self) { index in
                HStack {
                    TextField(
                        "",
                        text: $skillGroup.skills[index]
                    )
                    .textFieldStyle(StyledTextField())
                    Button(action: {
                        skillGroup.skills.remove(at: index)
                    }) {
                        Image(systemName: "trash.fill")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
            }

            StyledButton(
                title: localizedTitle(for: "add_skill"),
                systemImage: "plus",
                action: {
                    skillGroup.skills.append("")
                }
            )
        }
        .textFieldStyle(StyledTextField())
    }
}

struct ExperienceForm: View {
    @Bindable var experience: Experience
    var language: String

    private func localizedTitle(for key: String) -> String {
        let enDict: [String: String] = [
            "company": "Company",
            "position": "Position",
            "start_date": "Start Date",
            "end_date": "End Date",
        ]
        let frDict: [String: String] = [
            "company": "Entreprise",
            "position": "Poste",
            "start_date": "Date de début",
            "end_date": "Date de fin",
        ]
        let dict = language == "en" ? enDict : frDict
        return dict[key] ?? key
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField(localizedTitle(for: "company"), text: $experience.company)
                .foregroundColor(.primary)
            TextField(
                localizedTitle(for: "position"),
                text: Binding(
                    get: { experience.position ?? "" },
                    set: { experience.position = $0.isEmpty ? nil : $0 }
                )
            )
            .foregroundColor(.primary)
            HStack {
                DatePicker(
                    localizedTitle(for: "start_date"), selection: $experience.startDate,
                    displayedComponents: .date
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
            "end_date": "End Date",
        ]
        let frDict: [String: String] = [
            "institution": "Institution",
            "degree": "Diplôme",
            "start_date": "Date de début",
            "end_date": "Date de fin",
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
                    localizedTitle(for: "start_date"), selection: $education.startDate,
                    displayedComponents: .date
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
            "phone": "Phone",
        ]
        let frDict: [String: String] = [
            "name": "Nom",
            "position": "Poste",
            "company": "Entreprise",
            "email": "Email",
            "phone": "Téléphone",
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
            "drag_photo": "Drag a photo here",
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
            "drag_photo": "Glissez une photo ici",
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

private struct DropZoneView: View {
    let targetIndex: Int
    let onDrop: ([NSItemProvider], Int) -> Void

    @State private var isTargeted = false

    var body: some View {
        Rectangle()
            .fill(isTargeted ? Color.accentColor : Color.clear)
            .frame(height: isTargeted ? 5 : 2)
            .cornerRadius(2.5)
            .padding(.vertical, isTargeted ? 8 : 0)
            .animation(.spring(), value: isTargeted)
            .onDrop(of: [.text], isTargeted: $isTargeted) { providers in
                onDrop(providers, targetIndex)
                return true
            }
    }
}

// MARK: - Preview
#Preview {
    ProfileView(selectedSection: .constant(nil))
        .modelContainer(for: Profile.self, inMemory: true)
}
