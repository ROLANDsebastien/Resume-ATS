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
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
        ]
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }
    
    func search(keywords: String, location: String?) async throws -> [JobResult] {
        print("🔍 Editx: Fetching sitemap for keywords: \(keywords)")
        
        // 1. Fetch Sitemap
        guard let sitemapData = try? await fetchData(from: URL(string: sitemapURL)!),
              let sitemapXML = String(data: sitemapData, encoding: .utf8) else {
            print("❌ Editx: Failed to fetch sitemap")
            return []
        }
        
        // 2. Extract URLs
        let allURLs = extractURLsFromSitemap(sitemapXML)
        print("🔍 Editx: Found \(allURLs.count) URLs in sitemap")
        
        // 3. Filter URLs
        // Must be an IT Job page (contains /it-jobs/)
        // Must not be the search page or main listing
        // Must match keywords (in URL path)
        let jobURLs = allURLs.filter { url in
            url.contains("/it-jobs/") &&
            !url.contains("/it-jobs/search") &&
            !url.hasSuffix("/it-jobs") &&
            urlMatchesKeywords(url, keywords: keywords)
        }
        
        print("🔍 Editx: Found \(jobURLs.count) matching job URLs")
        
        // Limit to top 20 to avoid excessive requests
        let limitedURLs = Array(jobURLs.prefix(20))
        
        var allJobs: [JobResult] = []
        
        // 4. Fetch Details
        await withTaskGroup(of: JobResult?.self) { group in
            for urlString in limitedURLs {
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
    
    // MARK: - Private Helpers
    
    private func fetchData(from url: URL) async throws -> Data {
        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ScrapingError.networkError(NSError(domain: "EditxScraper", code: -1, userInfo: [NSLocalizedDescriptionKey: "HTTP Error"]))
        }
        return data
    }
    
    private func extractURLsFromSitemap(_ xml: String) -> [String] {
        let pattern = #"<loc>(.*?)</loc>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return [] }
        
        let matches = regex.matches(in: xml, options: [], range: NSRange(xml.startIndex..., in: xml))
        return matches.compactMap { match in
            if let range = Range(match.range(at: 1), in: xml) {
                return String(xml[range])
            }
            return nil
        }
    }
    
    private func urlMatchesKeywords(_ url: String, keywords: String) -> Bool {
        let urlLower = url.lowercased()
        let keywordsLower = keywords.lowercased().components(separatedBy: " ")
        
        // Required: ALL keywords must be present in the URL
        for keyword in keywordsLower {
            if !keyword.isEmpty && !urlLower.contains(keyword) {
                return false
            }
        }
        return true
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
        
        // Fallback to <title> tag
        if title == nil || title?.isEmpty == true {
            title = extractTitleTag(html)
        }
        
        // Cleanup title
        let finalTitle = title?.replacingOccurrences(of: " | Editx", with: "")
                             .replacingOccurrences(of: " - Editx", with: "")
                             .trimmingCharacters(in: .whitespacesAndNewlines) ?? "Unknown Title"
        
        // Extract Description for Company/Location
        let description = extractMetaContent(html, property: "og:description") ?? ""
        
        var company = "Editx"
        var location = "Belgium"
        
        // Regex to match: [Company] is looking for [Title/Role] in [Location] with...
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
        
        // Fallback: Try to get company from start of string
        if company == "Editx" && !description.isEmpty {
            let parts = description.components(separatedBy: " is looking for")
            if let first = parts.first, !first.isEmpty {
                company = first
            }
        }
        
        // Clean up
        company = company.trimmingCharacters(in: .whitespacesAndNewlines)
        location = location.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove trailing punctuation from location
        if location.hasSuffix(".") {
            location = String(location.dropLast())
        }
        
        return JobResult(
            title: finalTitle,
            company: company,
            location: location,
            salary: nil,
            url: url,
            source: sourceName
        )
    }
    
    private func extractMetaContent(_ html: String, property: String) -> String? {
        let pattern = #"<meta[^>]+(?:property|name)\s*=\s*["']\#(property)["'][^>]*>"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        
        let nsString = html as NSString
        let matches = regex.matches(in: html, options: [], range: NSRange(location: 0, length: nsString.length))
        
        for match in matches {
            let metaTag = nsString.substring(with: match.range)
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