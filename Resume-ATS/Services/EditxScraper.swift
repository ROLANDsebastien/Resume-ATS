import Foundation

class EditxScraper: JobScraperProtocol {
    let sourceName = "Editx"
    let baseURL = "https://editx.eu"
    let sitemapURL = "https://editx.eu/sitemap.xml"
    
    private let session: URLSession
    
    init() {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "en-US,en;q=0.9"
        ]
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }
    
    func search(keywords: String, location: String?) async throws -> [JobResult] {
        var allJobs: [JobResult] = []
        var page = 1
        let maxPages = 3 // Limit pages
        
        // Keep track of visited URLs to avoid duplicates
        var visitedURLs = Set<String>()
        
        while page <= maxPages {
            let searchURL = buildSearchURL(keywords: keywords, page: page)
            print("🔍 Editx: Scraping page \(page)...")
            
            do {
                let data = try await fetchData(from: searchURL)
                
                guard let html = String(data: data, encoding: .utf8) else { break }
                
                let jobURLs = parseJobLinks(html)
                if jobURLs.isEmpty {
                    print("🔍 Editx: No job links found on page \(page). Stopping.")
                    break
                }
                
                // Filter duplicates
                let newURLs = jobURLs.filter { !visitedURLs.contains($0) }
                if newURLs.isEmpty { break }
                newURLs.forEach { visitedURLs.insert($0) }
                
                print("🔍 Editx: Found \(newURLs.count) new job links on page \(page)")
                
                // Fetch details for these URLs in parallel
                await withTaskGroup(of: JobResult?.self) { group in
                    for urlString in newURLs {
                        group.addTask {
                            return await self.fetchJobDetails(urlString: urlString)
                        }
                    }
                    
                    for await job in group {
                        if let job = job {
                            allJobs.append(job)
                        }
                    }
                }
                
                try await Task.sleep(nanoseconds: 500_000_000)
                page += 1
            } catch {
                print("❌ Editx Error on page \(page): \(error)")
                break
            }
        }
        
        return allJobs
    }
    
    private func buildSearchURL(keywords: String, page: Int) -> URL {
        // https://www.editx.eu/en/jobs/?q=devops&page=1
        // Note: I'm assuming 'q' and 'page' parameters based on common practices.
        // If this is incorrect, we might need to adjust.
        // Checking the sitemap URLs, they are under /en/it-jobs/
        // The search page might be /en/jobs/ or /en/search/
        // Let's try /en/jobs/ first.
        
        var components = URLComponents(string: "\(baseURL)/en/jobs/")!
        var queryItems: [URLQueryItem] = []
        
        queryItems.append(URLQueryItem(name: "q", value: keywords))
        if page > 1 {
            queryItems.append(URLQueryItem(name: "page", value: String(page)))
        }
        
        components.queryItems = queryItems
        return components.url!
    }
    
    private func parseJobLinks(_ html: String) -> [String] {
        // Extract links to /it-jobs/
        // href="https://editx.eu/en/it-jobs/..." or href="/en/it-jobs/..."
        let pattern = #"href=["']((?:https:\/\/www\.editx\.eu)?\/en\/it-jobs\/[^"']+)["']"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return [] }
        
        let matches = regex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
        var urls: [String] = []
        
        for match in matches {
            if let range = Range(match.range(at: 1), in: html) {
                let urlPath = String(html[range])
                let fullURL = urlPath.hasPrefix("http") ? urlPath : "\(baseURL)\(urlPath)"
                urls.append(fullURL)
            }
        }
        
        return Array(Set(urls)) // Unique URLs
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
    
    private func fetchData(from url: URL) async throws -> Data {
        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ScrapingError.networkError(NSError(domain: "EditxScraper", code: -1, userInfo: [NSLocalizedDescriptionKey: "HTTP Error"]))
        }
        return data
    }

    private func fetchJobDetails(urlString: String) async -> JobResult? {
        guard let url = URL(string: urlString) else { return nil }
        
        do {
            let data = try await fetchData(from: url)
            guard let html = String(data: data, encoding: .utf8) else { return nil }
            
            return parseJobPage(html, url: urlString)
        } catch {
            print("⚠️ Editx: Failed to fetch details for \(urlString)")
            return nil
        }
    }
    
    private func parseJobPage(_ html: String, url: String) -> JobResult? {
        // Extract Title
        var title = extractMetaContent(html, property: "og:title")
        
        // Fallback to <title> tag if og:title is missing or empty
        if title == nil || title?.isEmpty == true {
            title = extractTitleTag(html)
        }
        
        // Final fallback
        let finalTitle = title?.replacingOccurrences(of: " | Editx", with: "") ?? "Unknown Title"
        
        // Extract Description for Company/Location
        let description = extractMetaContent(html, property: "og:description") ?? ""
        
        // Description format: "Acensi Belgium SRL is looking for test / validation engineer in Brussels with software testing skills."
        // Regex to extract Company and Location
        
        var company = "Editx"
        var location = "Belgium"
        
        // Regex to match: [Company] is looking for [Title] in [Location] with...
        // We use a loose regex to catch "is looking for" and "in"
        let descPattern = #"^(.*?) is looking for .*? in (.*?) (?:with|at)"#
        
        if let regex = try? NSRegularExpression(pattern: descPattern, options: [.caseInsensitive]) {
            let nsDesc = description as NSString
            if let match = regex.firstMatch(in: description, options: [], range: NSRange(location: 0, length: nsDesc.length)) {
                if match.numberOfRanges >= 3 {
                    company = nsDesc.substring(with: match.range(at: 1))
                    location = nsDesc.substring(with: match.range(at: 2))
                }
            }
        }
        
        // Fallback: If regex fails, try to just get the company (text before "is looking for")
        if company == "Editx" && !description.isEmpty {
            let parts = description.components(separatedBy: " is looking for")
            if let first = parts.first, !first.isEmpty {
                company = first
            }
        }
        
        // Clean up
        company = company.trimmingCharacters(in: .whitespacesAndNewlines)
        location = location.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove trailing punctuation from location if present (e.g. "Brussels.")
        if location.hasSuffix(".") {
            location = String(location.dropLast())
        }
        
        return JobResult(
            title: finalTitle.trimmingCharacters(in: .whitespacesAndNewlines),
            company: company,
            location: location,
            salary: nil,
            url: url,
            source: sourceName
        )
    }
    
    private func extractMetaContent(_ html: String, property: String) -> String? {
        // This regex handles:
        // 1. <meta property="og:title" content="..." />
        // 2. <meta content="..." property="og:title" />
        // 3. Whitespace variations
        // 4. property vs name attribute
        
        // Strategy: Find the whole meta tag that contains the property/name, then extract content
        
        let pattern = #"<meta[^>]+(?:property|name)\s*=\s*["']\#(property)["'][^>]*>"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        
        let nsString = html as NSString
        let matches = regex.matches(in: html, options: [], range: NSRange(location: 0, length: nsString.length))
        
        for match in matches {
            let metaTag = nsString.substring(with: match.range)
            
            // Now extract content="..." from this specific tag
            if let content = extractAttribute(from: metaTag, attribute: "content") {
                return content
            }
        }
        
        return nil
    }
    
    private func extractTitleTag(_ html: String) -> String? {
        let pattern = #"<title[^>]*>(.*?)</title>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else { return nil }
        
        let nsString = html as NSString
        if let match = regex.firstMatch(in: html, options: [], range: NSRange(location: 0, length: nsString.length)) {
            return nsString.substring(with: match.range(at: 1))
        }
        return nil
    }
    
    private func extractAttribute(from tag: String, attribute: String) -> String? {
        let pattern = #"content\s*=\s*["']([^"']*)["']"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        
        let nsString = tag as NSString
        if let match = regex.firstMatch(in: tag, options: [], range: NSRange(location: 0, length: nsString.length)) {
            return nsString.substring(with: match.range(at: 1))
        }
        return nil
    }
}