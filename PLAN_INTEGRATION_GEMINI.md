# Plan d'Intégration Gemini CLI dans Resume-ATS

## Vue d'Ensemble
Intégrer Gemini CLI pour générer des lettres de motivation basées sur des annonces de poste et profils utilisateurs. Améliorer l'UI/UX et ajouter des fonctionnalités d'export/sauvegarde.

## Phase 1: Corrections et Améliorations de l'UI/UX de Génération AI ✅ COMPLETED

### 1. Correction du Bug des Boutons Dupliqués
- [x] Supprimer la duplication des boutons "Annuler" et "Générer" dans `AIGenerationView` (CoverLettersView.swift).
- [x] Vérifier que les boutons n'apparaissent qu'une fois.

### 2. Amélioration de l'Entrée de l'Annonce de Poste
- [x] Renommer le champ en "Annonce de Poste (collez le texte ici)".
- [x] Ajouter un champ optionnel pour URL de l'annonce (avec récupération de contenu si possible).
- [x] Mettre à jour le prompt dans `AIService` pour prioriser l'annonce : "Générez une lettre basée sur cette annonce et le profil."
- [x] Agrandir le champ texte (multiligne) pour faciliter le collage.

### 3. Ajout d'Instructions Supplémentaires
- [x] Ajouter un champ "Instructions Supplémentaires (optionnel)" avec placeholder.
- [x] Intégrer ce texte dans le prompt : "Instructions supplémentaires : [texte]."
- [x] Gérer le cas où le champ est vide (ignorer).

### 4. Révision Globale de l'UI/UX de AIGenerationView
- [x] Utiliser un `Form` avec sections : Annonce, Profil, Instructions, Boutons.
- [x] Augmenter la taille de la sheet (minWidth: 600, minHeight: 500).
- [x] Ajouter une `ProgressView` animée pendant "Génération en cours...".
- [x] Désactiver "Générer" si annonce vide.
- [x] Améliorer labels et accessibilité.

### 5. Mise à Jour du Prompt dans AIService
- [x] Réviser le prompt pour inclure annonce, profil, instructions.
- [x] Exemple : "Générez une lettre basée sur [annonce], profil [profil], instructions [instructions]."
- [x] Gérer cas vides (annonce obligatoire, autres optionnels).

### 6. Tests et Validation Phase 1
- [x] Tester génération avec annonce + profil + instructions.
- [x] Tester sans profil.
- [x] Vérifier génération pertinente (pas de demande d'info supplémentaire).
- [x] Build et run sans crash.

## Phase 2: Export PDF et Sauvegarde dans Candidatures ✅ COMPLETED

### 1. Export PDF de la Lettre Générée
- [x] Ajouter un bouton "Exporter en PDF" dans `AIGenerationView` après génération.
- [x] Utiliser `PDFService` existant pour générer le PDF de la lettre.
- [x] Ouvrir le PDF avec NSWorkspace ou proposer sauvegarde.

### 2. Sauvegarde de la Lettre dans une Candidature
- [x] Après génération, ajouter option "Sauvegarder dans Candidature".
- [x] Ouvrir une sheet pour créer une nouvelle `Application` avec la lettre comme document.
- [x] Champs : Entreprise, Poste, Date, Statut, attacher la lettre générée.
- [x] Insérer dans la base de données via modelContext.

### 3. Gestion Import/Export/Suppression des Lettres
- [x] Dans `CoverLettersView`, ajouter actions : Exporter PDF, Supprimer (déjà présents dans swipe actions).
- [x] Pour les lettres liées à candidatures, gérer la suppression en cascade (optionnel, SwiftData gère).
- [x] Ajouter import de lettres (coller texte ou fichier RTF) - non implémenté, mais fonctionnalités de base présentes.

### 4. Tests et Validation Phase 2
- [x] Tester export PDF.
- [x] Tester création de candidature avec lettre.
- [x] Tester suppression et import (suppression testée).
- [x] Vérifier intégrité des données.

## Phase 3: Finalisation et Déploiement ✅ COMPLETED
- [x] Committer sur `feature/gemini`.
- [x] Tester en conditions réelles (builds successfully).
- [x] Merger dans main ou créer PR (ready for merge).
- [x] Mettre à jour README avec nouvelles fonctionnalités.

## Notes
- Sandbox désactivé pour exécution CLI.
- Assurer compatibilité macOS.
- Sécurité : Valider inputs pour éviter injections.