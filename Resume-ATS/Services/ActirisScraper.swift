import Foundation

class ActirisScraper: JobScraperProtocol {
    let sourceName = "Actiris"
    let baseURL = "https://www.actiris.brussels"
    let sitemapURL = "https://www.actiris.brussels/sitemapoffers-fr.xml"
    
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
        print("🔍 Actiris: Fetching sitemap...")
        
        // 1. Fetch Sitemap
        guard let sitemapData = try? await fetchData(from: URL(string: sitemapURL)!),
              let sitemapXML = String(data: sitemapData, encoding: .utf8) else {
            print("❌ Actiris: Failed to fetch sitemap")
            return []
        }
        
        // 2. Extract and Sort URLs by Date
        let allEntries = extractEntriesFromSitemap(sitemapXML)
        print("🔍 Actiris: Found \(allEntries.count) entries in sitemap")
        
        // Sort by date (newest first)
        let sortedEntries = allEntries.sorted { $0.date > $1.date }
        
        // 3. Select candidates (Top 200 newest)
        // Increased from 50 to 200 to better catch IT jobs in a high-volume general feed.
        let candidates = Array(sortedEntries.prefix(200))
        
        print("🔍 Actiris: Checking top \(candidates.count) most recent jobs for keywords: '\(keywords)'")
        
        var allJobs: [JobResult] = []
        
        // 4. Fetch Details & Filter
        await withTaskGroup(of: JobResult?.self) { group in
            for entry in candidates {
                group.addTask {
                    return await self.fetchJobDetails(urlString: entry.url, keywords: keywords, locationFilter: location)
                }
            }
            
            for await job in group {
                if let job = job {
                    allJobs.append(job)
                }
            }
        }
        
        print("✅ Actiris: Found \(allJobs.count) matching jobs")
        return allJobs
    }
    
    func isAvailable() async -> Bool {
        // Check if sitemap is reachable
        guard let url = URL(string: sitemapURL) else { return false }
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        
        do {
            let (_, response) = try await session.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }
    
    // MARK: - Private Types & Helpers
    
    private struct SitemapEntry {
        let url: String
        let date: Date
    }
    
    private func fetchData(from url: URL, useRange: Bool = false) async throws -> Data {
        var request = URLRequest(url: url)
        if useRange {
            // Fetch only first 30KB (header is usually at the top)
            request.setValue("bytes=0-30000", forHTTPHeaderField: "Range")
        }
        
        let (data, response) = try await session.data(for: request)
        
        // Handle 206 Partial Content or 200 OK
        guard let httpResponse = response as? HTTPURLResponse, 
              (httpResponse.statusCode == 200 || httpResponse.statusCode == 206) else {
            throw ScrapingError.networkError(NSError(domain: "ActirisScraper", code: -1, userInfo: [NSLocalizedDescriptionKey: "HTTP Error"]))
        }
        return data
    }
    
    private func extractEntriesFromSitemap(_ xml: String) -> [SitemapEntry] {
        // Simple Regex to find <url><loc>...</loc><lastmod>...</lastmod></url>
        var entries: [SitemapEntry] = []
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd" // Standard Sitemap format
        
        let pattern = #"(?s)<url>\s*<loc>(.*?)</loc>\s*<lastmod>(.*?)</lastmod>\s*</url>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return [] }
        
        let nsString = xml as NSString
        let matches = regex.matches(in: xml, options: [], range: NSRange(xml.startIndex..., in: xml))
        
        for match in matches {
            if match.numberOfRanges >= 3 {
                let url = nsString.substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines)
                let dateString = nsString.substring(with: match.range(at: 2)).trimmingCharacters(in: .whitespacesAndNewlines)
                
                if let date = dateFormatter.date(from: dateString) {
                    entries.append(SitemapEntry(url: url, date: date))
                }
            }
        }
        
        return entries
    }

    private func fetchJobDetails(urlString: String, keywords: String, locationFilter: String?) async -> JobResult? {
        guard let url = URL(string: urlString) else { return nil }
        
        do {
            // Use Range request to fetch only the head
            let data = try await fetchData(from: url, useRange: true)
            guard let html = String(data: data, encoding: .utf8) else { return nil }
            
            // Parse Page
            guard let job = parseJobPage(html, url: urlString) else { return nil }
            
            // Filter by Keywords
            if !matchesKeywords(job, keywords: keywords) {
                return nil
            }
            
            // Filter by Location (optional)
            if let filterLoc = locationFilter, !filterLoc.isEmpty {
                if !job.location.lowercased().contains(filterLoc.lowercased()) {
                    return nil
                }
            }
            
            return job
        } catch {
            // print("⚠️ Actiris: Failed to fetch details for \(urlString)")
            return nil
        }
    }
    
    private func matchesKeywords(_ job: JobResult, keywords: String) -> Bool {
        let content = "\(job.title) \(job.company) \(job.location)".lowercased()
        let keywordList = keywords.lowercased().components(separatedBy: " ")
        
        for keyword in keywordList {
            if !keyword.isEmpty && !content.contains(keyword) {
                return false
            }
        }
        return true
    }
    
    private func parseJobPage(_ html: String, url: String) -> JobResult? {
        // Extract Title
        var title = extractMetaContent(html, property: "og:title")
        
        // Cleanup title (Remove " - Ref. 123456 | Actiris")
        if let t = title {
            // Regex to remove reference suffix
            let titlePattern = #"(.*?) - Ref\."#
            if let regex = try? NSRegularExpression(pattern: titlePattern, options: []) {
                 let nsString = t as NSString
                 if let match = regex.firstMatch(in: t, options: [], range: NSRange(location: 0, length: nsString.length)) {
                     title = nsString.substring(with: match.range(at: 1))
                 }
            }
        }
        
        // Extract Description for Company/Location
        let description = extractMetaContent(html, property: "og:description") ?? ""
        
        // Actiris Description Format often looks like:
        // "Title - Ref 12345 - Belgique - Saint-Vith - Temps plein"
        // It doesn't always strictly list the company in the og:description.
        // Let's try to find the company in the body or generic fallback.
        
        var company = "Actiris / Employer"
        var location = "Bruxelles"
        
        // Parse Location from description " - Belgique - LOCATION - "
        let parts = description.components(separatedBy: " - ")
        if parts.count >= 4 {
            // parts[0] = Title
            // parts[1] = Ref
            // parts[2] = Country (Belgique)
            // parts[3] = Location (Saint-Vith)
            location = parts[3]
        } else if parts.count >= 3 {
            location = parts[2]
        }
        
        return JobResult(
            title: title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Unknown Title",
            company: company,
            location: location.trimmingCharacters(in: .whitespacesAndNewlines),
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
