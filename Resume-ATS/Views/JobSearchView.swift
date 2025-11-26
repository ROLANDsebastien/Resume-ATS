import SwiftUI
import SwiftData

struct JobSearchView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [Profile]
    @State private var jobSearchService = JobSearchService()
    
    @State private var selectedProfile: Profile?
    @State private var searchText = ""
    @State private var locationText = ""
    @State private var distanceKm: Int = 50
    @State private var isSearching = false
    @State private var searchProgress: Double = 0
    @State private var currentSearchingSite = ""
    @State private var jobs: [Job] = []
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var selectedJob: Job?
    @State private var showingJobDetail = false
    @State private var selectedSources: Set<String> = []
    @State private var minScore: Int = 0
    @State private var showingFilters = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header moderne
            modernHeaderView
            
            // Filtres
            if showingFilters {
                filtersView
            }
            
            // Liste des résultats ou état vide
            if jobs.isEmpty {
                emptyStateView
            } else {
                List {
                    ForEach(jobs) { job in
                        ModernJobCard(job: job, profile: selectedProfile, profiles: profiles)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets())
                            .onTapGesture {
                                selectedJob = job
                                showingJobDetail = true
                            }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Resume-ATS")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingFilters.toggle() }) {
                    Image(systemName: showingFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .foregroundColor(.accentColor)
                }
            }
        }
        .alert("Erreur", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showingJobDetail) {
            if let job = selectedJob {
                JobDetailView(job: job)
            }
        }
        .onAppear {
            if selectedProfile == nil && !profiles.isEmpty {
                selectedProfile = profiles.first
            }
        }
    }
    
    // MARK: - Modern Header View
    
    private var modernHeaderView: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Titre principal
            VStack(alignment: .leading, spacing: 6) {
                Text("Recherche Intelligente d'Emploi")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Sélectionnez votre profil pour trouver des emplois compatibles avec vos expériences et compétences.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            
            // Barre de recherche
            HStack(spacing: 12) {
                // Profile Selector
                Menu {
                    if profiles.isEmpty {
                        Text("Aucun profil disponible")
                    } else {
                        ForEach(profiles) { profile in
                            Button(action: {
                                selectedProfile = profile
                            }) {
                                HStack {
                                    Text(profile.name.isEmpty ? "Profil sans nom" : profile.name)
                                    if selectedProfile?.id == profile.id {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "person.circle")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                        
                        Text(selectedProfile?.name.isEmpty == false ? selectedProfile!.name : "Choisir un profil")
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(width: 220)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                }
                .menuStyle(BorderlessButtonMenuStyle())
                
                // City Input
                HStack(spacing: 8) {
                    Image(systemName: "mappin.circle")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                    
                    TextField("Ville (ex: Brussels)", text: $locationText)
                        .font(.system(size: 14))
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(width: 220)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
                
                // Distance Selector
                Menu {
                    ForEach([10, 25, 50, 75, 100], id: \.self) { distance in
                        Button(action: {
                            distanceKm = distance
                        }) {
                            HStack {
                                Text("\(distance) km")
                                if distanceKm == distance {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "circle.dashed")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                        
                        Text("\(distanceKm)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Text("km")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(width: 100)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                }
                .menuStyle(BorderlessButtonMenuStyle())
                
                // Search Button
                Button(action: performSearch) {
                    HStack(spacing: 8) {
                        if isSearching {
                            ProgressView()
                                .scaleEffect(0.6)
                                .frame(width: 16, height: 16)
                        } else {
                            Image(systemName: "sparkles")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        Text("Rechercher")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .disabled(selectedProfile == nil || isSearching)
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
    
    // MARK: - Filters View
    
    private var filtersView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Filtres")
                .font(.headline)
                .padding(.horizontal, 24)
            
            // Score minimum
            VStack(alignment: .leading, spacing: 8) {
                Text("Score de compatibilité minimum: \(minScore)%")
                    .font(.subheadline)
                
                Slider(value: Binding(
                    get: { Double(minScore) },
                    set: { minScore = Int($0) }
                ), in: 0...100, step: 5)
                .tint(.blue)
            }
            .padding(.horizontal, 24)
            
            // Sources
            VStack(alignment: .leading, spacing: 8) {
                Text("Sources:")
                    .font(.subheadline)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(jobSearchService.getAvailableSources(), id: \.self) { source in
                        Toggle(source, isOn: Binding(
                            get: { selectedSources.contains(source) },
                            set: { isSelected in
                                if isSelected {
                                    selectedSources.insert(source)
                                } else {
                                    selectedSources.remove(source)
                                }
                            }
                        ))
                        .toggleStyle(CheckboxToggleStyle())
                    }
                }
                .padding(.horizontal, 24)
            }
            .padding(.vertical, 16)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.4))
            
            Text("Sélectionnez votre profil et lancez la recherche")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Search Logic
    
    private func performSearch() {
        guard selectedProfile != nil else { return }
        
        isSearching = true
        searchProgress = 0
        jobs = []
        
        Task {
            await performSearchAsync()
        }
    }
    
    @MainActor
    private func performSearchAsync() async {
        let keywords: String
        if let profile = selectedProfile,
           let mostRecentExperience = profile.experiences.sorted(by: { $0.startDate > $1.startDate }).first,
           let position = mostRecentExperience.position, !position.isEmpty {
            keywords = position
        } else {
            keywords = selectedProfile?.name ?? "Emploi"
        }
        
        print("🔍 Starting job search with keywords: \(keywords)")
        
        await jobSearchService.searchJobsWithAI(
            keywords: keywords,
            location: locationText.isEmpty ? nil : locationText,
            maxResults: 50,
            profile: selectedProfile
        ) { [self] searchResults in
            print("✅ Received \(searchResults.count) job results")
            
            let filteredResults = filterResults(searchResults)
            
            DispatchQueue.main.async {
                self.jobs = filteredResults
                self.isSearching = false
                self.searchProgress = 1.0
            }
        }
    }
    
    private func filterResults(_ jobs: [Job]) -> [Job] {
        return jobs.filter { job in
            if let score = job.aiScore, score < minScore {
                return false
            }
            
            if !selectedSources.isEmpty && !selectedSources.contains(job.source) {
                return false
            }
            
            return true
        }
    }
}

// MARK: - Modern Job Card

struct ModernJobCard: View {
    let job: Job
    let profile: Profile?
    let profiles: [Profile]  // Add profiles array for smart profile selection
    @State private var isHovered = false
    @State private var isGenerating = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: "briefcase.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(job.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(job.company)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    Label(job.location, systemImage: "mappin.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(job.source)
                        .font(.system(size: 12))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(4)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 2)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                if let score = job.aiScore {
                    let color: Color = score >= 80 ? .green : .orange
                    
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12))
                        Text("\(score)%")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(color.opacity(0.15))
                    .foregroundColor(color)
                    .cornerRadius(8)
                }
                
                Button(action: {
                    print("🔗 Opening URL: \(job.url)")
                    if let url = URL(string: job.url) {
                        NSWorkspace.shared.open(url)
                    } else {
                        print("❌ Invalid URL: \(job.url)")
                    }
                }) {
                    Image(systemName: "arrow.up.forward.square")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Ouvrir l'annonce")
                
                Button(action: {
                    generateApplicationPackage()
                }) {
                    HStack(spacing: 6) {
                        if isGenerating {
                            ProgressView()
                                .scaleEffect(0.6)
                                .frame(width: 12, height: 12)
                        } else {
                            Text("Postuler")
                                .fontWeight(.semibold)
                            Image(systemName: "folder.badge.plus")
                                .font(.system(size: 12, weight: .bold))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .disabled(isGenerating || profile == nil)
            }
        }
        .padding(16)
        .background(Color.clear)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isHovered ? Color.blue.opacity(0.5) : Color.clear, lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .alert("Application Package", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func generateApplicationPackage() {
        guard let profile = profile else {
            alertMessage = "Aucun profil sélectionné"
            showAlert = true
            return
        }
        
        isGenerating = true
        
        let language = LanguageDetector.detectLanguage(
            title: job.title,
            company: job.company,
            location: job.location
        )
        
        // Select the appropriate profile based on job language
        let selectedProfile = selectProfileForLanguage(language, currentProfile: profile, availableProfiles: profiles)
        
        CoverLetterService.generateCoverLetter(for: job, profile: selectedProfile, language: language) { coverLetter in
            guard let coverLetter = coverLetter else {
                isGenerating = false
                alertMessage = "Échec de la génération de la lettre de motivation"
                showAlert = true
                return
            }
            
            ApplicationPackageService.createApplicationPackage(
                for: job.title,
                company: job.company,
                location: job.location,
                url: job.url,
                profile: selectedProfile,
                coverLetter: coverLetter
            ) { result in
                isGenerating = false
                
                switch result {
                case .success(let folderURL):
                    alertMessage = "Dossier créé avec succès!\n\(folderURL.lastPathComponent)"
                    showAlert = true
                case .failure:
                    alertMessage = "Erreur lors de la création du dossier"
                    showAlert = true
                }
            }
        }
    }
    
    
    /// Select the appropriate profile based on the detected job language
    /// Falls back to current profile if no matching language profile is found
    private func selectProfileForLanguage(_ language: LanguageDetector.Language, currentProfile: Profile, availableProfiles: [Profile]) -> Profile {
        let targetLanguage: String
        switch language {
        case .french:
            targetLanguage = "fr"
        case .english:
            targetLanguage = "en"
        case .dutch:
            // User doesn't speak Dutch, prefer French
            targetLanguage = "fr"
        }
        
        // Try to find a profile with matching language
        if let matchingProfile = availableProfiles.first(where: { $0.language == targetLanguage }) {
            print("📋 [Profile] Selected \(targetLanguage.uppercased()) profile for \(language.rawValue) job")
            return matchingProfile
        }
        
        // Fallback to current profile if no match found
        print("⚠️ [Profile] No matching profile for language \(targetLanguage), using current profile")
        return currentProfile
    }
}

// MARK: - Checkbox Toggle Style

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .foregroundColor(configuration.isOn ? .blue : .gray)
                .onTapGesture {
                    configuration.isOn.toggle()
                }
            
            configuration.label
        }
    }
}

// MARK: - Job Detail View

struct JobDetailView: View {
    let job: Job
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Détails de l'offre")
                    .font(.headline)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(job.title)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(job.company)
                            .font(.title3)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Label(job.location, systemImage: "mappin.circle.fill")
                            if let salary = job.salary, !salary.isEmpty {
                                Label(salary, systemImage: "eurosign.circle.fill")
                            }
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                    
                    if let score = job.aiScore {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.purple)
                                Text("Analyse IA")
                                    .font(.headline)
                            }
                            
                            HStack {
                                Text("Score de compatibilité")
                                Spacer()
                                let color: Color = score >= 80 ? .green : .orange
                                Text("\(score)%")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(color)
                            }
                            
                            if let reason = job.matchReason, !reason.isEmpty {
                                Text(reason)
                                    .font(.body)
                                    .foregroundColor(.primary)
                            }
                            
                            if !job.missingRequirements.isEmpty {
                                Text("Compétences manquantes:")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .padding(.top, 8)
                                
                                ForEach(job.missingRequirements, id: \.self) { requirement in
                                    HStack(alignment: .top) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.orange)
                                            .font(.caption)
                                            .padding(.top, 2)
                                        Text(requirement)
                                            .font(.body)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(12)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            
            HStack(spacing: 16) {
                Button(action: {
                    // TODO: Toggle favorite
                }) {
                    HStack {
                        Image(systemName: "heart")
                        Text("Sauvegarder")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    if let url = URL(string: job.url) {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    HStack {
                        Text("Postuler sur le site")
                        Image(systemName: "arrow.up.right")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 500, height: 600)
    }
}

#Preview {
    JobSearchView()
}