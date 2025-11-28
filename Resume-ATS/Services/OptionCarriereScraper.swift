import Foundation

class OptionCarriereScraper: JobScraperProtocol {
    let sourceName = "OptionCarriere"
    let baseURL = "https://www.optioncarriere.be"
    
    private let session: URLSession
    
    init() {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8",
            "Accept-Language": "fr-BE,fr;q=0.9,en-US;q=0.8,en;q=0.7",
            "Referer": "https://www.optioncarriere.be/",
            "Upgrade-Insecure-Requests": "1"
        ]
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }
    
    func search(keywords: String, location: String?) async throws -> [JobResult] {
        var allJobs: [JobResult] = []
        var page = 1
        let maxPages = 5
        
        while page <= maxPages {
            // Use the search endpoint that redirects (URLSession follows redirects automatically)
            let searchURL = buildSearchURL(keywords: keywords, location: location, page: page)
            print("🔍 OptionCarriere: Scraping page \(page)...")
            
            do {
                let (data, response) = try await session.data(from: searchURL)
                
                // Check for valid response
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 404 {
                    print("⚠️ OptionCarriere: 404 for page \(page)")
                    break
                }
                
                guard let html = String(data: data, encoding: .utf8) else {
                    print("⚠️ OptionCarriere: Failed to decode HTML for page \(page)")
                    break
                }
                
                let jobs = try parseJobResults(html)
                if jobs.isEmpty {
                    print("🔍 OptionCarriere: No more jobs found on page \(page). Stopping.")
                    break
                }
                
                allJobs.append(contentsOf: jobs)
                
                // Polite delay
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5s
                
                page += 1
            } catch {
                print("❌ OptionCarriere Error on page \(page): \(error)")
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
        // Using /recherche/emplois endpoint which handles redirections correctly
        guard var components = URLComponents(string: "\(baseURL)/recherche/emplois") else {
            fatalError("Invalid OptionCarriere base URL")
        }
        
        var queryItems: [URLQueryItem] = []
        queryItems.append(URLQueryItem(name: "s", value: keywords))
        
        if let location = location, !location.isEmpty {
            queryItems.append(URLQueryItem(name: "l", value: location))
        }
        
        // Add pagination parameter
        if page > 1 {
            queryItems.append(URLQueryItem(name: "p", value: String(page)))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            fatalError("Failed to build OptionCarriere search URL")
        }
        
        return url
    }
    
    private func parseJobResults(_ html: String) throws -> [JobResult] {
        var jobs: [JobResult] = []
        
        // Regex to find job articles
        // <article class="job clicky" ...> ... </article>
        let jobPattern = #"(<article[^>]*class=["'][^"']*job clicky[^"']*["'][^>]*>.*?</article>)"#
        
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
        
        print("🔍 OptionCarriere: Found \(jobs.count) jobs")
        return jobs
    }
    
    private func parseJobBlock(_ html: String) -> JobResult? {
        // 1. Extract URL
        let urlPattern = #"data-url=["']([^"']+)["']"#
        let partialUrl = extractMatch(from: html, pattern: urlPattern)
        
        // 2. Extract Title
        // <h2><a href="..." title="Title">Title</a></h2>
        // Or just text inside <a>
        let titlePattern = #"<h2>\s*<a[^>]*>(.*?)</a>"#
        let title = extractMatch(from: html, pattern: titlePattern)?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 3. Extract Company
        // <p class="company"> ... </p>
        let companyPattern = #"<p class=["']company["'][^>]*>(.*?)</p>"#
        var company = extractMatch(from: html, pattern: companyPattern)
        
        // Clean company (remove <a> tags if present)
        if let rawCompany = company {
             company = stripTags(rawCompany).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // 4. Extract Location
        // <ul class="location"><li> ... </li></ul>
        let locationPattern = #"<ul class=["']location["'][^>]*>.*?<li>(.*?)</li>"#
        var location = extractMatch(from: html, pattern: locationPattern)
        
        // Clean location (remove SVG)
        if let rawLocation = location {
            location = stripTags(rawLocation).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Validate
        guard let validTitle = title, !validTitle.isEmpty,
              let validUrl = partialUrl, !validUrl.isEmpty else {
            return nil
        }
        
        let fullURL = validUrl.hasPrefix("http") ? validUrl : "\(baseURL)\(validUrl)"
        
        return JobResult(
            title: validTitle,
            company: company ?? "OptionCarriere",
            location: location ?? "Belgique",
            salary: nil, // Salary is hard to parse reliably here
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
