import Foundation

class CityService {
    static let shared = CityService()
    
    struct LocationOption: Identifiable, Hashable {
        let id = UUID()
        let name: String
        let type: LocationType
        let alternativeName: String? // For bilingual cities
        
        enum LocationType {
            case region
            case city
        }
    }
    
    // Régions belges
    private let regions: [LocationOption] = [
        LocationOption(name: "Région de Bruxelles-Capitale", type: .region, alternativeName: "Brussels Hoofdstedelijk Gewest"),
        LocationOption(name: "Région Flamande", type: .region, alternativeName: "Vlaams Gewest"),
        LocationOption(name: "Région Wallonne", type: .region, alternativeName: "Waals Gewest")
    ]
    
    // Liste des principales villes belges (avec noms bilingues pour Bruxelles)
    private let cities: [LocationOption] = [
        // Bruxelles-Capitale (bilingual)
        LocationOption(name: "Bruxelles", type: .city, alternativeName: "Brussel"),
        LocationOption(name: "Schaerbeek", type: .city, alternativeName: "Schaarbeek"),
        LocationOption(name: "Anderlecht", type: .city, alternativeName: nil),
        LocationOption(name: "Ixelles", type: .city, alternativeName: "Elsene"),
        LocationOption(name: "Molenbeek-Saint-Jean", type: .city, alternativeName: "Sint-Jans-Molenbeek"),
        LocationOption(name: "Woluwe-Saint-Lambert", type: .city, alternativeName: "Sint-Lambrechts-Woluwe"),
        LocationOption(name: "Forest", type: .city, alternativeName: "Vorst"),
        LocationOption(name: "Etterbeek", type: .city, alternativeName: nil),
        LocationOption(name: "Jette", type: .city, alternativeName: nil),
        LocationOption(name: "Saint-Gilles", type: .city, alternativeName: "Sint-Gillis"),
        LocationOption(name: "Uccle", type: .city, alternativeName: "Ukkel"),
        LocationOption(name: "Woluwe-Saint-Pierre", type: .city, alternativeName: "Sint-Pieters-Woluwe"),
        LocationOption(name: "Koekelberg", type: .city, alternativeName: nil),
        LocationOption(name: "Ganshoren", type: .city, alternativeName: nil),
        LocationOption(name: "Berchem-Sainte-Agathe", type: .city, alternativeName: "Sint-Agatha-Berchem"),
        LocationOption(name: "Evere", type: .city, alternativeName: nil),
        LocationOption(name: "Watermael-Boitsfort", type: .city, alternativeName: "Watermaal-Bosvoorde"),
        LocationOption(name: "Auderghem", type: .city, alternativeName: "Oudergem"),
        LocationOption(name: "Saint-Josse-ten-Noode", type: .city, alternativeName: "Sint-Joost-ten-Node"),
        
        // Flandre
        LocationOption(name: "Antwerp", type: .city, alternativeName: "Anvers"),
        LocationOption(name: "Ghent", type: .city, alternativeName: "Gand"),
        LocationOption(name: "Bruges", type: .city, alternativeName: "Brugge"),
        LocationOption(name: "Leuven", type: .city, alternativeName: "Louvain"),
        LocationOption(name: "Mechelen", type: .city, alternativeName: "Malines"),
        LocationOption(name: "Aalst", type: .city, alternativeName: "Alost"),
        LocationOption(name: "Sint-Niklaas", type: .city, alternativeName: "Saint-Nicolas"),
        LocationOption(name: "Ostend", type: .city, alternativeName: "Oostende"),
        LocationOption(name: "Roeselare", type: .city, alternativeName: "Roulers"),
        LocationOption(name: "Genk", type: .city, alternativeName: nil),
        LocationOption(name: "Beveren", type: .city, alternativeName: nil),
        LocationOption(name: "Dendermonde", type: .city, alternativeName: "Termonde"),
        LocationOption(name: "Vilvoorde", type: .city, alternativeName: "Vilvorde"),
        LocationOption(name: "Turnhout", type: .city, alternativeName: nil),
        LocationOption(name: "Hasselt", type: .city, alternativeName: nil),
        LocationOption(name: "Kortrijk", type: .city, alternativeName: "Courtrai"),
        LocationOption(name: "Sint-Truiden", type: .city, alternativeName: "Saint-Trond"),
        LocationOption(name: "Geel", type: .city, alternativeName: nil),
        LocationOption(name: "Lier", type: .city, alternativeName: "Lierre"),
        LocationOption(name: "Ypres", type: .city, alternativeName: "Ieper"),
        LocationOption(name: "Menen", type: .city, alternativeName: "Menin"),
        
        // Wallonie
        LocationOption(name: "Charleroi", type: .city, alternativeName: nil),
        LocationOption(name: "Liège", type: .city, alternativeName: "Luik"),
        LocationOption(name: "Namur", type: .city, alternativeName: "Namen"),
        LocationOption(name: "Mons", type: .city, alternativeName: "Bergen"),
        LocationOption(name: "La Louvière", type: .city, alternativeName: nil),
        LocationOption(name: "Tournai", type: .city, alternativeName: "Doornik"),
        LocationOption(name: "Seraing", type: .city, alternativeName: nil),
        LocationOption(name: "Mouscron", type: .city, alternativeName: "Moeskroen"),
        LocationOption(name: "Verviers", type: .city, alternativeName: nil),
        LocationOption(name: "Châtelet", type: .city, alternativeName: nil),
        LocationOption(name: "Braine-l'Alleud", type: .city, alternativeName: nil),
        LocationOption(name: "Herstal", type: .city, alternativeName: nil),
        LocationOption(name: "Wavre", type: .city, alternativeName: "Waver"),
        LocationOption(name: "Binche", type: .city, alternativeName: nil),
        LocationOption(name: "Ottignies-Louvain-la-Neuve", type: .city, alternativeName: nil),
        LocationOption(name: "Courcelles", type: .city, alternativeName: nil),
        LocationOption(name: "Ans", type: .city, alternativeName: nil),
        LocationOption(name: "Marche-en-Famenne", type: .city, alternativeName: nil),
        LocationOption(name: "Nivelles", type: .city, alternativeName: "Nijvel"),
        LocationOption(name: "Ath", type: .city, alternativeName: nil),
        LocationOption(name: "Soignies", type: .city, alternativeName: "Zinnik"),
        LocationOption(name: "Andenne", type: .city, alternativeName: nil),
        LocationOption(name: "Arlon", type: .city, alternativeName: "Aarlen")
    ]
    
    func searchLocations(query: String) -> [LocationOption] {
        // Si query est vide, retourner les régions en premier
        guard !query.isEmpty else {
            return regions + cities.prefix(10)
        }
        
        let lowerQuery = query.lowercased()
        
        let allOptions = regions + cities
        
        return allOptions.filter { option in
            option.name.lowercased().contains(lowerQuery) ||
            (option.alternativeName?.lowercased().contains(lowerQuery) ?? false)
        }.sorted { option1, option2 in
            // Régions en premier
            if option1.type == .region && option2.type != .region {
                return true
            }
            if option1.type != .region && option2.type == .region {
                return false
            }
            // Puis alphabétique
            return option1.name < option2.name
        }
    }
    
    func getAllLocations() -> [LocationOption] {
        return regions + cities.sorted { $0.name < $1.name }
    }
}
