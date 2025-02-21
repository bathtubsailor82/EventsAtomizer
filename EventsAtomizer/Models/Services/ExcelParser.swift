//
//  ExcelDateConverter.swift
//  EventsAtomizer
//
//  Created by localadmin on 20/02/2025.
//

import Foundation
import CoreXLSX
import SwiftData

@Model
class Item {
    // Propriétés obligatoires
    var id: UUID
    
    // Propriétés optionnelles
    var readableId: String?
    var eventName: String?
    var startDateTime: Date?
    var endDateTime: Date?
    var venue: String?
    var serviceType: String?
    var serviceId: String?
    var serviceCard: String?
    var status: String?
    var eventStatus: String?
    var secretariatContact: String?
    var eventLink: String? // Nouveau champ pour Excel
    
    init() {
        self.id = UUID()
    }
}

class ExcelParser {
    enum ExcelError: Error {
        case invalidFile
        case missingWorksheet
        case invalidData(String)
        case parsingError(String)
    }
    
    func parse(url: URL) async throws -> [Item] {
        guard let file = XLSXFile(filepath: url.path) else {
            throw ExcelError.invalidFile
        }
        
        // Récupérer toutes les feuilles disponibles
        let paths = try file.parseWorksheetPaths()
        guard let firstPath = paths.first else {
            throw ExcelError.missingWorksheet
        }
        
        // On récupère les données de la première feuille
        let worksheet = try file.parseWorksheet(at: firstPath)
        
        // Parser chaque ligne
        var items: [Item] = []
        
        for row in worksheet.data?.rows.dropFirst() ?? [] {
            let item = Item()
            // Remplir l'item avec les données de la ligne
            items.append(item)
        }
        
        return items
    }
    
    private func getHeaders(worksheet: Worksheet) throws -> [String: Int] {
        var headers: [String: Int] = [:]
        
        guard let headerRow = worksheet.data?.rows.first else {
            throw ExcelError.parsingError("Pas d'en-têtes trouvés")
        }
        
        for (index, cell) in headerRow.cells.enumerated() {
            if let header = cell.value {
                headers[header] = index
            }
        }
        
        return headers
    }
    
    private func parseRow(row: Row, headers: [String: Int]) throws -> Item? {
        let item = Item()
        
        // Helper pour récupérer la valeur d'une cellule par nom de colonne
        func getValue(for header: String) -> String? {
            guard let index = headers[header],
                  index < row.cells.count,
                  let value = row.cells[index].value else {
                return nil
            }
            return value
        }
        
        // Mapping des champs basiques
        item.readableId = getValue(for: "Readable Id")
        item.eventName = cleanupText(getValue(for: "Event Name"))
        item.venue = getValue(for: "Venue")
        item.serviceType = getValue(for: "Service Type")
        item.status = getValue(for: "Status")
        item.eventStatus = getValue(for: "Event Status")
        item.serviceId = getValue(for: "Id Service")
        item.serviceCard = cleanupText(getValue(for: "Service Card"))
        item.secretariatContact = cleanupText(getValue(for: "Event Secretariat Contact"))
        item.eventLink = getValue(for: "Link to Event")
        
        // Conversion des dates
        if let startDateStr = getValue(for: "Start Date Time") {
            item.startDateTime = parseExcelDate(startDateStr)
        }
        
        if let endDateStr = getValue(for: "End Date Time") {
            item.endDateTime = parseExcelDate(endDateStr)
        }
        
        return item
    }
    
    private func parseExcelDate(_ dateString: String) -> Date? {
        // Excel stocke les dates comme nombre de jours depuis 1900
        if let days = Double(dateString) {
            // Excel epoch (1900-01-01)
            let excelEpoch = Date(timeIntervalSince1970: -2208988800)
            let secondsInDay: Double = 86400
            let timeInterval = days * secondsInDay
            return excelEpoch.addingTimeInterval(timeInterval)
        }
        return nil
    }
    
    private func cleanupText(_ text: String?) -> String? {
        return text?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n+", with: "\n", options: .regularExpression)
    }
}

// Extension pour faciliter l'utilisation
extension ExcelParser {
    // Méthode utilitaire pour vérifier si un fichier est un Excel
    static func isExcelFile(_ url: URL) -> Bool {
        return url.pathExtension.lowercased() == "xlsx"
    }
}
