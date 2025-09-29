//
//  StatistiquesView.swift
//  Resume-ATS
//
//  Created by ROLAND Sébastien on 27/09/2025.
//

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

struct StatistiquesView: View {
    @Binding var selectedSection: String?
    @Query private var applications: [Application]
    @State private var selectedYear: Int = 2025
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

                Chart(monthlyStats) { stat in
                    BarMark(
                        x: .value(language == "fr" ? "Mois" : "Month", stat.month),
                        y: .value(language == "fr" ? "Nombre" : "Count", stat.count)
                    )
                    .foregroundStyle(by: .value(language == "fr" ? "Statut" : "Status", stat.status.localizedString(language: language)))
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
                    AxisMarks { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel()
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 400)
                .padding(.horizontal)
            }
            .padding()
        }
        .navigationTitle("Resume-ATS")
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: {
                    selectedSection = "Dashboard"
                }) {
                    Image(systemName: "chevron.left")
                }
            }
        }
    }
}

#Preview {
    StatistiquesView(selectedSection: .constant(nil), language: "fr")
        .modelContainer(for: [Application.self], inMemory: true)
}
