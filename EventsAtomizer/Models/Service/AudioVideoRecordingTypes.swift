//
//  AudioVideoRecording 2.swift
//  EventsAtomizer
//
//  Created by localadmin on 27/01/2025.
//

import Foundation
import SwiftUI


// Premièrement, on déplace StreamingPlatform dans AudioVideoRecording
enum AudioVideoRecording {
   

    // Status du service (from XML)
    enum Status: String, Codable, CaseIterable {
        case requested = "Requested"
        case beingProcessed = "Being Processed"
        case deliveryConfirmed = "Delivery Confirmed"
        case cancellationRequested = "Cancellation requested"
    }
    
    // Status de traitement local
    enum ProcessingStatus: String, Codable {
        case pending = "Pending"
        case inProgress = "In Progress"
        case completed = "Completed"
        case failed = "Failed"
        case cancelled = "Cancelled"
    }
    
    // Configuration audio/vidéo
    struct RecordingConfiguration: Codable {
           // Core features
           var isAudioOnly: Bool
           var isVideoRecording: Bool
           var isInternalUseOnly: Bool
           var isDownloadable: Bool
           var hasVOD: Bool
           var hasLivestream: Bool
           
           // Streaming configuration
           var streamingPlatforms: Set<StreamingPlatform>
           var streamingKey: String?
           
           // Languages configuration
           var audioOnlyLanguages: Set<String>
           var recordingLanguages: Set<String>
           var broadcastLanguages: Set<String>
           
           // Additional info
           var xmlComments: String?
           
           init(
               isAudioOnly: Bool,
               isVideoRecording: Bool = false,
               isInternalUseOnly: Bool = false,
               isDownloadable: Bool = false,
               hasVOD: Bool = false,
               hasLivestream: Bool = false,
               streamingPlatforms: Set<StreamingPlatform> = [],
               streamingKey: String? = nil,
               audioOnlyLanguages: Set<String> = [],
               recordingLanguages: Set<String> = [],
               broadcastLanguages: Set<String> = [],
               xmlComments: String? = nil
           ) {
               self.isAudioOnly = isAudioOnly
               self.isVideoRecording = isVideoRecording
               self.isInternalUseOnly = isInternalUseOnly
               self.isDownloadable = isDownloadable
               self.hasVOD = hasVOD
               self.hasLivestream = hasLivestream
               self.streamingPlatforms = streamingPlatforms
               self.streamingKey = streamingKey
               self.audioOnlyLanguages = audioOnlyLanguages
               self.recordingLanguages = recordingLanguages
               self.broadcastLanguages = broadcastLanguages
               self.xmlComments = xmlComments
           }
           
           // Helper pour obtenir toutes les langues uniques
           var allLanguages: Set<String> {
               audioOnlyLanguages
                   .union(recordingLanguages)
                   .union(broadcastLanguages)
           }
       }
    
    enum Constants {
        static let defaultProcessingStatus = ProcessingStatus.pending
        static let defaultLanguages: Set<String> = []
    }
    
    enum ServiceError: Error {
        case invalidConfiguration
        case invalidStatus
        case invalidLink
    }
}

