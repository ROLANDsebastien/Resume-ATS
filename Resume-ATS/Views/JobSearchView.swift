import SwiftUI
import SwiftData

struct JobSearchView: View {
    @Binding var selectedSection: String?
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
    
    // Location (City/Region) Selection
    @State private var selectedLocations: Set<CityService.LocationOption> = []
    @State private var locationSuggestions: [CityService.LocationOption] = []
    @State private var showingLocationSuggestions = false
    @State private var isLocationFieldFocused = false
    
    // Contract Filters
    @State private var selectedContractTypes: Set<String> = []
    let contractTypes = ["CDI", "CDD", "Freelance", "Stage", "Intérim"]
    
    // Time Filter
    enum TimeFilter: String, CaseIterable, Identifiable {
        case all = "Tout"
        case last24h = "24 heures"
        case last7days = "7 jours"
        
        var id: String { rawValue }
    }
    @State private var selectedTimeFilter: TimeFilter = .all
    
    var body: some View {
        VStack(spacing: 0) {
            // Header compact
            compactHeaderView
            
            // Liste des résultats
            if jobs.isEmpty && !isSearching {
                emptyStateView
                Spacer()
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
            ToolbarItem(placement: .navigation) {
                Button(action: {
                    selectedSection = "Dashboard"
                }) {
                    Image(systemName: "chevron.left")
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
            // Initialize selectedSources with all available sources
            if selectedSources.isEmpty {
                selectedSources = Set(jobSearchService.getAvailableSources())
            }
        }
    }
    
    // MARK: - Compact Header View
    
    private var compactHeaderView: some View {
        VStack(spacing: 12) {
            // Ligne 1 : Profil, Localisation, Rayon
            HStack(spacing: 12) {
                // Profil Selector
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
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.blue)
                        Text(selectedProfile?.name.isEmpty == false ? selectedProfile!.name : "Choisir un profil")
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                .menuStyle(.borderlessButton)
                .frame(width: 200) // Fixed width for profile
                
                // Location Search
                ZStack(alignment: .topLeading) {
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.green)
                        
                        TextField("Ville, Région...", text: $locationText)
                            .textFieldStyle(.plain)
                            .onChange(of: locationText) { _, newValue in
                                locationSuggestions = CityService.shared.searchLocations(query: newValue)
                                showingLocationSuggestions = !locationSuggestions.isEmpty
                            }
                            .onSubmit {
                                if let firstSuggestion = locationSuggestions.first {
                                    selectedLocations.insert(firstSuggestion)
                                    locationText = ""
                                    showingLocationSuggestions = false
                                    locationSuggestions = []
                                }
                            }
                        
                        if !locationText.isEmpty {
                            Button(action: { locationText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    
                    // Suggestions Overlay
                    if showingLocationSuggestions && !locationSuggestions.isEmpty {
                        VStack(spacing: 0) {
                            ScrollView {
                                LazyVStack(spacing: 0) {
                                    ForEach(locationSuggestions) { location in
                                        Button(action: {
                                            selectedLocations.insert(location)
                                            locationText = ""
                                            showingLocationSuggestions = false
                                            locationSuggestions = []
                                        }) {
                                            HStack {
                                                Image(systemName: location.type == .region ? "location.circle.fill" : "mappin")
                                                    .foregroundColor(location.type == .region ? .blue : .secondary)
                                                Text(location.name)
                                                    .foregroundColor(.primary)
                                                Spacer()
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .contentShape(Rectangle())
                                        }
                                        .buttonStyle(.plain)
                                        //.hoverEffect(.highlight) // Not available on macOS 12/13 depending on target, safe to omit or use onHover
                                        
                                        Divider()
                                    }
                                }
                            }
                            .frame(maxHeight: 200)
                        }
                        .background(.regularMaterial)
                        .cornerRadius(8)
                        .shadow(radius: 4)
                        .offset(y: 40) // Position below the text field
                        .zIndex(100)
                    }
                }
                
                // Selected Locations Chips (Compact)
                if !selectedLocations.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(Array(selectedLocations), id: \.id) { location in
                                HStack(spacing: 2) {
                                    Text(location.name)
                                        .font(.caption)
                                    Button(action: { selectedLocations.remove(location) }) {
                                        Image(systemName: "xmark")
                                            .font(.caption2)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                            }
                        }
                    }
                    .frame(maxWidth: 150)
                }

                // Radius
                Menu {
                    ForEach([10, 25, 50, 75, 100], id: \.self) { distance in
                        Button(action: { distanceKm = distance }) {
                            HStack {
                                Text("\(distance) km")
                                if distanceKm == distance { Image(systemName: "checkmark") }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text("\(distanceKm) km")
                        // Chevron removed as requested
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                .menuStyle(.borderlessButton)
                .frame(width: 80)
            }
            .zIndex(10) // Ensure suggestions appear on top
            
            // Ligne 2 : Filtres (Date, Contrat, Sources) et Bouton Recherche
            HStack(spacing: 12) {
                // Date Filter
                Menu {
                    ForEach(TimeFilter.allCases) { filter in
                        Button(action: { selectedTimeFilter = filter }) {
                            HStack {
                                Text(filter.rawValue)
                                if selectedTimeFilter == filter { Image(systemName: "checkmark") }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.orange)
                        Text(selectedTimeFilter.rawValue)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                .menuStyle(.borderlessButton)
                
                // Contract Filter
                Menu {
                    ForEach(contractTypes, id: \.self) { type in
                        Button(action: {
                            if selectedContractTypes.contains(type) {
                                selectedContractTypes.remove(type)
                            } else {
                                selectedContractTypes.insert(type)
                            }
                        }) {
                            HStack {
                                Text(type)
                                if selectedContractTypes.contains(type) { Image(systemName: "checkmark") }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(.indigo)
                        Text(selectedContractTypes.isEmpty ? "Type de contrat" : "\(selectedContractTypes.count) sélectionné(s)")
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                .menuStyle(.borderlessButton)
                
                // Sources Filter
                Menu {
                    ForEach(jobSearchService.getAvailableSources(), id: \.self) { source in
                        Button(action: {
                            if selectedSources.contains(source) {
                                selectedSources.remove(source)
                            } else {
                                selectedSources.insert(source)
                            }
                        }) {
                            HStack {
                                Text(source)
                                if selectedSources.contains(source) { Image(systemName: "checkmark") }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "globe")
                            .foregroundColor(.cyan)
                        Text(selectedSources.isEmpty ? "Sources" : "\(selectedSources.count) source(s)")
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                .menuStyle(.borderlessButton)
                
                Spacer()
                
                // Search Button
                Button(action: performSearch) {
                    HStack(spacing: 8) {
                        if isSearching {
                            ProgressView()
                                .scaleEffect(0.8)
                                .frame(width: 16, height: 16)
                        } else {
                            Image(systemName: "magnifyingglass")
                        }
                        Text("Rechercher")
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .disabled(selectedProfile == nil || isSearching)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: searchProgress == 1.0 ? "magnifyingglass.circle" : "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.4))
            
            Text(searchProgress == 1.0 ? "Aucun résultat trouvé pour cette recherche." : "Sélectionnez votre profil et lancez la recherche")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
            
            if searchProgress == 1.0 {
                Text("Essayez d'élargir vos critères ou de changer de localisation.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top, 60)
        .frame(maxWidth: .infinity)
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
        print("🔍 Selected sources: \(selectedSources)")
        
        await jobSearchService.searchJobsWithAI(
            keywords: keywords,
            location: locationText.isEmpty ? nil : locationText,
            maxResults: 50,
            profile: selectedProfile,
            selectedSources: selectedSources
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
        print("🔍 Filtering \(jobs.count) jobs with selectedSources: \(selectedSources)")
        let filtered = jobs.filter { job in
            if let score = job.aiScore, score < minScore {
                return false
            }
            
            if !selectedSources.isEmpty && !selectedSources.contains(job.source) {
                print("🚫 Filtering out job from \(job.source): \(job.title)")
                return false
            }
            
            if !selectedSources.isEmpty && !selectedSources.contains(job.source) {
                print("🚫 Filtering out job from \(job.source): \(job.title)")
                return false
            }
            
            if !selectedContractTypes.isEmpty {
                // Si le job n'a pas de type de contrat, on l'affiche quand même si on est indulgent,
                // ou on le masque. Ici, on va supposer que si contractType est nil, ça ne matche pas.
                // Ou alors on peut décider d'afficher les "Inconnu" si l'utilisateur ne filtre pas strictement.
                // Pour l'instant, filtrage strict si le type est connu.
                if let type = job.contractType {
                    // Simple contains check. In real app, might need mapping (e.g. "Full-time" -> "CDI")
                    // Pour l'instant on suppose que le scraping normalise les types.
                    if !selectedContractTypes.contains(where: { type.contains($0) }) {
                        return false
                    }
                }
            }
            
            // Time filter
            switch selectedTimeFilter {
            case .last24h:
                let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
                if job.createdAt < yesterday {
                    return false
                }
            case .last7days:
                let lastWeek = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
                if job.createdAt < lastWeek {
                    return false
                }
            case .all:
                break
            }
            
            return true
        }
        
        // Sort by AI score (highest first) with priority order: green (80+) > orange (50-79) > red (<50)
        return filtered.sorted { job1, job2 in
            let score1 = job1.aiScore ?? 0
            let score2 = job2.aiScore ?? 0
            
            // First sort by score descending
            if score1 != score2 {
                return score1 > score2
            }
            
            // If scores are equal, maintain original order or sort by other criteria
            return job1.createdAt > job2.createdAt // Most recent first if scores equal
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
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(2)
                
                Text(job.company)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
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
    JobSearchView(selectedSection: .constant("JobSearch"))
}