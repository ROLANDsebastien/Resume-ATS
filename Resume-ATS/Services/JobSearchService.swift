import Foundation
import SwiftData

// Service principal simplifié
class JobSearchService {
    private let multiScraper: MultiSiteScraper
    
    init() {
        self.multiScraper = MultiSiteScraper()
    }
    
    func searchJobs(keywords: String, location: String? = nil, maxResults: Int = 50) async throws -> [JobResult] {
        let results = try await multiScraper.searchAllSites(
            keywords: keywords,
            location: location,
            maxResultsPerSite: maxResults
        )
        
        // Fallback to mock data if no results found (for demo/testing purposes)
        if results.isEmpty {
            print("⚠️ No results found from scrapers.")
            // Temporarily disabled mock data to debug scraper
            return []
            // return generateMockJobs(keywords: keywords, location: location)
        }
        
        return results
    }
    
    func checkSitesStatus() async -> [String: Bool] {
        return await multiScraper.checkSitesAvailability()
    }
    
    func getAvailableSources() -> [String] {
        return multiScraper.getScraperNames()
    }
    
    
    // Generate search keywords based on profile
    private func generateSearchKeywords(from profile: Profile?) -> [String] {
        guard let profile = profile else {
            return ["DevOps", "QA", "IT Support"]
        }
        
        var keywords: Set<String> = []
        var hasDevOpsExperience = false
        var hasQAExperience = false
        var hasSupportExperience = false
        
        // Analyze all experiences to build comprehensive keyword set
        for experience in profile.experiences {
            guard let position = experience.position, !position.isEmpty else { continue }
            let positionLower = position.lowercased()
            
            // DevOps related keywords
            if positionLower.contains("devops") || positionLower.contains("cloud") || 
               positionLower.contains("infrastructure") || positionLower.contains("deployment") ||
               positionLower.contains("ci/cd") || positionLower.contains("cicd") ||
               positionLower.contains("kubernetes") || positionLower.contains("docker") ||
               positionLower.contains("aws") || positionLower.contains("azure") {
                hasDevOpsExperience = true
                keywords.insert("DevOps")
                keywords.insert("Cloud Engineer")
                keywords.insert("Infrastructure Engineer")
                keywords.insert("Cloud")
                keywords.insert("AWS")
                keywords.insert("Azure")
            }
            
            // QA / Testing related keywords
            if positionLower.contains("qa") || positionLower.contains("test") || 
               positionLower.contains("quality") || positionLower.contains("testing") ||
               positionLower.contains("assurance") || positionLower.contains("validation") ||
               positionLower.contains("automatisation") || positionLower.contains("automation") {
                hasQAExperience = true
                keywords.insert("QA")
                keywords.insert("Testeur")
                keywords.insert("Tester")
                keywords.insert("Quality Assurance")
                keywords.insert("Testing")
                keywords.insert("Test Analyst")
                keywords.insert("QA Engineer")
                keywords.insert("Test Automation")
                keywords.insert("Automation Engineer")
                keywords.insert("Automatisation")
                keywords.insert("QA Automation")
            }
            
            // IT Support related keywords
            if positionLower.contains("support") || positionLower.contains("help") ||
               positionLower.contains("technician") || positionLower.contains("desktop") ||
               positionLower.contains("service desk") || positionLower.contains("it support") {
                hasSupportExperience = true
                keywords.insert("IT Support")
                keywords.insert("Support Informatique")
                keywords.insert("IT Technician")
                keywords.insert("Helpdesk")
                keywords.insert("Service Desk")
                keywords.insert("Technicien IT")
                keywords.insert("Support Technique")
            }
            
            // General IT keywords
            if positionLower.contains("develop") || positionLower.contains("programmer") || 
               positionLower.contains("software") || positionLower.contains("application") {
                keywords.insert("Developer")
                keywords.insert("Développeur")
            }
            
            if positionLower.contains("admin") || positionLower.contains("system") {
                keywords.insert("System Administrator")
                keywords.insert("Administrateur Système")
                keywords.insert("SysAdmin")
            }
            
            if positionLower.contains("junior") || positionLower.contains("stagiaire") || 
               positionLower.contains("stage") || positionLower.contains("intern") {
                keywords.insert("Junior")
                keywords.insert("Stagiaire")
                keywords.insert("Stage")
                keywords.insert("Intern")
            }
        }
        
        // Add education-based keywords if no experience found
        if keywords.isEmpty && !profile.educations.isEmpty {
            for education in profile.educations {
                let degree = education.degree
        guard !degree.isEmpty else { continue }
                let degreeLower = degree.lowercased()
                
                if degreeLower.contains("support") || degreeLower.contains("informatique") {
                    keywords.insert("IT Support")
                    keywords.insert("Support Informatique")
                    hasSupportExperience = true
                }
                if degreeLower.contains("devops") || degreeLower.contains("cloud") {
                    keywords.insert("DevOps")
                    keywords.insert("Cloud")
                    hasDevOpsExperience = true
                }
            }
        }
        
        // Ensure we have core keywords based on profile
        if hasDevOpsExperience {
            keywords.insert("DevOps")
            keywords.insert("Cloud Engineer")
        }
        if hasQAExperience {
            keywords.insert("QA")
            keywords.insert("Testeur")
        }
        if hasSupportExperience {
            keywords.insert("IT Support")
        }
        
        // Add experience level indicators (junior to 2 years)
        keywords.insert("Junior")
        keywords.insert("Stagiaire")
        keywords.insert("Entry Level")
        keywords.insert("Débutant")
        keywords.insert("0-2 ans")
        keywords.insert("1-2 years")
        keywords.insert("Junior/Intermediate")
        
        // Add general IT keywords if we still don't have enough
        if keywords.isEmpty {
            keywords.insert("DevOps")
            keywords.insert("QA")
            keywords.insert("IT Support")
        }
        
        // Prioritize most relevant keywords for junior profile
        let prioritizedKeywords = Array(keywords).sorted { word1, word2 in
            // Priority order: DevOps > QA > Support > General IT
            let priority1 = getKeywordPriority(word1)
            let priority2 = getKeywordPriority(word2)
            if priority1 != priority2 {
                return priority1 < priority2
            }
            return word1.count < word2.count // Shorter keywords first
        }
        
        // Return top 5-6 keywords for better coverage
        return Array(prioritizedKeywords.prefix(6))
    }
    
    // Helper function to prioritize keywords
    private func getKeywordPriority(_ keyword: String) -> Int {
        let keywordLower = keyword.lowercased()
        
        // Highest priority: Core DevOps and QA terms
        if keywordLower.contains("devops") || keywordLower.contains("cloud engineer") {
            return 1
        }
        if keywordLower.contains("qa") || keywordLower.contains("test") {
            return 2
        }
        
        // High priority: Support and infrastructure
        if keywordLower.contains("support") || keywordLower.contains("infrastructure") {
            return 3
        }
        
        // Medium priority: Specific technologies
        if keywordLower.contains("aws") || keywordLower.contains("azure") || 
           keywordLower.contains("kubernetes") || keywordLower.contains("docker") {
            return 4
        }
        
        // Lower priority: General terms
        if keywordLower.contains("junior") || keywordLower.contains("stagiaire") {
            return 5
        }
        
        return 6 // Default priority
    }
    
    
    func searchJobsWithAI(
        keywords: String, 
        location: String? = nil, 
        maxResults: Int = 50,
        profile: Profile? = nil,
        completion: @escaping ([Job]) -> Void
    ) async {
        // Generate multiple search keywords based on profile
        let searchKeywords = generateSearchKeywords(from: profile)
        print("🔍 Generated search keywords: \(searchKeywords.joined(separator: ", "))")
        
        var allJobResults: [JobResult] = []
        
        // Search with each keyword
        for keyword in searchKeywords {
            do {
                let results = try await searchJobs(keywords: keyword, location: location, maxResults: maxResults / searchKeywords.count)
                allJobResults.append(contentsOf: results)
                print("🔍 Found \(results.count) results for '\(keyword)'")
            } catch {
                print("⚠️ Error searching for '\(keyword)': \(error)")
            }
        }
        
        // Deduplicate results based on URL
        var seenURLs = Set<String>()
        let uniqueResults = allJobResults.filter { jobResult in
            if seenURLs.contains(jobResult.url) {
                return false
            }
            seenURLs.insert(jobResult.url)
            return true
        }
        
        print("📊 Total unique results: \(uniqueResults.count) from \(allJobResults.count) total")
        
        // Filter out Flemish/Dutch jobs (user doesn't speak Dutch)
        let languageFilteredResults = uniqueResults.filter { jobResult in
            let detectedLanguage = LanguageDetector.detectLanguage(
                title: jobResult.title,
                company: jobResult.company,
                location: jobResult.location
            )
            
            // Keep only French and English jobs
            if detectedLanguage == .dutch {
                print("🚫 [Filter] Removed Flemish job: \(jobResult.title)")
                return false
            }
            return true
        }
        
        print("📊 After language filter: \(languageFilteredResults.count) jobs (removed \(uniqueResults.count - languageFilteredResults.count) Flemish jobs)")
        
        // Process with AI if profile is available
        if let profile = profile {
            AIJobMatchingService.processBatchJobs(jobResults: languageFilteredResults, profile: profile) { jobs in
                completion(jobs)
            }
        } else {
            // Convert to Job objects without AI scoring
            let jobs = languageFilteredResults.map { jobResult in
                Job(
                    title: jobResult.title,
                    company: jobResult.company,
                    location: jobResult.location,
                    salary: jobResult.salary,
                    url: jobResult.url,
                    source: jobResult.source
                )
            }
            completion(jobs)
        }
    }
    
    // MARK: - Mock Data
    
    private func generateMockJobs(keywords: String, location: String?) -> [JobResult] {
        let loc = location ?? "Brussels"
        let lowerKeywords = keywords.lowercased()
        
        if lowerKeywords.contains("devops") || lowerKeywords.contains("cloud") || lowerKeywords.contains("admin") {
            return [
                                JobResult(
                                    title: "Junior DevOps Engineer",
                                    company: "CloudNative Belgium",
                                    location: loc,
                                    salary: "€3000 - €4000 / mois",
                                    url: "https://www.linkedin.com/jobs/", // Placeholder
                                    source: "LinkedIn"
                                ),
                                JobResult(
                                    title: "System Administrator / DevOps",
                                    company: "IT Solutions",
                                    location: "Ghent",
                                    salary: "€3500 - €4500 / mois",
                                    url: "https://www.ictjob.be/", // Placeholder
                                    source: "ICTJobs"
                                ),
                                JobResult(
                                    title: "Cloud Infrastructure Intern",
                                    company: "Tech Giants",
                                    location: loc,
                                    salary: "Stage rémunéré",
                                    url: "https://www.stepstone.be/en/job-search/", // Placeholder
                                    source: "StepStone"
                                ),
                                JobResult(
                                    title: "Senior DevOps Architect",
                                    company: "Enterprise Corp",
                                    location: "Antwerp",
                                    salary: "€5500+ / mois",
                                    url: "https://www.indeed.com/", // Placeholder
                                    source: "Indeed"
                                ),
                                JobResult(
                                    title: "IT Support Engineer",
                                    company: "ServiceDesk BE",
                                    location: loc,
                                    salary: "€2800 - €3500 / mois",
                                    url: "https://www.jobat.be/fr/", // Placeholder
                                    source: "Jobat"
                                )
                            ]
                        } else {
                            // Default iOS/Mobile jobs if no specific match
                            return [
                                JobResult(
                                    title: "Senior iOS Developer",
                                    company: "TechCorp Belgium",
                                    location: loc,
                                    salary: "€4000 - €5500 / mois",
                                    url: "https://www.linkedin.com/jobs/", // Placeholder
                                    source: "LinkedIn"
                                ),
                                JobResult(
                                    title: "SwiftUI Engineer",
                                    company: "AppStudio",
                                    location: "Antwerp",
                                    salary: "€3500 - €4500 / mois",
                                    url: "https://www.ictjob.be/", // Placeholder
                                    source: "ICTJobs"
                                ),
                                JobResult(
                                    title: "Mobile Lead (iOS/Android)",
                                    company: "Innovation Lab",
                                    location: loc,
                                    salary: "€5000+ / mois",
                                    url: "https://www.stepstone.be/en/job-search/", // Placeholder
                                    source: "StepStone"
                                ),
                                JobResult(
                                    title: "Junior iOS Developer",
                                    company: "StartUp Inc",
                                    location: "Ghent",
                                    salary: "€2500 - €3000 / mois",
                                    url: "https://www.indeed.com/", // Placeholder
                                    source: "Indeed"
                                ),
                                JobResult(
                                    title: "Product Owner Mobile",
                                    company: "BigBank",
                                    location: loc,
                                    salary: "Compétitif",
                                    url: "https://www.jobat.be/fr/", // Placeholder
                                    source: "Jobat"
                                )
                            ]
                        }
                    }
}
                