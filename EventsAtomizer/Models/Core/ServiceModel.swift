//
//  ServiceModel.swift
//  EventsAtomizer
//
//  Created by localadmin on 13/02/2025.
//

// ServiceModel.swift
import Foundation
import SwiftData

@Model
final class ServiceModel {
    // MARK: - Core Properties
    @Attribute(.unique) var id: String
    @Attribute var serviceType: ServiceType
    
    // MARK: - Common Data
    @Attribute var status: String
    @Attribute var xmlLastUpdate: Date
    @Attribute var localNotes: String?
    @Attribute var localLastModified: Date
    @Attribute var eventId: String
    @Attribute var optionId: String
    @Attribute var serviceCard: String?  // Ajout de la serviceCard
    
    // MARK: - Relationships
    @Relationship(inverse: \Event.services) var event: Event?
    @Relationship(inverse: \Venue.services) var venue: Venue?
    
    // MARK: - Type-specific Details
    @Relationship(deleteRule: .cascade) var audioVideoDetails: AudioVideoRecordingDetails?
    @Relationship(deleteRule: .cascade) var onlinePlatformDetails: OnlinePlatformDetails?
    
    // MARK: - Initialization
    init(id: String,
         serviceType: ServiceType,
         commonData: CommonServiceData,
    serviceCard: String? = nil) {
        self.id = id
        self.serviceType = serviceType
        self.status = commonData.status
        self.xmlLastUpdate = commonData.xmlLastUpdate
        self.localNotes = commonData.localNotes
        self.localLastModified = commonData.localLastModified
        self.eventId = commonData.eventId
        self.optionId = commonData.optionId
        self.serviceCard = serviceCard  // Ajout de l'assignation
    }
    
    // MARK: - Convenience initializers for specific service types
    static func createAudioVideoService(
        id: String,
        commonData: CommonServiceData,
        configuration: AudioVideoRecording.RecordingConfiguration,
        serviceCard: String? = nil
    ) -> ServiceModel {
        let service = ServiceModel(
            id: id,
            serviceType: .audioVideoRecording,
            commonData: commonData,
            serviceCard: serviceCard  // Passage du paramètre
        )
        
        let details = AudioVideoRecordingDetails(configuration: configuration)
        service.audioVideoDetails = details
        
        return service
    }
    
    static func createOnlinePlatformService(
        id: String,
        commonData: CommonServiceData,
        hasDocuments: Bool = false,
        needsInterpreting: Bool = false,
        connectionTestType: ConnectionTestType = .none,
        participantRange: ParticipantRange = .small,
        hasExistingLink: Bool = false,  // Ajouté
        platformLink: String? = nil,
        meetingId: String? = nil,
        passcode: String? = nil,
        hostKey: String? = nil,
        comments: String? = nil,
        serviceCard: String? = nil
    ) -> ServiceModel {
        let service = ServiceModel(
            id: id,
            serviceType: .onlinePlatform,
            commonData: commonData,
            serviceCard: serviceCard
        )
        
        let details = OnlinePlatformDetails(
            hasDocuments: hasDocuments,
            needsInterpreting: needsInterpreting,
            connectionTestType: connectionTestType,
            participantRange: participantRange,
            hasExistingLink: hasExistingLink,  // Ajouté
            platformLink: platformLink,
            meetingId: meetingId,
            passcode: passcode,
            hostKey: hostKey,
            comments: comments
        )
        service.onlinePlatformDetails = details
        
        return service
    }
}
