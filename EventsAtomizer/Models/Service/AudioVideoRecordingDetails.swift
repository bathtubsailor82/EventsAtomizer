//
//  AudioVideoRecordingDetails.swift
//  EventsAtomizer
//
//  Created by localadmin on 13/02/2025.
//

import Foundation
import SwiftData
import AppKit

@Model
final class AudioVideoRecordingDetails {
    // MARK: - Core Features
    @Attribute var isAudioOnly: Bool
    @Attribute var isVideoRecording: Bool
    @Attribute var isInternalUseOnly: Bool
    @Attribute var isDownloadable: Bool
    @Attribute var hasVOD: Bool
    @Attribute var hasLivestream: Bool
    
    // MARK: - Streaming Configuration
    @Attribute var streamingPlatforms: [String]
    @Attribute var streamingKey: String?
    
    // MARK: - Languages Configuration
    @Attribute var audioOnlyLanguages: Set<String>
    @Attribute var recordingLanguages: Set<String>
    @Attribute var broadcastLanguages: Set<String>
    
    // MARK: - Additional Information
    @Attribute var xmlComments: String?
    @Attribute private var processingStatusRawValue: String
    
    @Relationship(inverse: \ServiceModel.audioVideoDetails) var service: ServiceModel?
    
    var processingStatus: AudioVideoRecording.ProcessingStatus {
        get { AudioVideoRecording.ProcessingStatus(rawValue: processingStatusRawValue) ?? .pending }
        set { processingStatusRawValue = newValue.rawValue }
    }
    
    init(configuration: AudioVideoRecording.RecordingConfiguration) {
        // Core Features
        self.isAudioOnly = configuration.isAudioOnly
        self.isVideoRecording = configuration.isVideoRecording
        self.isInternalUseOnly = configuration.isInternalUseOnly
        self.isDownloadable = configuration.isDownloadable
        self.hasVOD = configuration.hasVOD
        self.hasLivestream = configuration.hasLivestream
        
        // Streaming Configuration
        self.streamingPlatforms = Array(configuration.streamingPlatforms.map { $0.rawValue })
        self.streamingKey = configuration.streamingKey
        
        // Languages Configuration
        self.audioOnlyLanguages = configuration.audioOnlyLanguages
        self.recordingLanguages = configuration.recordingLanguages
        self.broadcastLanguages = configuration.broadcastLanguages
        
        // Additional Information
        self.xmlComments = configuration.xmlComments
        self.processingStatusRawValue = AudioVideoRecording.ProcessingStatus.pending.rawValue
    }
    
    // MARK: - Helper Properties
    
    var streamingPlatformsEnum: Set<StreamingPlatform> {
        Set(streamingPlatforms.compactMap { StreamingPlatform(rawValue: $0) })
    }
    
    // Helper pour obtenir toutes les langues uniques
    var allLanguages: Set<String> {
        audioOnlyLanguages
            .union(recordingLanguages)
            .union(broadcastLanguages)
    }
    
    
    // Nouvelle computed property pour convertir les langues audio en ISO
    var audioOnlyLanguagesISO: [String] {
        return audioOnlyLanguages.compactMap { langCode in
            Language(rawValue: langCode)?.isoCode
        }
    }
    
    
    func generateDeliveryCommand(preferences: CommandPreferences? = nil) -> String {
        var command = "-c" // implicite ./ultimate-converter#.sh (version supportée 3+)
        
        // Room
        if let room = service?.venue?.getRecordingRoomCode() {
            command += " -room \(room)"
        }
        
        // Date
        if let event = service?.event {
            command += " -date \(event.formattedDateForRecording())"
        }
        
        // Taille minimale - configurable
        if preferences?.useSizeArg ?? true {
            command += " -size \(preferences?.sizeValue ?? "43M")"
        }
        
        // Sort - optionnel
        if preferences?.useSortArg ?? false {
            command += " -sort \(preferences?.sortValue ?? "time")"
        }
        
        // Langues - optionnel
        if preferences?.useLangArg ?? false {
            // Les langues de base qui doivent toujours être présentes
            let baseLanguages = Set([
                Language.original.isoCode,  // "or"
                Language.english.isoCode,   // "en"
                Language.french.isoCode     // "fr"
            ])
            
            // Ajouter les langues audio spécifiques qui ne sont pas déjà dans les langues de base
            var allLanguages = baseLanguages
            allLanguages.formUnion(audioOnlyLanguagesISO)
            
            // Ajouter à la commande (toujours trier pour avoir un ordre cohérent)
            let languagesStr = allLanguages.sorted().joined(separator: ",")
            command += " -lang \(languagesStr)"
        }
        
        // Event info - configurable
        if preferences?.useCustomEvent ?? false && !(preferences?.customEventValue.isEmpty ?? true) {
            command += " -event \"\(preferences?.customEventValue ?? "")\""
        } else if let event = self.service?.event {
            command += " -event \"\(event.id) \(event.name)\""
        }
        
        return command
    }
}

// Extension pour la configuration audio/vidéo
extension AudioVideoRecordingDetails {
    var audioConfig: AudioConfiguration {
        AudioConfiguration(
            isEnabled: isAudioOnly || isVideoRecording,
            recordingLanguages: Set(recordingLanguages.compactMap(Language.from)),
            streamingLanguages: Set(broadcastLanguages.compactMap(Language.from)),
            isInternalUseOnly: isInternalUseOnly,
            isDownloadable: isDownloadable,
            format: nil
        )
    }
    
    var videoConfig: VideoConfiguration {
        VideoConfiguration(
            isEnabled: isVideoRecording,
            recordingLanguages: Set(recordingLanguages.compactMap(Language.from)),
            streamingLanguages: Set(broadcastLanguages.compactMap(Language.from)),
            isInternalUseOnly: isInternalUseOnly,
            isDownloadable: isDownloadable,
            streamingPlatforms: [], // À implémenter en fonction des nouvelles données
            quality: nil
        )
    }
}


