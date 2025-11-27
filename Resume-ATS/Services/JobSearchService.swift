import Foundation
import SwiftData

// Service principal simplifié
class JobSearchService {
    private let multiScraper: MultiSiteScraper
    
    init() {
        self.multiScraper = MultiSiteScraper()
    }
    
    func searchJobs(keywords: String, location: String? = nil, maxResults: Int = 50, selectedSources: Set<String> = []) async throws -> [JobResult] {
        let results = try await multiScraper.searchAllSites(
            keywords: keywords,
            location: location,
            maxResultsPerSite: maxResults,
            selectedSources: selectedSources
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
    // Generate search keywords based on profile
    private func generateSearchKeywords(from profile: Profile?) -> [String] {
        guard let profile = profile else {
            return ["DevOps", "QA", "IT Support"]
        }
        
        var keywords: Set<String> = []
        
        // 1. Add Job Titles from Experience (most recent first)
        // We prioritize recent roles as they likely reflect current career path
        for experience in profile.experiences.sorted(by: { $0.startDate > $1.startDate }) {
            if let position = experience.position, !position.isEmpty {
                // Clean up position to get core role, but also keep original if it's distinct
                let corePosition = position
                    .replacingOccurrences(of: "(?i)junior", with: "", options: .regularExpression)
                    .replacingOccurrences(of: "(?i)senior", with: "", options: .regularExpression)
                    .replacingOccurrences(of: "(?i)intern", with: "", options: .regularExpression)
                    .replacingOccurrences(of: "(?i)stagiaire", with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                if !corePosition.isEmpty {
                    keywords.insert(corePosition)
                }
                keywords.insert(position)
            }
        }
        
        // 2. Add Top Skills
        // Flatten all skills and take the first few (assuming user ordered them by importance)
        let allSkills = profile.skills.flatMap { $0.skillsArray }
        for skill in allSkills.prefix(8) {
            keywords.insert(skill)
        }
        
        // 3. Add Education Degrees if keywords are sparse
        if keywords.count < 3 {
            for education in profile.educations {
                keywords.insert(education.degree)
            }
        }
        
        // 4. Fallback if still empty
        if keywords.isEmpty {
            return ["DevOps", "QA", "IT Support"]
        }
        
        // 5. Return top unique keywords
        // We limit to 8 to avoid spamming the search APIs too much, but enough to get variety
        return Array(keywords).prefix(8).map { String($0) }
    }
    
    
    func searchJobsWithAI(
        keywords: String, 
        location: String? = nil, 
        maxResults: Int = 50,
        profile: Profile? = nil,
        selectedSources: Set<String> = [],
        completion: @escaping ([Job]) -> Void
    ) async {
        // Generate multiple search keywords based on profile
        let searchKeywords = generateSearchKeywords(from: profile)
        print("🔍 Generated search keywords: \(searchKeywords.joined(separator: ", "))")
        
        var allJobResults: [JobResult] = []
        
        // Search with each keyword
        for keyword in searchKeywords {
            do {
                let results = try await searchJobs(keywords: keyword, location: location, maxResults: maxResults / searchKeywords.count, selectedSources: selectedSources)
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
            // Create a safeguard timeout for the entire batch
            let aiProcessingGroup = DispatchGroup()
            aiProcessingGroup.enter()
            
            var processedJobs: [Job] = []
            var aiFinished = false
            
            // Limit AI analysis to top 5 jobs (safe with sequential processing)
            let jobsToAnalyze = Array(languageFilteredResults.prefix(5))
            let remainingJobs = Array(languageFilteredResults.dropFirst(5))
            
            print("🔍 Analyzing top \(jobsToAnalyze.count) jobs with AI, skipping \(remainingJobs.count) jobs")
            
            AIJobMatchingService.processBatchJobs(jobResults: jobsToAnalyze, profile: profile) { analyzedJobs in
                if !aiFinished {
                    // Convert remaining jobs to Job objects without scores
                    let remainingJobsConverted = remainingJobs.map { jobResult in
                        Job(
                            title: jobResult.title,
                            company: jobResult.company,
                            location: jobResult.location,
                            salary: jobResult.salary,
                            url: jobResult.url,
                            source: jobResult.source,
                            contractType: jobResult.contractType
                        )
                    }
                    
                    // Combine analyzed jobs with remaining jobs
                    processedJobs = analyzedJobs + remainingJobsConverted
                    aiFinished = true
                    aiProcessingGroup.leave()
                }
            }
            
            // Wait for AI with a global timeout (e.g. 30 seconds max for the whole batch to start showing something)
            // Note: This blocks the underlying task, but since we are in an async function called by Task {}, it's okay-ish,
            // but better to use async/await pattern properly. However, processBatchJobs is callback-based.
            // Let's use a simple async delay race.
            
            let timeoutResult = await withCheckedContinuation { continuation in
                DispatchQueue.global().async {
                    // Increase timeout to 180s to accommodate slower models (e.g. Qwen)
                    let result = aiProcessingGroup.wait(timeout: .now() + 180.0)
                    if result == .timedOut {
                        continuation.resume(returning: true) // Timed out
                    } else {
                        continuation.resume(returning: false) // Finished
                    }
                }
            }
            
            if timeoutResult {
                print("⚠️ AI processing timed out globally. Returning raw jobs.")
                // Fallback to raw jobs
                let rawJobs = languageFilteredResults.map { jobResult in
                    Job(
                        title: jobResult.title,
                        company: jobResult.company,
                        location: jobResult.location,
                        salary: jobResult.salary,
                        url: jobResult.url,
                        source: jobResult.source,
                        contractType: jobResult.contractType
                    )
                }
                completion(rawJobs)
            } else {
                completion(processedJobs)
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
                    source: jobResult.source,
                    contractType: jobResult.contractType
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
                