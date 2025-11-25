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
        let searchURL = buildSearchURL(keywords: keywords, location: location)
        
        do {
            let (data, _) = try await session.data(from: searchURL)
            guard let html = String(data: data, encoding: .utf8) else {
                throw ScrapingError.parsingError("Impossible de décoder le HTML")
            }
            
            return try parseJobResults(html)
        } catch {
            if error is ScrapingError {
                throw error
            }
            throw ScrapingError.networkError(error)
        }
    }
    
    func isAvailable() async -> Bool {
        do {
            let (_, response) = try await session.data(from: URL(string: baseURL)!)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }
    
    private func buildSearchURL(keywords: String, location: String?) -> URL {
        var components = URLComponents(string: "\(baseURL)/fr/jobs/results")!
        var queryItems: [URLQueryItem] = []
        
        queryItems.append(URLQueryItem(name: "k", value: keywords))
        
        if let location = location, !location.isEmpty {
            queryItems.append(URLQueryItem(name: "l", value: location))
        }
        
        components.queryItems = queryItems
        
        return components.url!
    }
    
    private func parseJobResults(_ html: String) throws -> [JobResult] {
        var jobs: [JobResult] = []
        
        // Parser avec des expressions régulières simples
        let jobPatterns = [
            #"<div[^>]*class[^>]*["'][^"']*job[^"']*["'][^>]*>.*?</div>"#,
            #"<article[^>]*class[^>]*["'][^"']*job[^"']*["'][^>]*>.*?</article>"#,
            #"<li[^>]*class[^>]*["'][^"']*vacancy[^"']*["'][^>]*>.*?</li>"#
        ]
        
        for pattern in jobPatterns {
            let regex = try NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
            let matches = regex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
            
            for match in matches {
                if let range = Range(match.range, in: html) {
                    let jobHTML = String(html[range])
                    if let job = parseJobHTML(jobHTML) {
                        jobs.append(job)
                    }
                }
            }
        }
        
        return jobs
    }
    
    private func parseJobHTML(_ html: String) -> JobResult? {
        // Extraire le titre
        let titlePatterns = [
            #"<h[1-6][^>]*>([^<]+)</h[1-6]>"#,
            #"<a[^>]*title\s*=\s*["']([^"']+)["']"#,
            #"class[^>]*title[^>]*>([^<]+)"#
        ]
        
        // Extraire l'entreprise
        let companyPatterns = [
            #"(?:company|entreprise|firm)[^>]*>([^<]+)"#,
            #"class[^>]*company[^>]*>([^<]+)"#,
            #"<span[^>]*itemprop[^>]*hiringOrganization[^>]*>([^<]+)</span>"#
        ]
        
        // Extraire la localisation
        let locationPatterns = [
            #"(?:location|lieu|city|ville)[^>]*>([^<]+)"#,
            #"class[^>]*location[^>]*>([^<]+)"#,
            #"<span[^>]*itemprop[^>]*jobLocation[^>]*>([^<]+)</span>"#
        ]
        
        // Extraire le lien
        let linkPatterns = [
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