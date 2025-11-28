# Plan d'Amélioration : Recherche d'Emploi & IA

Ce document détaille pourquoi la fonctionnalité de recherche actuelle retourne peu de résultats et propose un plan d'action concret pour transformer l'application en un outil de "Daily Apply" performant pour les profils QA, DevOps, et IT Support.

## 1. Diagnostic : Pourquoi si peu de résultats ?

L'analyse du code a révélé 4 goulots d'étranglement majeurs qui limitent artificiellement le nombre d'offres. Ce n'est pas l'IA qui filtre trop, c'est le système qui ne lui donne pas assez à manger.

### A. Le problème de la "Pagination Manquante" (Critique 🔴)
Actuellement, les scrapers (`ICTJobs`, `Jobat`, `OptionCarriere`) ne lisent **que la première page** des résultats.
*   *Conséquence :* Si une recherche "DevOps" donne 500 résultats sur le site web, l'application n'en voit que 10 à 20.
*   *Impact :* 95% des offres sont invisibles pour l'application.

### B. La "Division par Mots-Clés" (Critique 🔴)
Dans `JobSearchService.swift`, le nombre total de résultats demandés (`maxResults`, par défaut 50) est **divisé** par le nombre de mots-clés.
*   *Le Code :* `maxResults: maxResults / searchKeywords.count`
*   *Exemple :* Si l'IA génère 5 mots-clés (QA, Tester, Automation, ISTQB, IT), l'app demande seulement **10 offres** au total pour "QA", 10 pour "Tester", etc. Réparti sur 4 sites, cela fait à peine **2 offres par site**.
*   *Impact :* On s'auto-limite drastiquement avant même de commencer.

### C. Le cas "Editx" (Moyen 🟠)
Le scraper `EditxScraper` n'effectue pas une vraie recherche. Il télécharge un fichier "sitemap" (liste de toutes les pages du site) et cherche le mot-clé dans l'URL.
*   *Problème :* Si le mot-clé n'est pas dans l'URL (mais dans la description), l'offre est ratée. De plus, il est limité aux 15 premières correspondances trouvées dans tout le site.

### D. La limite d'Analyse IA (Moyen 🟠)
Dans `JobSearchService.swift`, seules les **15 premières offres** trouvées sont envoyées à l'IA pour analyse (`prefix(15)`).
*   *Conséquence :* Les offres suivantes sont affichées sans score de compatibilité ni résumé.

---

## 2. Plan d'Action Technique

Voici les modifications à apporter pour garantir un flux constant de 50 à 100+ nouvelles offres pertinentes chaque matin.

### Phase 1 : "Ouvrir les vannes" (Scraping & Pagination)
*Objectif : Récupérer toutes les offres disponibles, pas juste la page 1.*

1.  **Implémenter la Pagination :** Modifier chaque scraper pour qu'il boucle sur les pages (Page 1, Page 2, Page 3...) jusqu'à atteindre une limite (ex: 100 offres ou 5 pages).
2.  **Réécrire `EditxScraper` :** Abandonner la méthode sitemap. Utiliser l'URL de recherche réelle du site Editx (ex: `https://www.editx.eu/en/jobs/?q=DevOps`).
3.  **Robustesse du Parsing :** Les "Regex" actuelles sont fragiles. Si le site change une virgule, le scraper casse.
    *   *Solution :* Utiliser une librairie de parsing HTML solide (comme `SwiftSoup`) ou améliorer les patterns de détection pour qu'ils soient plus tolérants.

### Phase 2 : Optimiser l'Orchestration
*Objectif : Ne plus brider la recherche.*

1.  **Supprimer la Division par Mots-Clés :**
    *   *Avant :* `limit = 50 / 5 mots-clés = 10`
    *   *Après :* `limit = 50` (par mot-clé). On veut 50 résultats pour "QA", ET 50 résultats pour "DevOps".
2.  **Augmenter la capacité IA :**
    *   Passer la limite d'analyse IA de 15 à **50 ou 100**.
    *   Optimiser `processBatchJobs` pour traiter les offres par lots (chunks) de 10 en parallèle pour ne pas attendre 3 minutes.

### Phase 3 : Stratégie de Recherche (Mots-Clés)
*Objectif : Mieux cibler pour avoir moins de bruit.*

1.  **Recherche Exacte vs Large :**
    *   Pour "ISTQB", c'est un mot-clé très précis -> rechercher tel quel.
    *   Pour "IT Support", c'est large -> rechercher "Support" et "Helpdesk".
2.  **Configuration Utilisateur :**
    *   Permettre à l'utilisateur de définir ses propres mots-clés fixes (ex: "DevOps", "QA Tester") dans les réglages, au lieu de laisser l'IA deviner à chaque fois à partir du profil.

---

## 3. Nouvelle Fonctionnalité : "Morning Routine"

Pour atteindre votre but de "postuler à tout le matin", nous devrons ajouter ces fonctionnalités UX une fois le backend réparé :

1.  **Bouton "Tout Postuler" (Batch Apply) :**
    *   Une action pour ouvrir les 10 meilleures offres dans 10 onglets du navigateur d'un coup.
2.  **Suivi Automatique :**
    *   Dès qu'on clique sur "Voir l'offre", l'ajouter automatiquement dans la base de données "Candidatures" avec le statut "Vu" ou "À faire".
3.  **Filtre "Nouveaux" :**
    *   Ne montrer que les offres jamais vues (basé sur l'URL).

## Conclusion

La priorité absolue est la **Phase 1 (Pagination)** et la suppression de la division par mots-clés dans la **Phase 2**. Une fois fait, vous devriez voir passer le nombre de résultats de ~10 à ~200 pour une recherche standard.
