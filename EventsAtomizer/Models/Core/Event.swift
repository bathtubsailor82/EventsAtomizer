//
//  Event.swift
//  EventsAtomizer
//
//  Created by localadmin on 27/01/2025.
//

import Foundation
import SwiftData

@Model
class Event {
    var id: String
    var eventID: String
    var name: String
    var status: String
    var secretariatContact: String
    var startDateTime: Date
    var endDateTime: Date
    var xmlLastUpdate: Date
    var localNotes: String?
    var localLastModified: Date
    var activeOptionIds: Set<String>
    
    @Relationship(deleteRule: .cascade) var options: [Option]
    @Relationship(deleteRule: .cascade) var services: [ServiceModel]
    
    init(id: String = "",
         eventID: String = "",
         name: String = "",
         status: String = "",
         secretariatContact: String = "") {
        self.id = id
        self.eventID = eventID
        self.name = name
        self.status = status
        self.secretariatContact = secretariatContact
        self.startDateTime = Date()
        self.endDateTime = Date()
        self.xmlLastUpdate = Date()
        self.localLastModified = Date()
        self.activeOptionIds = []
        self.options = []
        self.services = []
    }
}


extension Event {
    // Conversion de la date en format YYYYMMDD
    func formattedDateForRecording() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: self.startDateTime)
    }
}
