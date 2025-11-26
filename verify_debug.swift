import Foundation

// Mock JobResult and JobScraperProtocol
struct JobResult: CustomStringConvertible {
    let title: String
    let company: String
    let location: String
    let salary: String?
    let url: String
    let source: String
    
    var description: String {
        return "Title: \(title), URL: \(url)"
    }
}

class JobatScraper {
    let sourceName = "Jobat"
    let baseURL = "https://www.jobat.be"
    
    func parseJobResults(_ html: String) throws -> [JobResult] {
        var jobs: [JobResult] = []
        
        // Parser avec des expressions régulières simples
        let jobPatterns = [
            #"<div[^>]*class[^>]*["'][^"']*job[^"']*["'][^>]*>.*?</div>"#,
            #"<article[^>]*class[^>]*["'][^"']*job[^"']*["'][^>]*>.*?</article>"#,
            #"<li[^>]*class[^>]*["'][^"']*vacancy[^"']*["'][^>]*>.*?</li>"#,
            #"<div[^>]*class[^>]*jobResults-card[^>]*>.*?</div>"#
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
            #"<h[1-6][^>]*>\s*<a[^>]*>([^<]+)</a>"#,
            #"class=["']jobTitle["'][^>]*>\s*<a[^>]*>([^<]+)</a>"#,
            #"<a[^>]*title\s*=\s*["']([^"']+)["']"#,
            #">([^<]+)</a>"#
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
        let company = extractFirstMatch(html, patterns: companyPatterns) ?? "Unknown Company"
        let location = extractFirstMatch(html, patterns: locationPatterns) ?? "Unknown Location"
        let url = extractFirstMatch(html, patterns: linkPatterns)
        let salary = extractFirstMatch(html, patterns: salaryPatterns)
        
        guard let title = title?.trimmingCharacters(in: .whitespacesAndNewlines),
              let url = url?.trimmingCharacters(in: .whitespacesAndNewlines),
              !title.isEmpty, !url.isEmpty else {
            return nil
        }
        
        let fullURL = url.hasPrefix("http") ? url : "\(baseURL)\(url)"
        
        return JobResult(
            title: title,
            company: company,
            location: location,
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

// Main execution
do {
    let htmlPath = "/Users/rolandsebastien/Developer/Resume-ATS/jobat_debug.html"
    let html = try String(contentsOfFile: htmlPath, encoding: .utf8)
    
    let scraper = JobatScraper()
    let jobs = try scraper.parseJobResults(html)
    
    print("Found \(jobs.count) jobs")
    for (index, job) in jobs.prefix(5).enumerated() {
        print("Job \(index + 1): \(job)")
    }
} catch {
    print("Error: \(error)")
}
