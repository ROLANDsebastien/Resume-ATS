#!/usr/bin/env swift

import Foundation

// Test simple et rapide
print("🧪 Test de connectivité des sites d'emploi")

let sites = [
    ("Jobat", "https://www.jobat.be"),
    ("Actiris", "https://www.actiris.brussels"),
    ("OptionCarriere", "https://www.optioncariere.be"),
    ("ICTJobs", "https://www.ictjobs.be"),
    ("Editx", "https://www.editxjobs.be")
]

func testSite(name: String, url: String) async -> (String, Bool, Double) {
    let startTime = Date()
    
    guard let siteURL = URL(string: url) else {
        return (name, false, 0)
    }
    
    do {
        var request = URLRequest(url: siteURL)
        request.timeoutInterval = 5
        request.httpMethod = "HEAD"
        
        let (_, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        let duration = Date().timeIntervalSince(startTime)
        
        return (name, (200...299).contains(statusCode), duration)
    } catch {
        let duration = Date().timeIntervalSince(startTime)
        return (name, false, duration)
    }
}

let semaphore = DispatchSemaphore(value: 0)

Task {
    let results = await withTaskGroup(of: (String, Bool, Double).self) { group in
        var results: [(String, Bool, Double)] = []
        
        for (name, url) in sites {
            group.addTask {
                await testSite(name: name, url: url)
            }
        }
        
        for await result in group {
            results.append(result)
        }
        
        return results.sorted { $0.0 < $1.0 }
    }
    
    print("\n" + String(repeating: "=", count: 50))
    
    for (name, isAvailable, duration) in results {
        let status = isAvailable ? "✅" : "❌"
        let statusText = isAvailable ? "Disponible" : "Indisponible"
        print("\(status) \(name): \(statusText) (\(String(format: "%.2f", duration))s)")
    }
    
    let availableCount = results.filter { $0.1 }.count
    print("\n📊 Résumé: \(availableCount)/\(sites.count) sites disponibles")
    
    semaphore.signal()
}

semaphore.wait()
print("\n🏁 Test terminé")