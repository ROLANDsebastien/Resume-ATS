import Foundation

protocol JobScraperProtocol {
    var sourceName: String { get }
    var baseURL: String { get }
    
    func search(keywords: String, location: String?) async throws -> [JobResult]
    func isAvailable() async -> Bool
}

enum ScrapingError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case parsingError(String)
    case noResultsFound
    case siteUnavailable
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL invalide"
        case .networkError(let error):
            return "Erreur réseau: \(error.localizedDescription)"
        case .parsingError(let details):
            return "Erreur de parsing: \(details)"
        case .noResultsFound:
            return "Aucun résultat trouvé"
        case .siteUnavailable:
            return "Site temporairement indisponible"
        }
    }
}