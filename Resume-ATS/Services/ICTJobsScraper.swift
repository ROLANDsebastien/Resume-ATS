import Foundation

class ICTJobsScraper: JobScraperProtocol {
    let sourceName = "ICTJobs"
    let baseURL = "https://www.ictjob.be"
    
    private let session: URLSession
    
    init() {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8",
            "Accept-Language": "fr-BE,fr;q=0.9,en-US;q=0.8,en;q=0.7",
            "Referer": "https://www.ictjob.be/",
            "Upgrade-Insecure-Requests": "1"
        ]
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }
    
    func search(keywords: String, location: String?) async throws -> [JobResult] {
        var allJobs: [JobResult] = []
        var page = 1
        let maxPages = 5 // Limit to 5 pages to avoid taking too long
        
        while page <= maxPages {
            let searchURL = buildSearchURL(keywords: keywords, location: location, page: page)
            print("🔍 ICTJobs: Scraping page \(page)...")
            
            do {
                let (data, response) = try await session.data(from: searchURL)
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                    print("⚠️ ICTJobs: Status code \(httpResponse.statusCode) for URL \(searchURL.absoluteString)")
                    break
                }
                
                guard let html = String(data: data, encoding: .utf8) else {
                    print("⚠️ ICTJobs: Failed to decode HTML for page \(page)")
                    break
                }
                
                let jobs = try parseJobResults(html)
                if jobs.isEmpty {
                    print("🔍 ICTJobs: No more jobs found on page \(page). Stopping.")
                    break
                }
                
                allJobs.append(contentsOf: jobs)
                
                // Polite delay between pages
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5s
                
                page += 1
            } catch {
                print("❌ ICTJobs Error on page \(page): \(error)")
                break
            }
        }
        
        return allJobs
    }
    
    func isAvailable() async -> Bool {
        guard let url = URL(string: baseURL) else { return false }
        do {
            let (_, response) = try await session.data(from: url)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }
    
    private func buildSearchURL(keywords: String, location: String?, page: Int) -> URL {
        // https://www.ictjob.be/fr/chercher-emplois-it?keywords=tester&p=1
        guard var components = URLComponents(string: "\(baseURL)/fr/chercher-emplois-it") else {
            fatalError("Invalid ICTJobs base URL")
        }
        
        var queryItems: [URLQueryItem] = []
        queryItems.append(URLQueryItem(name: "keywords", value: keywords))
        
        if let location = location, !location.isEmpty {
            queryItems.append(URLQueryItem(name: "location", value: location))
        }
        
        // Add pagination parameter
        if page > 1 {
            queryItems.append(URLQueryItem(name: "p", value: String(page)))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            fatalError("Failed to build ICTJobs search URL")
        }
        
        return url
    }
    
    private func parseJobResults(_ html: String) throws -> [JobResult] {
        var jobs: [JobResult] = []
        
        // Container: <li class="search-item ..."> ... </li>
        let jobPattern = #"(<li[^>]*class=["'][^"']*search-item[^"']*["'][^>]*>.*?</li>)"#
        
        guard let regex = try? NSRegularExpression(pattern: jobPattern, options: [.dotMatchesLineSeparators, .caseInsensitive]) else {
            return []
        }
        
        let matches = regex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
        
        for match in matches {
            if let range = Range(match.range(at: 1), in: html) {
                let jobHTML = String(html[range])
                if let job = parseJobBlock(jobHTML) {
                    jobs.append(job)
                }
            }
        }
        
        print("🔍 ICTJobs: Found \(jobs.count) jobs")
        return jobs
    }
    
    private func parseJobBlock(_ html: String) -> JobResult? {
        // 1. Extract Title & URL
        // <a itemprop="title" class="job-title search-item-link" href="...">Title</a>
        let titleUrlPattern = #"<a[^>]*class=["'][^"']*job-title[^"']*["'][^>]*href=["']([^"']+)["'][^>]*>(.*?)</a>"#
        
        guard let titleUrlRegex = try? NSRegularExpression(pattern: titleUrlPattern, options: [.dotMatchesLineSeparators, .caseInsensitive]),
              let match = titleUrlRegex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..., in: html)),
              match.numberOfRanges >= 3,
              let urlRange = Range(match.range(at: 1), in: html),
              let titleRange = Range(match.range(at: 2), in: html) else {
            return nil
        }
        
        let partialUrl = String(html[urlRange])
        var title = String(html[titleRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Clean title (sometimes contains <span> or other tags)
        title = stripTags(title)
        
        // Additional cleaning for ICTJobs titles
        title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        // Remove leading/trailing spaces and special characters that might affect alignment
        title = title.replacingOccurrences(of: "^\\s+", with: "", options: .regularExpression)
        title = title.replacingOccurrences(of: "\\s+$", with: "", options: .regularExpression)
        
        // Debug: Print the cleaned title for ICTJobs
        print("🔍 ICTJobs Title: '\(title)' (length: \(title.count))")
        
        // 2. Extract Company
        // Try alt attribute of logo first: <img ... class="search-item-logo ..." alt="Company" />
        // Or text content of hiringOrganization
        var company = "ICTJob"
        
        let companyLogoPattern = #"<img[^>]*class=["'][^"']*search-item-logo[^"']*["'][^>]*alt=["']([^"']+)["']"#
        if let logoMatch = extractMatch(from: html, pattern: companyLogoPattern) {
            company = logoMatch
        } else {
            // Fallback: <span itemprop="hiringOrganization">...</span>
             let companyTextPattern = #"<span[^>]*itemprop=["']hiringOrganization["'][^>]*>(.*?)</span>"#
             if let textMatch = extractMatch(from: html, pattern: companyTextPattern) {
                 company = stripTags(textMatch).trimmingCharacters(in: .whitespacesAndNewlines)
             }
        }
        
        // 3. Extract Location
        // <span itemprop="jobLocation">...</span>
        // Often contains nested spans, so we strip tags
        var location = "Belgique"
        let locationPattern = #"<span[^>]*itemprop=["']jobLocation["'][^>]*>(.*?)</span>"#
        if let locMatch = extractMatch(from: html, pattern: locationPattern) {
            location = stripTags(locMatch).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // 4. Extract Date (Optional but good for debugging)
        // <span itemprop="datePosted">...</span>
        
        // Validate
        guard !title.isEmpty, !partialUrl.isEmpty else { return nil }
        
        let fullURL = partialUrl.hasPrefix("http") ? partialUrl : "\(baseURL)\(partialUrl)"
        
        return JobResult(
            title: title,
            company: company,
            location: location.isEmpty ? "Belgique" : location,
            salary: nil,
            url: fullURL,
            source: sourceName
        )
    }
    
    private func extractMatch(from text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators, .caseInsensitive]) else { return nil }
        
        if let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
           match.numberOfRanges > 1,
           let range = Range(match.range(at: 1), in: text) {
            return String(text[range])
        }
        return nil
    }
    
    private func stripTags(_ html: String) -> String {
        return html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
    }
}
