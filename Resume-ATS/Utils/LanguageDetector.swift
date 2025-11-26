import Foundation

/// Detects the language of a job posting based on text analysis
class LanguageDetector {
    
    enum Language: String {
        case french = "fr"
        case dutch = "nl"
        case english = "en"
        
        var coverLetterFileName: String {
            switch self {
            case .french: return "lettre_motivation.txt"
            case .dutch: return "motivatiebrief.txt"
            case .english: return "cover_letter.txt"
            }
        }
        
        var cvFileName: String {
            switch self {
            case .french: return "CV.pdf"
            case .dutch: return "CV.pdf"
            case .english: return "Resume.pdf"
            }
        }
    }
    
    static func detectLanguage(title: String, company: String, location: String) -> Language {
        let text = "\(title) \(company) \(location)".lowercased()
        
        // French indicators
        let frenchKeywords = ["bruxelles", "liège", "namur", "développeur", "ingénieur", 
                             "société", "équipe", "emploi", "wallonie", "h/f", "stage", "stagiaire"]
        let frenchCount = frenchKeywords.filter { text.contains($0) }.count
        
        // Dutch indicators - more specific to avoid false positives
        let dutchKeywords = ["brussel", "antwerpen", "gent", "ontwikkelaar", "ontwikkelaar", 
                            "bedrijf", "vlaanderen", "werken", "medewerker", "m/v", "m/v/x"]
        let dutchCount = dutchKeywords.filter { text.contains($0) }.count
        
        // English indicators - include tech terms that are commonly English
        let englishKeywords = ["developer", "engineer", "company", "team", "brussels", 
                              "devops", "it", "support", "analyst", "coordinator", "specialist",
                              "manager", "lead", "senior", "junior", "backend", "frontend",
                              "full-stack", "aws", "azure", "cloud", "infrastructure", "java",
                              ".net", "dotnet", "web", "erp", "datawarehouse", "bi"]
        let englishCount = englishKeywords.filter { text.contains($0) }.count
        
        // Strong Dutch indicators (override English)
        let strongDutchIndicators = ["medewerker", "m/v", "m/v/x", "vacature", "solliciteer"]
        let hasStrongDutch = strongDutchIndicators.contains { text.contains($0) }
        
        // Strong French indicators (override English)
        let strongFrenchIndicators = ["h/f", "postulez", "candidature"]
        let hasStrongFrench = strongFrenchIndicators.contains { text.contains($0) }
        
        // Determine language with priority rules
        if hasStrongDutch {
            return .dutch
        } else if hasStrongFrench {
            return .french
        } else if englishCount > 0 {
            // Prioritize English for tech positions - this should catch most IT jobs
            return .english
        } else if frenchCount > dutchCount && frenchCount > 0 {
            return .french
        } else if dutchCount > frenchCount && dutchCount > 0 {
            return .dutch
        } else if text.contains("brussels") || text.contains("bruxelles") {
            // Default Brussels jobs to French if no clear indicator
            return .french
        } else {
            // Default to English for international positions
            return .english
        }
    }
}
