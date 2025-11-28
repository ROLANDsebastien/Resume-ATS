import Foundation

class JobatScraper: JobScraperProtocol {
    let sourceName = "Jobat"
    let baseURL = "https://www.jobat.be"
    
    private let session: URLSession
    
    init() {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "fr-BE,fr;q=0.8,en-US;q=0.5,en;q=0.3"
        ]
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }
    
    func search(keywords: String, location: String?) async throws -> [JobResult] {
        var allJobs: [JobResult] = []
        var page = 1
        let maxPages = 10
        
        while page <= maxPages {
            let searchURL = buildSearchURL(keywords: keywords, location: location, page: page)
            print("🔍 [JobatScraper] Searching page \(page): \(searchURL)")
            
            do {
                let (data, response) = try await session.data(from: searchURL)
                
                if let httpResponse = response as? HTTPURLResponse {
                    // print("🔍 [JobatScraper] Status Code: \(httpResponse.statusCode)")
                    if httpResponse.statusCode != 200 {
                        print("⚠️ [JobatScraper] Status code \(httpResponse.statusCode) for page \(page)")
                        break
                    }
                }
                
                guard let html = String(data: data, encoding: .utf8) else {
                    print("❌ [JobatScraper] Failed to decode HTML for page \(page)")
                    break
                }
                
                let jobs = try parseJobResults(html)
                if jobs.isEmpty {
                    print("🔍 [JobatScraper] No more jobs found on page \(page). Stopping.")
                    break
                }
                
                allJobs.append(contentsOf: jobs)
                print("✅ [JobatScraper] Found \(jobs.count) results on page \(page)")
                
                // Polite delay
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5s
                
                page += 1
            } catch {
                print("❌ [JobatScraper] Error on page \(page): \(error)")
                break
            }
        }
        
        return allJobs
    }
    
    func isAvailable() async -> Bool {
        do {
            let (_, response) = try await session.data(from: URL(string: baseURL)!)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }
    
    private func buildSearchURL(keywords: String, location: String?, page: Int) -> URL {
        var components = URLComponents(string: "\(baseURL)/fr/jobs/results")!
        var queryItems: [URLQueryItem] = []
        
        queryItems.append(URLQueryItem(name: "k", value: keywords))
        
        if let location = location, !location.isEmpty {
            queryItems.append(URLQueryItem(name: "l", value: location))
        }
        
        // Add pagination parameter
        if page > 1 {
            queryItems.append(URLQueryItem(name: "p", value: String(page)))
        }
        
        components.queryItems = queryItems
        
        return components.url!
    }
    
    private func parseJobResults(_ html: String) throws -> [JobResult] {
        var jobs: [JobResult] = []
        
        // NEW APPROACH: Extract job IDs first, then extract data for each job
        // Pattern to find all job card IDs: <div id="article_XXXXXX" class="jobResults-card
        let idPattern = #"<div\s+id="article_(\d+)"\s+class="jobResults-card"#
        guard let idRegex = try? NSRegularExpression(pattern: idPattern, options: []) else {
            return []
        }
        
        let idMatches = idRegex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
        print("🔍 [JobatScraper] Found \(idMatches.count) job IDs in HTML")
        
        for idMatch in idMatches {
            guard let idRange = Range(idMatch.range(at: 1), in: html) else { continue }
            let jobId = String(html[idRange])
            
            // Now extract the job data for this specific job ID
            if let job = parseJobById(jobId, from: html) {
                jobs.append(job)
            }
        }
        
        return jobs
    }
    
    private func parseJobById(_ jobId: String, from html: String) -> JobResult? {
        // Find the  section for this specific job - look for data-id and title
        let sectionPattern = #"id="article_\#(jobId)"[^>]*>.*?data-id\s*=\s*["']([^"']+)["'].*?<h2[^>]*>\s*<a[^>]*>([^<]+)</a>"#
        
        guard let regex = try? NSRegularExpression(pattern: sectionPattern, options: [.dotMatchesLineSeparators]),
              let match = regex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..., in: html)) else {
            return nil
        }
        
        guard let urlRange = Range(match.range(at: 1), in: html),
              let titleRange = Range(match.range(at: 2), in: html) else {
            return nil
        }
        
        let url = String(html[urlRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        let title = String(html[titleRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !url.isEmpty, !title.isEmpty else {
            return nil
        }
        
        let fullURL = url.hasPrefix("http") ? url : "\(baseURL)\(url)"
        
        // Try to extract company from the HTML content
        let companyPatterns = [
            #"class=["']jobCard-company["'][^>]*>\s*<a[^>]*>([^<]+)</a>"#,
            #"<li[^>]*class=["']jobCard-company["'][^>]*>\s*<a[^>]*>([^<]+)</a>"#,
            #"class=["']jobCard-company["'][^>]*>([^<]+)"#,
            #"<li[^>]*class=["']jobCard-company["'][^>]*>([^<]+)"#
        ]
        
        let company = extractFirstMatch(html, patterns: companyPatterns)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Company"
        
        return JobResult(
            title: title,
            company: company,
            location: "Brussels", // Already filtered by location in search
            salary: nil,
            url: fullURL,
            source: sourceName
        )
    }
    
    private func parseJobHTML(_ html: String) -> JobResult? {
        // Extraire le titre
        let titlePatterns = [
            #"<h[1-6][^>]*>\s*<a[^>]*>([^<]+)</a>"#,
            #"class=["']jobTitle["'][^>]*>\s*<a[^>]*>([^<]+)</a>"#,
            #"<a[^>]*title\s*=\s*["']([^"']+)["']"#,
            #">([^<]+)</a>"#
        ]
        
        // Extraire l'entreprise
        let companyPatterns = [
            #"class=["']jobCard-company["'][^>]*>\s*<a[^>]*>([^<]+)</a>"#,
            #"<li[^>]*class=["']jobCard-company["'][^>]*>\s*<a[^>]*>([^<]+)</a>"#,
            #"class=["']jobCard-company["'][^>]*>([^<]+)"#,
            #"<li[^>]*class=["']jobCard-company["'][^>]*>([^<]+)"#
        ]
        
        // Extraire la localisation
        let locationPatterns = [
            #"(?:location|lieu|city|ville)[^>]*>([^<]+)"#,
            #"class[^>]*location[^>]*>([^<]+)"#,
            #"<span[^>]*itemprop[^>]*jobLocation[^>]*>([^<]+)</span>"#
        ]
        
        // Extraire le lien
        let linkPatterns = [
            #"data-id\s*=\s*["']([^"']+)["']"#,
            #"<a[^>]*href\s*=\s*["']([^"']+)["'][^>]*onclick"#,
            #"<a[^>]*href\s*=\s*["']([^"']+)["'][^>]*title[^>]*>"#,
            #"<a[^>]*class[^>]*["'][^"']*job[^"']*["'][^>]*href\s*=\s*["']([^"']+)["']"#
        ]
        
        // Extraire le salaire
        let salaryPatterns = [
            #"(?:salary|salaire|rémunération)[^>]*>([^<]+)"#,
            #"class[^>]*salary[^>]*>([^<]+)"#,
            #"<span[^>]*itemprop[^>]*baseSalary[^>]*>([^<]+)</span>"#
        ]
        
        let title = extractFirstMatch(html, patterns: titlePatterns)
        let company = extractFirstMatch(html, patterns: companyPatterns)
        let location = extractFirstMatch(html, patterns: locationPatterns)
        let url = extractFirstMatch(html, patterns: linkPatterns)
        let salary = extractFirstMatch(html, patterns: salaryPatterns)
        
        guard let title = title?.trimmingCharacters(in: .whitespacesAndNewlines),
              let company = company?.trimmingCharacters(in: .whitespacesAndNewlines),
              let url = url?.trimmingCharacters(in: .whitespacesAndNewlines),
              !title.isEmpty, !company.isEmpty, !url.isEmpty else {
            return nil
        }
        
        let fullURL = url.hasPrefix("http") ? url : "\(baseURL)\(url)"
        
        return JobResult(
            title: title,
            company: company,
            location: location?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            salary: salary?.trimmingCharacters(in: .whitespacesAndNewlines),
            url: fullURL,
            source: sourceName
        )
    }
    
    private func extractFirstMatch(_ text: String, patterns: [String]) -> String? {
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
                  let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
                  let range = Range(match.range(at: 1), in: text) else {
                continue
            }
            return String(text[range])
        }
        return nil
    }
}