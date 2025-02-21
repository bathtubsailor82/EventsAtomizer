//
//  ServiceSortType.swift
//  EventsAtomizer
//
//  Created by localadmin on 18/02/2025.
//

import Foundation

enum ServiceSortType: String, CaseIterable, Decodable {
    case date = "Date"
    case eventNumber = "N° Event"
    case venue = "Salle"
    case eventName = "Nom"
    
    var image: String {
        switch self {
        case .date: return "calendar"
        case .eventNumber: return "number"
        case .venue: return "building.2"
        case .eventName: return "textformat"
        }
    }
}
