import Foundation

// Test simple pour vérifier les scrapers
class SimpleScraperTest {
    
    func testQuickAvailability() async {
        print("🧪 Test rapide de disponibilité des sites")
        print("=" * 40)
        
        let scrapers = [
            ("Jobat", "https://www.jobat.be"),
            ("Actiris", "https://www.actiris.brussels"),
            ("OptionCarriere", "https://www.optioncarriere.be"),
            ("ICTJobs", "https://www.ictjobs.be"),
            ("Editx", "https://www.editxjobs.be")
        ]
        
        for (name, url) in scrapers {
            let startTime = Date()
            var isAvailable = false
            
            if let siteURL = URL(string: url) {
                do {
                    var request = URLRequest(url: siteURL)
                    request.timeoutInterval = 5
                    request.httpMethod = "HEAD"
                    
                    let (_, response) = try await URLSession.shared.data(for: request)
                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                    isAvailable = (200...299).contains(statusCode)
                } catch {
                    isAvailable = false
                }
            }
            
            let duration = Date().timeIntervalSince(startTime)
            let status = isAvailable ? "✅" : "❌"
            print("\(status) \(name): \(isAvailable ? "Disponible" : "Indisponible") (\(String(format: "%.2f", duration))s)")
        }
        
        print("\n🏁 Test terminé")
    }
}

// Extension pour les strings
extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}

// Lancer le test
// let tester = SimpleScraperTest()
// Task {
//     await tester.testQuickAvailability()
// }