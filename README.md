# Resume-ATS

A macOS application for IT professionals to create ATS-optimized resumes, manage job applications, and generate AI-powered cover letters.

Une application macOS pour les professionnels IT pour creer des CV optimises ATS, gerer les candidatures et generer des lettres de motivation avec IA.

---

## English

### Overview

Resume-ATS is a comprehensive macOS application designed to streamline the job application process for IT professionals. Built with SwiftUI and SwiftData, it provides powerful tools for creating ATS-friendly resumes, tracking applications, and generating personalized cover letters using AI.

### Key Features

#### Profile Management
- Create and manage multiple professional profiles
- Add detailed information including contact details, summary, and photo
- Support for multiple languages (French and English)
- Organize profile sections with drag-and-drop reordering
- Toggle visibility of individual sections
- Rich text editing for summaries and descriptions

#### Professional Experience
- Track work experiences with detailed descriptions
- Manage education history
- Add professional references
- Organize skills by categories
- List certifications with dates and verification links
- Add language proficiencies with skill levels

#### CV Generation
- Generate ATS-optimized PDF resumes
- Professional formatting designed to pass automated screening systems
- Automatic pagination with proper page breaks
- Optional photo inclusion in PDFs
- Customizable section visibility and ordering
- Export CVs with consistent Arial font formatting

#### Application Tracking
- Track job applications with status management
- Application states: Applied, Pending, Interviewing, Rejected, Accepted, Withdrawn
- Attach relevant documents to applications
- Link cover letters to specific applications
- Add notes and track application sources
- Monitor application history and timelines

#### AI-Powered Cover Letters
- Generate personalized cover letters using Gemini CLI
- Automatic extraction of company and position from job descriptions
- Cover letter generation based on profile and job requirements
- Support for custom instructions and customization
- Rich text editing with formatting options
- Export cover letters to PDF
- Save and manage cover letter library

#### Statistics and Analytics
- Visual dashboard with application statistics
- Charts showing application status distribution
- Application timeline tracking
- Success rate metrics
- Monthly application trends

#### Data Management
- Automatic database backups with configurable intervals
- Manual backup creation and restoration
- Database integrity verification
- Auto-save functionality with periodic saves
- Scene phase-aware saving (background, inactive, active)
- Database export and import capabilities

#### User Interface
- Modern macOS design with native UI components
- Support for light and dark mode
- Customizable window size with persistence
- Bilingual interface (English and French)
- Smooth navigation with split view layout
- Material design with Tahoe and liquid glass effects

### Technical Stack

- Language: Swift
- UI Framework: SwiftUI
- Database: SwiftData with SQLite backend
- AI Integration: Gemini CLI for text generation
- Platform: macOS (Apple Silicon optimized)
- Minimum Requirements: macOS with Apple Silicon

### Project Structure

```
Resume-ATS/
├── Models/
│   ├── Profile.swift - Profile and related data models
│   ├── Application.swift - Job application tracking
│   ├── CoverLetter.swift - Cover letter management
│   ├── CVDocument.swift - CV document storage
│   ├── AIService.swift - Gemini CLI integration
│   ├── PDFService.swift - PDF generation
│   ├── DataService.swift - Data operations
│   ├── DatabaseBackupService.swift - Backup management
│   └── BuildService.swift - Build configuration
├── Views/
│   ├── ContentView.swift - Main app layout
│   ├── DashboardView.swift - Dashboard overview
│   ├── ProfileView.swift - Profile management
│   ├── CandidaturesView.swift - Application tracking
│   ├── CoverLettersView.swift - Cover letter management
│   ├── CVsView.swift - CV document management
│   ├── StatistiquesView.swift - Statistics and charts
│   ├── ATSResumeView.swift - ATS resume template
│   └── SettingsView.swift - App settings
├── Services/
│   ├── AutoSaveService.swift - Automatic saving
│   └── SaveManager.swift - Save coordination
└── Assets.xcassets - App resources
```

### Requirements

- macOS with Apple Silicon (M1/M2/M3)
- Xcode 15 or later
- Swift 5.9 or later
- Gemini CLI installed at /opt/homebrew/bin/gemini (for AI features)
- Free Apple Developer account (for building and running)

### Installation

1. Clone the repository
2. Open Resume-ATS.xcodeproj in Xcode
3. Install Gemini CLI if you want AI-powered features
4. Build and run the application

### Database

The application uses SwiftData with SQLite backend. Database location:
```
~/Library/Application Support/com.sebastienroland.Resume-ATS/ResumeATS.store
```

Automatic backups are stored in:
```
~/Library/Application Support/com.sebastienroland.Resume-ATS/Backups/
```

---

## Francais

### Apercu

Resume-ATS est une application macOS complete concue pour simplifier le processus de candidature pour les professionnels IT. Developpee avec SwiftUI et SwiftData, elle fournit des outils puissants pour creer des CV compatibles ATS, suivre les candidatures et generer des lettres de motivation personnalisees avec IA.

### Fonctionnalites principales

#### Gestion de profil
- Creer et gerer plusieurs profils professionnels
- Ajouter des informations detaillees incluant contacts, resume et photo
- Support multilingue (francais et anglais)
- Organiser les sections du profil par glisser-deposer
- Basculer la visibilite des sections individuelles
- Edition de texte enrichi pour resumes et descriptions

#### Experience professionnelle
- Suivre les experiences de travail avec descriptions detaillees
- Gerer lhistorique de formation
- Ajouter des references professionnelles
- Organiser les competences par categories
- Lister les certifications avec dates et liens de verification
- Ajouter les competences linguistiques avec niveaux

#### Generation de CV
- Generer des CV PDF optimises ATS
- Formatage professionnel concu pour passer les systemes de filtrage automatises
- Pagination automatique avec sauts de page appropries
- Inclusion optionnelle de photo dans les PDF
- Visibilite et ordre des sections personnalisables
- Export de CV avec formatage de police Arial uniforme

#### Suivi des candidatures
- Suivre les candidatures avec gestion des statuts
- Etats de candidature: Envoyee, En attente, Entretien, Refusee, Acceptee, Retiree
- Joindre des documents pertinents aux candidatures
- Lier des lettres de motivation a des candidatures specifiques
- Ajouter des notes et suivre les sources de candidature
- Monitorer lhistorique et les chronologies des candidatures

#### Lettres de motivation avec IA
- Generer des lettres de motivation personnalisees avec Gemini CLI
- Extraction automatique de lentreprise et du poste depuis les descriptions
- Generation de lettres basee sur le profil et les exigences du poste
- Support pour instructions personnalisees et customisation
- Edition de texte enrichi avec options de formatage
- Export de lettres de motivation en PDF
- Sauvegarde et gestion de bibliotheque de lettres

#### Statistiques et analyses
- Tableau de bord visuel avec statistiques de candidatures
- Graphiques montrant la distribution des statuts
- Suivi de chronologie des candidatures
- Metriques de taux de reussite
- Tendances mensuelles des candidatures

#### Gestion des donnees
- Sauvegardes automatiques de base de donnees avec intervalles configurables
- Creation et restauration manuelle de sauvegardes
- Verification de lintegrite de la base de donnees
- Fonction dauto-sauvegarde avec sauvegardes periodiques
- Sauvegarde consciente de la phase de scene (arriere-plan, inactif, actif)
- Capacites dexport et dimport de base de donnees

#### Interface utilisateur
- Design macOS moderne avec composants UI natifs
- Support des modes clair et sombre
- Taille de fenetre personnalisable avec persistence
- Interface bilingue (anglais et francais)
- Navigation fluide avec disposition en vue divisee
- Design materiel avec effets Tahoe et verre liquide

### Stack technique

- Langage: Swift
- Framework UI: SwiftUI
- Base de donnees: SwiftData avec backend SQLite
- Integration IA: Gemini CLI pour generation de texte
- Plateforme: macOS (optimise Apple Silicon)
- Prerequis minimum: macOS avec Apple Silicon

### Configuration requise

- macOS avec Apple Silicon (M1/M2/M3)
- Xcode 15 ou superieur
- Swift 5.9 ou superieur
- Gemini CLI installe dans /opt/homebrew/bin/gemini (pour fonctionnalites IA)
- Compte Apple Developer gratuit (pour compiler et executer)

### Installation

1. Cloner le depot
2. Ouvrir Resume-ATS.xcodeproj dans Xcode
3. Installer Gemini CLI si vous voulez les fonctionnalites IA
4. Compiler et executer lapplication

### Base de donnees

Lapplication utilise SwiftData avec backend SQLite. Emplacement de la base:
```
~/Library/Application Support/com.sebastienroland.Resume-ATS/ResumeATS.store
```

Les sauvegardes automatiques sont stockees dans:
```
~/Library/Application Support/com.sebastienroland.Resume-ATS/Backups/
```
