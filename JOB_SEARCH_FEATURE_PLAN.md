# Plan Complet : Fonctionnalité de Recherche d'Emplois Multi-Sites avec IA

## 🎯 Objectif

Créer une fonctionnalité robuste de recherche d'emplois qui :
- Scrappe plusieurs sites d'emploi belges/européens
- Utilise l'IA (Gemini) pour matcher les emplois au profil utilisateur
- Offre une expérience utilisateur fluide et professionnelle
- Gère les erreurs et les cas limites élégamment

---

## 📋 Architecture Globale

### 1. Modèles de Données

#### `JobResult` (Intermédiaire - Scraping)
```swift
struct JobResult: Identifiable {
    let id: String
    let title: String
    let company: String
    let location: String
    let salary: String?
    let url: String
    let source: String  // "jobat", "ictjobs", etc.
    let scrapedAt: Date
}
```

#### `Job` (Final - Avec Score IA)
```swift
@Model
class Job {
    var id: String
    var title: String
    var company: String
    var location: String
    var salary: String?
    var url: String
    var source: String
    var aiScore: Int?  // 0-100
    var matchReason: String?
    var missingRequirements: [String]
    var isFavorite: Bool
    var isApplied: Bool
    var notes: String
    var createdAt: Date
}
```

---

## 🔧 Services à Créer/Améliorer

### 1. **ScraperProtocol** (Interface commune)

```swift
protocol JobScraper {
    var sourceName: String { get }
    func search(keywords: String, location: String?) async throws -> [JobResult]
    func isAvailable() async -> Bool
}
```

### 2. **Scrapers Individuels** (Un par site)

#### Sites prioritaires :
1. **Jobat.be** ⭐ (Principal site belge)
2. **ICTJobs.be** (IT spécialisé)
3. **StepStone.be** (International)
4. **LinkedIn Jobs** (Optionnel - complexe)
5. **Indeed.be** (Agrégateur)

#### Structure de chaque scraper :
- Gestion des erreurs réseau
- Timeout configurable
- Rate limiting
- Parsing HTML robuste (SwiftSoup)
- Fallback si le site change

### 3. **MultiSiteScraper** (Orchestrateur)

```swift
class MultiSiteScraper {
    private let scrapers: [JobScraper]
    
    func searchAllSites(
        keywords: String,
        location: String?,
        maxResultsPerSite: Int = 20
    ) async -> [JobResult] {
        // Exécute tous les scrapers en parallèle
        // Déduplique les résultats
        // Trie par pertinence
    }
}
```

### 4. **AIMatchingService** (Gemini Integration)

> [!IMPORTANT]
> **Ne pas spécifier le chemin de Gemini** - utiliser la configuration système existante qui fonctionne

```swift
class AIMatchingService {
    func matchJobs(
        _ jobs: [JobResult],
        profile: Profile,
        language: String = "fr"
    ) async throws -> [Job] {
        // Appelle Gemini CLI (chemin géré par config)
        // Parse la réponse JSON
        // Retourne les jobs avec scores
    }
}
```

**Prompt optimisé pour Gemini :**
- Inclure tout le profil (compétences, expérience, langues)
- Demander un score 0-100
- Demander une raison courte
- Demander les requis manquants
- Filtrer les jobs en néerlandais si non parlé

### 5. **JobSearchService** (Service principal)

```swift
class JobSearchService {
    private let multiScraper: MultiSiteScraper
    private let aiMatcher: AIMatchingService
    
    func search(
        keywords: String,
        location: String?,
        profile: Profile
    ) async throws -> [Job] {
        // 1. Scrappe tous les sites
        // 2. Déduplique
        // 3. Envoie à l'IA pour matching
        // 4. Sauvegarde dans SwiftData
        // 5. Retourne les résultats triés
    }
}
```

---

## 🎨 Vues UI

### 1. **JobSearchView** (Vue principale)

**Composants :**
- Barre de recherche (keywords)
- Sélecteur de localisation (avec suggestions)
- Bouton "Rechercher"
- Indicateur de progression
- Liste des résultats

**États :**
```swift
enum SearchState {
    case idle
    case searching(progress: Double, currentSite: String)
    case aiMatching
    case completed([Job])
    case error(String)
}
```

### 2. **JobCardView** (Carte de résultat)

**Affichage :**
- Titre + Entreprise
- Localisation + Salaire
- Badge de source (Jobat, ICTJobs, etc.)
- Score IA avec barre de progression colorée
- Raison du match (expandable)
- Boutons : Favoris, Postuler, Voir détails

### 3. **JobDetailView** (Détails d'un emploi)

**Sections :**
- Informations complètes
- Score IA détaillé
- Compétences manquantes
- Notes personnelles
- Actions (ouvrir URL, marquer comme postulé)

### 4. **JobFiltersView** (Filtres avancés)

**Filtres :**
- Score minimum
- Sources (multi-sélection)
- Salaire minimum
- Distance maximale
- Favoris uniquement
- Non postulés uniquement

---

## ⚠️ Points Bloquants et Solutions

### 1. **Gemini CLI ne fonctionne pas**

**Solution :** Revenir au commit où ça fonctionnait, puis :
- Ne **jamais** toucher aux chemins Gemini
- Créer une classe `GeminiConfig` qui encapsule la configuration
- Tester immédiatement après chaque changement

### 2. **Sites qui changent leur HTML**

**Solutions :**
- Utiliser plusieurs sélecteurs CSS en fallback
- Logger les erreurs de parsing
- Continuer avec les autres sites si un échoue
- Tests réguliers automatisés

### 3. **Rate Limiting / Blocage**

**Solutions :**
- Délai entre requêtes (1-2 secondes)
- User-Agent réaliste
- Rotation de User-Agents
- Respecter robots.txt
- Cache des résultats (15-30 min)

### 4. **Performance avec beaucoup de résultats**

**Solutions :**
- Pagination côté UI
- Lazy loading
- Limiter à 100 résultats max
- Background processing pour l'IA

### 5. **Déduplication des emplois**

**Algorithme :**
```swift
func isDuplicate(job1: JobResult, job2: JobResult) -> Bool {
    // Même titre (fuzzy match 90%)
    // Même entreprise (exact ou similaire)
    // Même localisation (ville)
    return similarityScore > 0.85
}
```

---

## 🚀 Plan d'Implémentation (Étapes)

### Phase 1 : Fondations (1-2h)
- [ ] Revenir au commit fonctionnel
- [ ] Créer `JobResult` et `Job` models
- [ ] Créer `JobScraper` protocol
- [ ] Tester que Gemini fonctionne toujours

### Phase 2 : Scrapers (3-4h)
- [ ] Implémenter `JobatScraper`
- [ ] Implémenter `ICTJobsScraper`
- [ ] Implémenter `StepStoneScraper`
- [ ] Créer `MultiSiteScraper`
- [ ] Tests unitaires pour chaque scraper

### Phase 3 : IA Matching (2-3h)
- [ ] Créer `AIMatchingService`
- [ ] Optimiser le prompt Gemini
- [ ] Parser la réponse JSON
- [ ] Gestion d'erreurs robuste
- [ ] Tests avec vrais profils

### Phase 4 : Service Principal (1-2h)
- [ ] Créer `JobSearchService`
- [ ] Implémenter déduplication
- [ ] Implémenter cache
- [ ] Gestion d'état complète

### Phase 5 : UI (3-4h)
- [ ] `JobSearchView` avec états
- [ ] `JobCardView` avec animations
- [ ] `JobDetailView`
- [ ] `JobFiltersView`
- [ ] Navigation fluide

### Phase 6 : Polish (2-3h)
- [ ] Gestion d'erreurs UI
- [ ] Messages utilisateur clairs
- [ ] Animations et transitions
- [ ] Tests end-to-end
- [ ] Documentation

**Total estimé : 12-18 heures**

---

## 🎯 Fonctionnalités "WOW"

### 1. **Recherche Intelligente**
- Auto-complétion des mots-clés basée sur le profil
- Suggestions de localisation avec distance
- Sauvegarde des recherches récentes

### 2. **Matching IA Avancé**
- Score visuel avec code couleur (🔴 <60, 🟡 60-80, 🟢 >80)
- Explication détaillée du score
- Suggestions d'amélioration du profil

### 3. **Comparaison Multi-Sites**
- Voir le même emploi sur différents sites
- Comparer les descriptions
- Choisir la meilleure source

### 4. **Notifications**
- Alerte si nouvel emploi >90% match
- Rappel de postuler aux favoris
- Statistiques de recherche

### 5. **Export**
- Export PDF de la liste
- Export CSV pour tracking
- Génération de lettre de motivation (Gemini)

---

## 📊 Métriques de Succès

- ✅ Au moins 3 sites scrapés avec succès
- ✅ >80% des emplois correctement parsés
- ✅ Temps de recherche <10 secondes
- ✅ Score IA pertinent (validation manuelle)
- ✅ 0 crash sur erreurs réseau
- ✅ UI fluide et responsive

---

## 🔐 Sécurité et Éthique

- Respecter les Terms of Service des sites
- Ne pas surcharger les serveurs (rate limiting)
- Ne pas stocker de données personnelles des offres
- Informer l'utilisateur de la source des données
- Permettre la suppression facile des données

---

## 📝 Notes Techniques

### Librairies Recommandées
- **SwiftSoup** : Parsing HTML ✅ (déjà utilisé)
- **Alamofire** : Requêtes HTTP (optionnel, URLSession suffit)
- **SwiftData** : Persistance ✅ (déjà utilisé)

### Configuration Gemini
```swift
// NE PAS TOUCHER - Utiliser config existante
class GeminiConfig {
    static let shared = GeminiConfig()
    // Chemin géré automatiquement
    func execute(prompt: String) async throws -> String
}
```

### Gestion d'Erreurs
```swift
enum JobSearchError: LocalizedError {
    case noResults
    case scrapingFailed(site: String, reason: String)
    case aiMatchingFailed(reason: String)
    case networkError(Error)
    
    var errorDescription: String? {
        // Messages utilisateur clairs en FR
    }
}
```

---

## 🎨 Design System

### Couleurs
- **Score élevé** : Vert (#4CAF50)
- **Score moyen** : Orange (#FF9800)
- **Score faible** : Rouge (#F44336)
- **Source badges** : Bleu (#2196F3)

### Icônes
- 🔍 Recherche
- 🎯 Score IA
- ⭐ Favoris
- ✅ Postulé
- 📍 Localisation
- 💰 Salaire

---

## ✅ Checklist Finale

Avant de considérer la feature terminée :

- [ ] Gemini fonctionne sans erreur
- [ ] Au moins 3 scrapers opérationnels
- [ ] Déduplication efficace
- [ ] UI responsive et fluide
- [ ] Gestion d'erreurs complète
- [ ] Tests sur vrais profils
- [ ] Documentation code
- [ ] README mis à jour
- [ ] Pas de chemins hardcodés
- [ ] Performance acceptable (<10s)

---

> [!TIP]
> **Conseil Principal** : Implémenter et tester chaque scraper **individuellement** avant de les combiner. Cela facilite le debug et garantit la qualité.

> [!WARNING]
> **Attention** : Ne jamais modifier les chemins Gemini une fois que ça fonctionne. Créer une abstraction et ne plus y toucher.
