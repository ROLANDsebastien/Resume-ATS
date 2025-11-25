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
    
    static func detectLanguage(from job: Job) -> Language {
        let text = "\(job.title) \(job.company) \(job.location)".lowercased()
        
        // French indicators
        let frenchKeywords = ["bruxelles", "liège", "namur", "développeur", "ingénieur", 
                             "société", "équipe", "emploi", "wallonie"]
        let frenchCount = frenchKeywords.filter { text.contains($0) }.count
        
        // Dutch indicators
        let dutchKeywords = ["brussel", "antwerpen", "gent", "ontwikkelaar", 
                            "bedrijf", "vlaanderen", "werken"]
        let dutchCount = dutchKeywords.filter { text.contains($0) }.count
        
        // English indicators (or neutral Belgian cities)
        let englishKeywords = ["developer", "engineer", "company", "team", "brussels"]
        _ = englishKeywords.filter { text.contains($0) }.count
        
        // Determine language based on keyword matches
        if frenchCount > dutchCount && frenchCount > 0 {
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
