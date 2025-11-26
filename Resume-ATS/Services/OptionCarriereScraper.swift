import Foundation

class OptionCarriereScraper: JobScraperProtocol {
    let sourceName = "OptionCarriere"
    let baseURL = "https://www.optioncarriere.be"
    
    private let session: URLSession
    
    init() {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
            "Accept-Language": "fr-BE,fr;q=0.9,en-US;q=0.8,en;q=0.7",
            "Upgrade-Insecure-Requests": "1",
            "Sec-Fetch-Site": "none",
            "Sec-Fetch-Mode": "navigate",
            "Sec-Fetch-User": "?1",
            "Sec-Fetch-Dest": "document"
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
        guard let url = URL(string: baseURL) else {
            return false
        }
        
        do {
            let (_, response) = try await session.data(from: url)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }
    
    private func buildSearchURL(keywords: String, location: String?) -> URL {
        guard var components = URLComponents(string: "\(baseURL)/emploi") else {
            fatalError("Invalid OptionCarriere base URL: \(baseURL)")
        }
        
        var queryItems: [URLQueryItem] = []
        queryItems.append(URLQueryItem(name: "s", value: keywords))
        
        if let location = location, !location.isEmpty {
            queryItems.append(URLQueryItem(name: "l", value: location))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            fatalError("Failed to build OptionCarriere search URL")
        }
        
        return url
    }
    
    private func parseJobResults(_ html: String) throws -> [JobResult] {
        var jobs: [JobResult] = []
        
        // OptionCarriere utilise souvent des données JSON dans des scripts
        jobs.append(contentsOf: try parseFromJSONScripts(html))
        
        // Fallback sur parsing HTML
        jobs.append(contentsOf: try parseFromHTML(html))
        
        return jobs
    }
    
    private func parseFromJSONScripts(_ html: String) throws -> [JobResult] {
        var jobs: [JobResult] = []
        
        // Patterns pour trouver les données JSON (patterns améliorés)
        let jsonPatterns = [
            #"window\.__INITIAL_STATE__\s*=\s*(\{[^}]*\});"#,
            #"window\.__INITIAL_STATE__\s*=\s*(\{[^}]*\})\s*$"#,
            #"window\.jobData\s*=\s*(\{[^}]*\});"#,
            #"window\.JOBS\s*=\s*(\{[^}]*\});"#,
            #"window\.APP_STATE\s*=\s*(\{[^}]*\});"#,
            #"<script[^>]*type\s*=\s*["']application/json["'][^>]*>(.*?)</script>"#,
            #"<script[^>]*type\s*=\s*["']application/ld\+json["'][^>]*>(.*?)</script>"#,
            #"data-job-list\s*=\s*["']([^"']*)["']"#,
            #"data-jobs\s*=\s*["']([^"']*)["']"#
        ]
        
        for pattern in jsonPatterns {
            let regex = try NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
            let matches = regex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
            
            for match in matches {
                if let range = Range(match.range, in: html) {
                    let jsonString = String(html[range])
                    jobs.append(contentsOf: try parseJSONJobs(jsonString))
                }
            }
        }
        
        return jobs
    }
    
    private func parseFromHTML(_ html: String) throws -> [JobResult] {
        var jobs: [JobResult] = []
        
        // Patterns pour les structures HTML communes
        let jobPatterns = [
            #"<div[^>]*class[^>]*["'][^"']*job[^"']*["'][^>]*>.*?</div>"#,
            #"<article[^>]*class[^>]*["'][^"']*job[^"']*["'][^>]*>.*?</article>"#,
            #"<li[^>]*class[^>]*["'][^"']*job[^"']*["'][^>]*>.*?</li>"#
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
    
    private func parseJSONJobs(_ jsonString: String) throws -> [JobResult] {
        var jobs: [JobResult] = []
        
        // Nettoyer la chaîne JSON
        let cleanedJSON = cleanJSONString(jsonString)
        
        guard let data = cleanedJSON.data(using: .utf8) else {
            return jobs
        }
        
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            
            if let dict = json as? [String: Any] {
                jobs.append(contentsOf: extractJobsFromDict(dict))
            } else if let array = json as? [[String: Any]] {
                jobs.append(contentsOf: extractJobsFromArray(array))
            }
        } catch {
            // Ignorer les erreurs de parsing JSON
        }
        
        return jobs
    }
    
    private func extractJobsFromDict(_ dict: [String: Any]) -> [JobResult] {
        var jobs: [JobResult] = []
        
        // Chercher dans les clés communes
        let possibleKeys = ["jobs", "offers", "results", "data", "items", "listings", "vacancies"]
        
        for key in possibleKeys {
            if let value = dict[key] {
                if let jobArray = value as? [[String: Any]] {
                    jobs.append(contentsOf: extractJobsFromArray(jobArray))
                }
            }
        }
        
        return jobs
    }
    
    private func extractJobsFromArray(_ array: [[String: Any]]) -> [JobResult] {
        var jobs: [JobResult] = []
        
        for jobDict in array {
            if let job = createJobFromDict(jobDict) {
                jobs.append(job)
            }
        }
        
        return jobs
    }
    
    private func createJobFromDict(_ dict: [String: Any]) -> JobResult? {
        let title = dict["title"] as? String ?? 
                   dict["job_title"] as? String ??
                   dict["position"] as? String ?? ""
        
        let company = dict["company"] as? String ??
                     dict["employer"] as? String ??
                     dict["organization"] as? String ?? ""
        
        let location = dict["location"] as? String ??
                       dict["city"] as? String ??
                       dict["address"] as? String ?? ""
        
        let url = dict["url"] as? String ??
                  dict["link"] as? String ??
                  dict["apply_url"] as? String ?? ""
        
        let salary = dict["salary"] as? String ??
                    dict["remuneration"] as? String ??
                    dict["wage"] as? String
        
        guard !title.isEmpty && !company.isEmpty && !url.isEmpty else {
            return nil
        }
        
        return JobResult(
            title: title,
            company: company,
            location: location,
            salary: salary,
            url: url,
            source: sourceName
        )
    }
    
    private func cleanJSONString(_ string: String) -> String {
        var cleaned = string
        
        // Enlever les assignations JavaScript - patterns simplifiés
        cleaned = cleaned.replacingOccurrences(of: "window.__INITIAL_STATE__", with: "", options: .caseInsensitive)
        cleaned = cleaned.replacingOccurrences(of: "window.jobList", with: "", options: .caseInsensitive)
        cleaned = cleaned.replacingOccurrences(of: "data-jobs=", with: "", options: .caseInsensitive)
        cleaned = cleaned.replacingOccurrences(of: ";", with: "")
        cleaned = cleaned.replacingOccurrences(of: "$", with: "")
        
        return cleaned
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