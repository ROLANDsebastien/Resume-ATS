//
//  StatistiquesView.swift
//  Resume-ATS
//
//  Created by ROLAND Sébastien on 27/09/2025.
//

import AppKit
import Charts
import SwiftData
import SwiftUI

struct MonthlyStat: Identifiable {
    let id = UUID()
    let month: String
    let status: Application.Status
    let count: Int
}

struct MonthStatusKey: Hashable {
    let monthComponents: DateComponents
    let status: Application.Status
}

struct SourceRate: Identifiable {
    let id = UUID()
    let source: String
    let rate: Double
}

struct StatistiquesView: View {
    @Binding var selectedSection: String?
    @Query private var applications: [Application]
    @State private var selectedYear: Int = 2025
    @State private var showingPDFExport = false
    var language: String

    var monthlyStats: [MonthlyStat] {
        let calendar = Calendar.current

        var allMonths: [Date] = []
        let numberOfMonths = 12  // Display 1 year of data

        for i in 0..<numberOfMonths {
            if let date = calendar.date(
                byAdding: .month, value: i,
                to: calendar.date(from: DateComponents(year: selectedYear, month: 1))!)
            {
                allMonths.append(date)
            }
        }

        let groupedByMonthAndStatus = Dictionary(grouping: applications) {
            application -> MonthStatusKey in
            let monthComponents = calendar.dateComponents(
                [.year, .month], from: application.dateApplied)
            return MonthStatusKey(monthComponents: monthComponents, status: application.status)
        }

        var stats: [MonthlyStat] = []
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM"
        dateFormatter.locale = Locale(identifier: language == "fr" ? "fr_FR" : "en_US")

        for monthDate in allMonths {
            let monthComponents = calendar.dateComponents([.year, .month], from: monthDate)
            let monthString = dateFormatter.string(from: monthDate)

            for status in Application.Status.allCases {
                let key = MonthStatusKey(monthComponents: monthComponents, status: status)
                let count = groupedByMonthAndStatus[key]?.count ?? 0
                stats.append(MonthlyStat(month: monthString, status: status, count: count))
            }
        }
        return stats
    }

    var statusDistribution: [Application.Status: Int] {
        Dictionary(grouping: applications, by: { $0.status }).mapValues { $0.count }
    }

    var totalApplications: Int {
        applications.count
    }

    var responseRate: Double {
        guard totalApplications > 0 else { return 0 }
        let responded = totalApplications - (statusDistribution[.pending] ?? 0)
        return Double(responded) / Double(totalApplications) * 100
    }

    var interviewConversionRate: Double {
        guard totalApplications > 0 else { return 0 }
        let interviewed =
            (statusDistribution[.interviewing] ?? 0) + (statusDistribution[.accepted] ?? 0)
        return Double(interviewed) / Double(totalApplications) * 100
    }

    var averageDuration: TimeInterval? {
        let completedApplications = applications.filter {
            $0.status != .pending && $0.status != .applied
        }
        guard !completedApplications.isEmpty else { return nil }
        let totalDuration = completedApplications.reduce(0) {
            $0 + Date().timeIntervalSince($1.dateApplied)
        }
        return totalDuration / Double(completedApplications.count)
    }

    var successRateBySource: [SourceRate] {
        let grouped = Dictionary(
            grouping: applications, by: { $0.source ?? (language == "fr" ? "Inconnue" : "Unknown") }
        )
        var rates: [SourceRate] = []
        for (source, apps) in grouped {
            let successful = apps.filter { $0.status == .interviewing || $0.status == .accepted }
                .count
            let total = apps.count
            let rate = total > 0 ? Double(successful) / Double(total) * 100 : 0
            rates.append(SourceRate(source: source, rate: rate))
        }
        return rates.sorted(by: { $0.rate > $1.rate })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(language == "fr" ? "Statistiques des Candidatures" : "Applications Statistics")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom)

                Picker(language == "fr" ? "Année" : "Year", selection: $selectedYear) {
                    ForEach(2020...2030, id: \.self) { year in
                        Text(String(year))
                    }
                }
                .pickerStyle(.menu)

                // KPIs Section
                VStack(alignment: .leading, spacing: 10) {
                    Text(language == "fr" ? "Indicateurs Clés" : "Key Indicators")
                        .font(.headline)

                    HStack(spacing: 20) {
                        VStack {
                            Text(String(format: "%.1f%%", responseRate))
                                .font(.title2)
                                .fontWeight(.bold)
                            Text(language == "fr" ? "Taux de Réponse" : "Response Rate")
                                .font(.caption)
                        }

                        VStack {
                            Text(String(format: "%.1f%%", interviewConversionRate))
                                .font(.title2)
                                .fontWeight(.bold)
                            Text(language == "fr" ? "Conversion Entretien" : "Interview Conversion")
                                .font(.caption)
                        }

                        if let avgDuration = averageDuration {
                            VStack {
                                Text(String(format: "%.0f", avgDuration / 86400))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text(language == "fr" ? "Jours Moyens" : "Avg Days")
                                    .font(.caption)
                            }
                        }
                    }
                }
                .padding(.vertical)



                // Bar Chart
                VStack(alignment: .leading) {
                    Text(language == "fr" ? "Candidatures par Mois" : "Applications per Month")
                        .font(.headline)

                    Chart(monthlyStats) { stat in
                        BarMark(
                            x: .value(language == "fr" ? "Mois" : "Month", stat.month),
                            y: .value(language == "fr" ? "Nombre" : "Count", stat.count)
                        )
                        .foregroundStyle(
                            by: .value(
                                language == "fr" ? "Statut" : "Status",
                                stat.status.localizedString(language: language)))
                    }
                    .chartForegroundStyleScale([
                        (language == "fr" ? "Acceptée" : "Accepted"): .green,
                        (language == "fr" ? "Refusée" : "Rejected"): .red,
                        (language == "fr" ? "Candidature envoyée" : "Applied"): .blue,
                        (language == "fr" ? "En attente" : "Pending"): .orange,
                        (language == "fr" ? "Retirée" : "Withdrawn"): .gray,
                        (language == "fr" ? "Entretien" : "Interviewing"): .cyan,
                    ])
                    .chartXAxis {
                        AxisMarks {
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 400)
                    .padding(.horizontal)

                }
                .padding(.vertical)


                // PDF Export Button
                Button(action: {
                    showingPDFExport = true
                }) {
                    Label(
                        language == "fr" ? "Exporter en PDF" : "Export to PDF",
                        systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.borderedProminent)
                .padding(.top)
            }
            .padding()
        }
        .sheet(isPresented: $showingPDFExport) {
            PDFExportView(
                applications: applications, language: language, selectedYear: selectedYear)
        }
        .navigationTitle("Resume-ATS")
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: { selectedSection = "Dashboard" }) {
                    Image(systemName: "chevron.left")
                }
            }
        }
    }
}

struct StatisticsPDFView: View {
    let applications: [Application]
    let language: String
    let selectedYear: Int

    var statusDistribution: [Application.Status: Int] {
        Dictionary(grouping: applications, by: { $0.status }).mapValues { $0.count }
    }

    var totalApplications: Int {
        applications.count
    }

    var responseRate: Double {
        guard totalApplications > 0 else { return 0 }
        let responded = totalApplications - (statusDistribution[.pending] ?? 0)
        return Double(responded) / Double(totalApplications) * 100
    }

    var interviewConversionRate: Double {
        guard totalApplications > 0 else { return 0 }
        let interviewed =
            (statusDistribution[.interviewing] ?? 0) + (statusDistribution[.accepted] ?? 0)
        return Double(interviewed) / Double(totalApplications) * 100
    }

    var averageDuration: TimeInterval? {
        let completedApplications = applications.filter {
            $0.status != .pending && $0.status != .applied
        }
        guard !completedApplications.isEmpty else { return nil }
        let totalDuration = completedApplications.reduce(0) {
            $0 + Date().timeIntervalSince($1.dateApplied)
        }
        return totalDuration / Double(completedApplications.count)
    }

    var successRateBySource: [SourceRate] {
        let grouped = Dictionary(
            grouping: applications, by: { $0.source ?? (language == "fr" ? "Inconnue" : "Unknown") }
        )
        var rates: [SourceRate] = []
        for (source, apps) in grouped {
            let successful = apps.filter { $0.status == .interviewing || $0.status == .accepted }
                .count
            let total = apps.count
            let rate = total > 0 ? Double(successful) / Double(total) * 100 : 0
            rates.append(SourceRate(source: source, rate: rate))
        }
        return rates.sorted(by: { $0.rate > $1.rate })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(
                language == "fr"
                    ? "Rapport de Statistiques - \(selectedYear)"
                    : "Statistics Report - \(selectedYear)"
            )
            .font(.largeTitle)
            .fontWeight(.bold)

            // KPIs
            VStack(alignment: .leading, spacing: 10) {
                Text(language == "fr" ? "Indicateurs Clés" : "Key Indicators")
                    .font(.title2)
                    .fontWeight(.semibold)

                HStack(spacing: 30) {
                    VStack {
                        Text(String(format: "%.1f%%", responseRate))
                            .font(.title)
                            .fontWeight(.bold)
                        Text(language == "fr" ? "Taux de Réponse" : "Response Rate")
                            .font(.caption)
                    }

                    VStack {
                        Text(String(format: "%.1f%%", interviewConversionRate))
                            .font(.title)
                            .fontWeight(.bold)
                        Text(language == "fr" ? "Conversion Entretien" : "Interview Conversion")
                            .font(.caption)
                    }

                    if let avgDuration = averageDuration {
                        VStack {
                            Text(String(format: "%.0f", avgDuration / 86400))
                                .font(.title)
                                .fontWeight(.bold)
                            Text(language == "fr" ? "Jours Moyens" : "Avg Days")
                                .font(.caption)
                        }
                    }
                }
            }

            // Status Distribution
            VStack(alignment: .leading, spacing: 10) {
                Text(language == "fr" ? "Répartition par Statut" : "Status Distribution")
                    .font(.title2)
                    .fontWeight(.semibold)

                ForEach(Application.Status.allCases, id: \.self) { status in
                    HStack {
                        Text(status.localizedString(language: language))
                        Spacer()
                        Text("\(statusDistribution[status] ?? 0)")
                    }
                }
            }

            // Success Rate by Source
            VStack(alignment: .leading, spacing: 10) {
                Text(language == "fr" ? "Taux de Succès par Source" : "Success Rate by Source")
                    .font(.title2)
                    .fontWeight(.semibold)

                ForEach(successRateBySource) { item in
                    HStack {
                        Text(item.source)
                        Spacer()
                        Text(String(format: "%.1f%%", item.rate))
                    }
                }
            }

            // Applications List
            VStack(alignment: .leading, spacing: 10) {
                Text(language == "fr" ? "Liste des Candidatures" : "Applications List")
                    .font(.title2)
                    .fontWeight(.semibold)

                ForEach(applications.sorted(by: { $0.dateApplied > $1.dateApplied })) { app in
                    VStack(alignment: .leading) {
                        Text("\(app.company) - \(app.position)")
                            .font(.headline)
                        Text(
                            "\(language == "fr" ? "Statut" : "Status"): \(app.status.localizedString(language: language))"
                        )
                        Text(
                            "\(language == "fr" ? "Source" : "Source"): \(app.source ?? (language == "fr" ? "Inconnue" : "Unknown"))"
                        )
                        Text(
                            "\(language == "fr" ? "Date" : "Date"): \(app.dateApplied.formatted(date: .abbreviated, time: .omitted))"
                        )
                    }
                    .padding(.vertical, 5)
                }
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct PDFExportView: View {
    let applications: [Application]
    let language: String
    let selectedYear: Int
    @Environment(\.dismiss) private var dismiss
    @State private var isGenerating = false
    @State private var generatedURL: URL?

    var body: some View {
        VStack {
            if isGenerating {
                ProgressView(language == "fr" ? "Génération du PDF..." : "Generating PDF...")
            } else if let url = generatedURL {
                Text(language == "fr" ? "PDF généré avec succès !" : "PDF generated successfully!")
                Button(language == "fr" ? "Ouvrir le PDF" : "Open PDF") {
                    NSWorkspace.shared.open(url)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                Button(language == "fr" ? "Fermer" : "Close") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            } else {
                Text(language == "fr" ? "Erreur lors de la génération" : "Error generating PDF")
                Button(language == "fr" ? "Fermer" : "Close") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .onAppear {
            generatePDF()
        }
    }

    private func generatePDF() {
        isGenerating = true
        PDFService.generateStatisticsPDF(
            applications: applications, language: language, selectedYear: selectedYear
        ) { url in
            isGenerating = false
            generatedURL = url
        }
    }
}

#Preview {
    StatistiquesView(selectedSection: .constant(nil), language: "fr")
        .modelContainer(for: [Application.self], inMemory: true)
}
