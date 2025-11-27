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
        // 1. Fetch Sitemap
        print("🔍 Editx: Fetching sitemap...")
        guard let sitemapData = try? await fetchData(from: URL(string: sitemapURL)!) else {
            throw ScrapingError.networkError(NSError(domain: "EditxScraper", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch sitemap"]))
        }
        
        guard let sitemapString = String(data: sitemapData, encoding: .utf8) else {
            throw ScrapingError.parsingError("Failed to decode sitemap")
        }
        
        // 2. Filter URLs from Sitemap
        let jobURLs = parseAndFilterSitemap(sitemapString, keywords: keywords)
        print("🔍 Editx: Found \(jobURLs.count) matching URLs in sitemap")
        
        // 3. Fetch Details for each URL (Limit to top 15 to avoid timeout)
        var results: [JobResult] = []
        
        // Use TaskGroup for concurrent fetching
        await withTaskGroup(of: JobResult?.self) { group in
            for urlString in jobURLs.prefix(15) {
                group.addTask {
                    return await self.fetchJobDetails(urlString: urlString)
                }
            }
            
            for await job in group {
                if let job = job {
                    results.append(job)
                }
            }
        }
        
        return results
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
    
    // MARK: - Private Methods
    
    private func fetchData(from url: URL) async throws -> Data {
        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ScrapingError.networkError(NSError(domain: "EditxScraper", code: -1, userInfo: [NSLocalizedDescriptionKey: "HTTP Error"]))
        }
        return data
    }
    
    private func parseAndFilterSitemap(_ xml: String, keywords: String) -> [String] {
        // Regex to extract <loc> URLs
        // Format: <loc>https://editx.eu/en/it-jobs/...</loc>
        let pattern = #"<loc>(https:\/\/editx\.eu\/en\/it-jobs\/[^<]+)<\/loc>"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return []
        }
        
        let nsString = xml as NSString
        let matches = regex.matches(in: xml, options: [], range: NSRange(location: 0, length: nsString.length))
        
        let keywordTokens = keywords.lowercased().components(separatedBy: " ").filter { !$0.isEmpty }
        
        var matchingURLs: [String] = []
        
        for match in matches {
            if let range = Range(match.range(at: 1), in: xml) {
                let url = String(xml[range])
                let urlLower = url.lowercased()
                
                // Check if URL contains ALL keywords
                let matchesAll = keywordTokens.allSatisfy { token in
                    urlLower.contains(token)
                }
                
                if matchesAll {
                    matchingURLs.append(url)
                }
            }
        }
        
        // Ideally we should sort by <lastmod> if available, but the regex above is simple.
        // Sitemaps are often ordered by date. We'll take the order as is or reverse if needed.
        // Let's assume top of file = older? Actually standard sitemaps often have newest last or first.
        // We'll return as is.
        return matchingURLs
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