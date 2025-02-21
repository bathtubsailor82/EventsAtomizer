//
//  OnlinePlatformDetails.swift
//  EventsAtomizer
//
//  Created by localadmin on 13/02/2025.
//

import Foundation
import SwiftData

@Model
final class OnlinePlatformDetails {
    // Configuration Options
    @Attribute var hasDocuments: Bool
    @Attribute var needsInterpreting: Bool
    @Attribute var connectionTestType: ConnectionTestType
    @Attribute var participantRange: ParticipantRange
    @Attribute var hasExistingLink: Bool  // Nouveau champ
    
    // Platform Specifics
    @Attribute var platformLink: String?
    @Attribute var meetingId: String?
    @Attribute var passcode: String?
    @Attribute var hostKey: String?
    @Attribute var comments: String?
    
    // Relationship
    @Relationship(inverse: \ServiceModel.onlinePlatformDetails) var service: ServiceModel?
    
    init(hasDocuments: Bool = false,
         needsInterpreting: Bool = false,
         connectionTestType: ConnectionTestType = .none,
         participantRange: ParticipantRange = .small,
         hasExistingLink: Bool = false,
         platformLink: String? = nil,
         meetingId: String? = nil,
         passcode: String? = nil,
         hostKey: String? = nil,
         comments: String? = nil) {
        self.hasDocuments = hasDocuments
        self.needsInterpreting = needsInterpreting
        self.connectionTestType = connectionTestType
        self.participantRange = participantRange
        self.hasExistingLink = hasExistingLink
        self.platformLink = platformLink
        self.meetingId = meetingId
        self.passcode = passcode
        self.hostKey = hostKey
        self.comments = comments
    }
}

// Enums pour les types spécifiques
enum ConnectionTestType: String, Codable {
    case none = "No test needed"
    case minutes15 = "15 minutes before"
    case minutes30 = "30 minutes before"
}

enum ParticipantRange: String, Codable {
    case small = "1-500"
    case large = "500+"
}
