//
//  ServiceProtocol.swift
//  EventsAtomizer
//
//  Created by localadmin on 13/02/2025.
//

import Foundation

protocol ServiceProtocol {
    var id: String { get }
    var serviceType: ServiceType { get }
    var status: String { get }
    var xmlLastUpdate: Date { get }
    var eventId: String { get }
    var optionId: String { get }
    var localNotes: String? { get set }
    var localLastModified: Date { get set }
    
    // Relationships
    var event: Event? { get set }
    var venue: Venue? { get set }
}

struct CommonServiceData: Codable {
    var status: String
    var xmlLastUpdate: Date
    var localNotes: String?
    var localLastModified: Date
    var eventId: String
    var optionId: String
}
