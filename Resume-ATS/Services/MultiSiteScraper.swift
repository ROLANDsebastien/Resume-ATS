import Foundation

class MultiSiteScraper {
    private let scrapers: [JobScraperProtocol]
    private let session: URLSession
    
    init() {
        self.scrapers = [
            JobatScraper()
            // Scrapers temporairement désactivés en raison d'erreurs réseau/parsing
            // Réactiver après correction individuelle de chaque scraper
            // ActirisScraper(),           // ❌ Parsing error - structure HTML changée
            // OptionCarriereScraper(),    // ❌ Parsing error - structure HTML changée
            // ICTJobsScraper(),           // ❌ TLS error - protection anti-bot
            // EditxScraper()              // ❌ DNS error - domaine inexistant
        ]
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }
    
    func searchAllSites(
        keywords: String,
        location: String? = nil,
        maxResultsPerSite: Int = 20
    ) async throws -> [JobResult] {
        var allResults: [JobResult] = []
        
        // Exécuter tous les scrapers en parallèle
        try await withThrowingTaskGroup(of: [JobResult].self) { group in
            for scraper in scrapers {
                let sourceName = scraper.sourceName
                group.addTask {
                    do {
                        let results = try await scraper.search(keywords: keywords, location: location)
                        return Array(results.prefix(maxResultsPerSite))
                    } catch {
                        print("Erreur avec \(sourceName): \(error.localizedDescription)")
                        return [] // Retourner tableau vide en cas d'erreur
                    }
                }
            }
            
            // Collecter tous les résultats
            for try await results in group {
                allResults.append(contentsOf: results)
            }
        }
        
        // Dédupliquer les résultats
        let deduplicatedResults = deduplicateJobs(allResults)
        
        // Trier par pertinence (ici par date de scraping)
        let sortedResults = deduplicatedResults.sorted { $0.scrapedAt > $1.scrapedAt }
        
        return sortedResults
    }
    
    func checkSitesAvailability() async -> [String: Bool] {
        var availability: [String: Bool] = [:]
        
        await withTaskGroup(of: (String, Bool).self) { group in
            for scraper in scrapers {
                let sourceName = scraper.sourceName
                group.addTask {
                    let isAvailable = await scraper.isAvailable()
                    return (sourceName, isAvailable)
                }
            }
            
            for await (sourceName, isAvailable) in group {
                availability[sourceName] = isAvailable
            }
        }
        
        return availability
    }
    
    private func deduplicateJobs(_ jobs: [JobResult]) -> [JobResult] {
        var uniqueJobs: [JobResult] = []
        var seenJobs: Set<String> = []
        
        for job in jobs {
            let signature = createJobSignature(job)
            
            if !seenJobs.contains(signature) {
                seenJobs.insert(signature)
                uniqueJobs.append(job)
            }
        }
        
        return uniqueJobs
    }
    
    private func createJobSignature(_ job: JobResult) -> String {
        // Créer une signature unique basée sur titre + entreprise + localisation
        let normalizedTitle = job.title.lowercased()
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        let normalizedCompany = job.company.lowercased()
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        let normalizedLocation = job.location.lowercased()
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return "\(normalizedTitle)-\(normalizedCompany)-\(normalizedLocation)"
    }
    
    func getScraperNames() -> [String] {
        return scrapers.map { $0.sourceName }
    }
}