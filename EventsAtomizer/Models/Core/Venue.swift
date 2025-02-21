//
//  Venue.swift
//  EventsAtomizer
//
//  Created by localadmin on 27/01/2025.
//


import Foundation
import SwiftData

@Model
class Venue {
    // MARK: - Core Properties
    var id: String
    var name: String
    
    // MARK: - XML Imported Data
    var building: String
    var xmlLastUpdate: Date
    
    // MARK: - Local Data
    var localNotes: String?
    var localLastModified: Date
    
    // MARK: - Relationships
   
    @Relationship(deleteRule: .cascade) var services: [ServiceModel]
    
    init(id: String = "", name: String = "", building: String = "") {
        self.id = id
        self.name = name
        self.building = building
        self.xmlLastUpdate = Date()
        self.localLastModified = Date()
        self.services = []
    }
}

extension Venue {
    // Dictionnaire de correspondance salles <-> abréviations
    static let roomAbbreviations: [String: String] = [
        "Paris Room 1 (Paris Office)": "PAR01",
        "Paris Room 2 (Paris Office)": "PAR02",
        "G01 (Agora)": "AG01",
        "G02 (Agora)": "AG02",
        "G03 (Agora)": "AG03",
        "G04 (Agora)": "AG04",
        "G05 (Agora)": "AG05",
        "G06 (Agora)": "AG06",
        "Room 2 (Palais)": "P02",
        "Room 3 (Palais)": "P03",
        "Room 4 (Palais)": "P04",
        "Room 5 (Palais)": "P05",
        "Room 6 (Palais)": "P06",
        "Room 7 (Palais)": "P07",
        "Room 8 (Palais)": "P08",
        "Room 9 (Palais)": "P09",
        "Room 10 (Palais)": "P10",
        "Room 11 (Palais)": "P11",
        "Room 12 (Palais)": "P12",
        "Room 13 (Palais)": "P13",
        "Room 14 (Palais)": "P14",
        "Room 15 (Palais)": "P15",
        "Room 16 (Palais)": "P16",
        "Room 17 (Palais)": "P17",
        "Brussels Room" : "BRX",
        "Strasbourg Hemicycle" : "HEMI01",
        
        
        // Ajoutez d'autres correspondances ici
        "Default": "UNKNOWN"
    ]
    
    // Méthode pour récupérer l'abréviation
    func getRecordingRoomCode() -> String {
        return Venue.roomAbbreviations[self.name] ?? Venue.roomAbbreviations["Default"]!
    }
}
