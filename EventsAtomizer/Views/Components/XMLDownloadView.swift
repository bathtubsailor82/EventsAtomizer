//
//  XMLDownloadView.swift
//  EventsAtomizer
//
//  Created by localadmin on 19/02/2025.
//

import SwiftUI

struct XMLDownloadView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var numberOfWeeks = 1
    @State private var startDate = Date()
    @State private var showImportInstructions = false
    
    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Start Date", selection: $startDate, displayedComponents: [.date])
                Stepper("Number of weeks: \(numberOfWeeks)", value: $numberOfWeeks, in: 1...4)
                
                if showImportInstructions {
                    Section("Next Steps") {
                        Text("1. Once downloaded, save the XML file")
                        Text("2. Use the 'Import Local XML' button in the main window to import the file")
                    }
                }
            }
            .navigationTitle("Download XML Report")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Download") {
                        downloadReport()
                        showImportInstructions = true
                    }
                }
            }
        }
    }
    
    private func downloadReport() {
        let urlString = "https://ssrsprd2019web.coe.int/WS_ReportServer/Pages/ReportViewer.aspx?%2fEVENTS%2fAllDatacards&rs:Command=Render&rs:Format=XML&StartDateParameter=\(formatDate(startDate))&NumberOfWeeks=\(numberOfWeeks)&CanceledVenuesParameter=true&DisplayIdService=true"
        
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
