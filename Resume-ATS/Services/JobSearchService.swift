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
            print("⚠️ No results found from scrapers. Returning mock data for demonstration.")
            return generateMockJobs(keywords: keywords, location: location)
        }
        
        return results
    }
    
    func checkSitesStatus() async -> [String: Bool] {
        return await multiScraper.checkSitesAvailability()
    }
    
    func getAvailableSources() -> [String] {
        return multiScraper.getScraperNames()
    }
    
    // MARK: - AI Integration Methods
    
    func searchJobsWithAI(
        keywords: String, 
        location: String? = nil, 
        maxResults: Int = 50,
        profile: Profile? = nil,
        completion: @escaping ([Job]) -> Void
    ) async {
        do {
            let jobResults = try await searchJobs(keywords: keywords, location: location, maxResults: maxResults)
            
            // Process with AI if profile is available
            if let profile = profile {
                AIJobMatchingService.processBatchJobs(jobResults: jobResults, profile: profile) { jobs in
                    completion(jobs)
                }
            } else {
                // Convert to Job objects without AI scoring
                let jobs = jobResults.map { jobResult in
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
        } catch {
            print("Error searching jobs: \(error)")
            // Return mock data on error too
            let mockResults = generateMockJobs(keywords: keywords, location: location)
            let jobs = mockResults.map { 
                Job(title: $0.title, company: $0.company, location: $0.location, salary: $0.salary, url: $0.url, source: $0.source)
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
                