//
//  Option.swift
//  EventsAtomizer
//
//  Created by localadmin on 27/01/2025.
//


import Foundation
import SwiftData

@Model
class Option {
    // MARK: - Core Properties
    var id: String          // Part after / in ReadableId
    var isActive: Bool
    
    // MARK: - XML Imported Data
    var xmlLastUpdate: Date
    
    // MARK: - Local Data
    var localNotes: String?
    var localLastModified: Date
    
    // MARK: - Relationships
    @Relationship(inverse: \Event.options) var event: Event?
    @Relationship var venue: Venue?
    
    init(id: String = "", isActive: Bool = false) {
           self.id = id
           self.isActive = isActive
           self.xmlLastUpdate = Date()
           self.localLastModified = Date()
       }
    
}
