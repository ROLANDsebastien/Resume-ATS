import Foundation

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
            return ["Developer", "IT", "Engineer"]
        }
        
        var keywords: Set<String> = []
        
        // Start with the most recent position if available
        if let mostRecentExperience = profile.experiences.sorted(by: { $0.startDate > $1.startDate }).first,
           let position = mostRecentExperience.position, !position.isEmpty {
            // Extract key terms from position
            let positionLower = position.lowercased()
            
            if positionLower.contains("devops") {
                keywords.insert("DevOps")
            }
            if positionLower.contains("qa") || positionLower.contains("test") || positionLower.contains("quality") {
                keywords.insert("QA")
                keywords.insert("Testeur")
            }
            if positionLower.contains("support") || positionLower.contains("help") {
                keywords.insert("IT Support")
            }
            if positionLower.contains("develop") || positionLower.contains("programmer") {
                keywords.insert("Developer")
            }
            if positionLower.contains("admin") {
                keywords.insert("System Administrator")
            }
        }
        
        // Add generic fallbacks if we don't have enough keywords
        if keywords.isEmpty {
            keywords.insert("Developer")
            keywords.insert("IT")
            keywords.insert("Engineer")
        } else if keywords.count < 3 {
            // Add broader related terms
            keywords.insert("IT")
            keywords.insert("Engineer")
        }
        
        // Limit to top 3 keywords to avoid too many queries
        return Array(keywords.prefix(3))
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
        
        // Process with AI if profile is available
        if let profile = profile {
            AIJobMatchingService.processBatchJobs(jobResults: uniqueResults, profile: profile) { jobs in
                completion(jobs)
            }
        } else {
            // Convert to Job objects without AI scoring
            let jobs = uniqueResults.map { jobResult in
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
                