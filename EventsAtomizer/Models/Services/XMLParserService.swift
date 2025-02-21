//
//  ParsedEntry.swift
//  EventsAtomizer
//
//  Created by localadmin on 28/01/2025.
//


import Foundation
import SwiftData

struct ParsedEntry: Equatable {
    let readableId: String
    let eventName: String
    let eventStatus: String
    let contactName: String
    let startDate: Date
    let endDate: Date
    let venue: String
    let serviceId: String
    let serviceType: String
    let serviceCard: String
    let serviceStatus: String
}

class ServiceXMLParser: NSObject, XMLParserDelegate {
    private var currentElement = ""
    private var currentEntry: [String: String] = [:]
    private var entries: [ParsedEntry] = []
    private var dateFormatter: DateFormatter
    
    override init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        super.init()
    }
    
    func parse(xmlData: Data) -> [ParsedEntry] {
        entries.removeAll()
        let parser = XMLParser(data: xmlData)
        parser.delegate = self
        parser.parse()
        return entries
    }
    
    // MARK: - XMLParserDelegate
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        if elementName == "Details" {
            currentEntry = attributeDict
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "Details" {
            if let entry = createParsedEntry(from: currentEntry) {
                entries.append(entry)
            }
            currentEntry.removeAll()
        }
    }
    
    private func createParsedEntry(from dict: [String: String]) -> ParsedEntry? {
        guard let readableId = dict["ReadableId"],
              let eventName = dict["EventName"],
              let eventStatus = dict["EventStatus"],
              let contactName = dict["EventSecretariatContact"],
              let startDateStr = dict["StartDateTime"],
              let endDateStr = dict["EndDateTim"],
              let venue = dict["Venue"],
              let serviceId = dict["IdService"],
              let serviceType = dict["ServiceType"],
              let serviceCard = dict["ServiceCard"],
              let serviceStatus = dict["Status"],
              let startDate = dateFormatter.date(from: startDateStr),
              let endDate = dateFormatter.date(from: endDateStr) else {
            return nil
        }
        
        return ParsedEntry(
            readableId: readableId,
            eventName: eventName.trimmingCharacters(in: .whitespacesAndNewlines),
            eventStatus: eventStatus,
            contactName: contactName.trimmingCharacters(in: .whitespacesAndNewlines),
            startDate: startDate,
            endDate: endDate,
            venue: venue,
            serviceId: serviceId,
            serviceType: serviceType,
            serviceCard: serviceCard.trimmingCharacters(in: .whitespacesAndNewlines),
            serviceStatus: serviceStatus
        )
    }
}

// MARK: - SwiftData Model Conversion
extension ParsedEntry {
    func toSwiftDataModels(context: ModelContext) -> (Event, Option, ServiceModel) {
        // 1. Créer ou récupérer l'Event
        let event = Event()
        event.id = readableId
        event.name = eventName
        event.status = eventStatus
        event.secretariatContact = contactName
        event.startDateTime = startDate
        event.endDateTime = endDate
        
        // 2. Créer ou récupérer la Venue
        let venueModel = Venue(id: venue, name: venue, building: "")
        
        // 3. Créer l'Option
        let option = Option()
        option.id = readableId.split(separator: "/").last?.description ?? ""
        option.isActive = true
        option.event = event
        option.venue = venueModel  // Lier l'option à la venue
        
        // 4. Préparer les données communes
        let commonData = CommonServiceData(
            status: serviceStatus,
            xmlLastUpdate: Date(),
            localNotes: nil,
            localLastModified: Date(),
            eventId: readableId,
            optionId: option.id
        )
        
        // 5. Créer le service selon son type
        let service: ServiceModel
        
        switch ServiceType.fromXMLString(serviceType) {
        case .audioVideoRecording:
            let config = parseAudioVideoConfiguration(from: serviceCard)
            service = ServiceModel.createAudioVideoService(
                id: serviceId,
                commonData: commonData,
                configuration: config,
                serviceCard: serviceCard
            )
            
        case .onlinePlatform:
            let details = parseOnlinePlatformDetails(from: serviceCard)
            service = ServiceModel.createOnlinePlatformService(
                id: serviceId,
                commonData: commonData,
                hasDocuments: details.hasDocuments,
                needsInterpreting: details.needsInterpreting,
                connectionTestType: details.connectionTestType,
                participantRange: details.participantRange,
                hasExistingLink: details.hasExistingLink,
                platformLink: details.platformLink,
                meetingId: details.meetingId,
                passcode: details.passcode,
                hostKey: details.hostKey,
                comments: details.comments,
                serviceCard: serviceCard
            )
            
        default:
                    service = ServiceModel(
                        id: serviceId,
                        serviceType: ServiceType.fromXMLString(serviceType),
                        commonData: commonData,
                        serviceCard: serviceCard
                    )
                }
        
        // 6. Établir les relations
        service.event = event
        service.venue = venueModel  // Important : Lier le service à la venue
        
        // 7. Insérer la venue dans le contexte
        context.insert(venueModel)
        
        return (event, option, service)
    }
}

// MARK: - Service Configuration Parsing
private func parseAudioVideoConfiguration(from serviceCard: String) -> AudioVideoRecording.RecordingConfiguration {
    print("Starting to parse Audio Video configuration")
    
    let cleanedCard = serviceCard
        .replacingOccurrences(of: "&#xD;&#xA;", with: "\n")
        .replacingOccurrences(of: "&#x9;", with: "\t")
        .trimmingCharacters(in: .whitespacesAndNewlines)
    
    print("Cleaned service card:\n\(cleanedCard)")
    
    var config = ConfigurationData()
    
    // First pass: detect all services
    if cleanedCard.contains("Audio only recording") {
        config.isAudioOnly = true
        if cleanedCard.contains("CoE internal use only") {
            config.isInternalUseOnly = true
        }
    }
    
    if cleanedCard.contains("Video recording (VOD)") {
        config.hasVOD = true
        config.isVideoRecording = true
        if cleanedCard.contains("Downloadable video") {
            config.isDownloadable = true
        }
    }
    
    if cleanedCard.contains("Livestream/broadcasting") {
        config.hasLivestream = true
        config.isVideoRecording = true
        
        // Detect platforms
        if cleanedCard.contains("Facebook") {
            config.streamingPlatforms.insert(.facebook)
        }
        if cleanedCard.contains("YouTube") {
            config.streamingPlatforms.insert(.youtube)
        }
    }
    
    // Second pass: find all language specifications by context
    let sections = cleanedCard.components(separatedBy: "\n\n")
    
    for section in sections {
        let lines = section.components(separatedBy: .newlines)
        
        // Determine the context of this section
        let isAudioOnlySection = section.contains("Audio only recording")
        let isVODSection = section.contains("Video recording (VOD)")
        let isLivestreamSection = section.contains("Livestream/broadcasting")
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            if trimmedLine.contains("Languages to be recorded") {
                let languages = parseLanguagesFromLine(trimmedLine)
                print("Found languages in recording: \(languages)")
                
                if isAudioOnlySection {
                    print("Adding to audio only languages")
                    config.audioOnlyLanguages.formUnion(languages)
                }
                if isVODSection {
                    print("Adding to recording languages")
                    config.recordingLanguages.formUnion(languages)
                }
            }
            
            if trimmedLine.contains("Languages to be broadcasted") {
                let languages = parseLanguagesFromLine(trimmedLine)
                print("Found languages in broadcasting: \(languages)")
                config.broadcastLanguages.formUnion(languages)
            }
            
            // Store the line as a comment
            if !trimmedLine.isEmpty {
                config.xmlComments.append(trimmedLine)
            }
        }
    }
    
    print("Final configuration:")
    print("Services detected:")
    print("- Audio Only: \(config.isAudioOnly)")
    print("- Video Recording: \(config.isVideoRecording)")
    print("- VOD: \(config.hasVOD)")
    print("- Livestream: \(config.hasLivestream)")
    print("\nLanguages detected:")
    print("- Audio Only: \(config.audioOnlyLanguages)")
    print("- Recording: \(config.recordingLanguages)")
    print("- Broadcasting: \(config.broadcastLanguages)")
    
    return config.toRecordingConfiguration()
}

private func parseLanguagesFromLine(_ line: String) -> Set<String> {
    print("Parsing language line: \(line)")
    
    var languages = Set<String>()
    
    // Add original if mentioned
    if line.contains("in addition to the original") {
        languages.insert(Language.original.rawValue)
        print("Added original language")
    }
    
    // Get language text after ":"
    if let languagesPart = line.split(separator: ":").last?.trimmingCharacters(in: .whitespaces) {
        print("Language part: '\(languagesPart)'")
        
        // Split by "/" and clean each language
        languagesPart.split(separator: "/").forEach { langPart in
            let cleanLang = langPart.trimmingCharacters(in: .whitespaces)
            print("Processing language: '\(cleanLang)'")
            
            switch cleanLang.lowercased() {
            case "french", "français", "francais":
                languages.insert(Language.french.rawValue)
                print("Added French (FRA)")
            case "english", "anglais":
                languages.insert(Language.english.rawValue)
                print("Added English (ENG)")
            default:
                if let language = Language.from(string: cleanLang) {
                    languages.insert(language.rawValue)
                    print("Added language via from(): \(language.rawValue)")
                } else {
                    print("Could not parse language: \(cleanLang)")
                }
            }
        }
    }
    
    print("Final languages for line: \(languages)")
    return languages
}



// Mise à jour des fonctions de parsing spécifiques avec logging
private func parseAudioSection(lines: [String], config: inout ConfigurationData) {
    print("Parsing audio section details:")
    config.isAudioOnly = true
    
    for line in lines {
        let trimmedLine = line.trimmingCharacters(in: .whitespaces)
        print("Processing line: \(trimmedLine)")
        
        if trimmedLine.contains("CoE internal use only") {
            config.isInternalUseOnly = true
            print("Set internal use only")
        }
        
        if trimmedLine.contains("Languages to be recorded") {
            if let languages = parseSectionLanguages(line: trimmedLine) {
                config.recordingLanguages.formUnion(languages)
                print("Added recording languages: \(languages)")
            }
        }
        
        config.xmlComments.append(trimmedLine)
    }
}



private struct ConfigurationData {
    // Core features
    var isAudioOnly = false
    var isVideoRecording = false
    var isInternalUseOnly = false
    var isDownloadable = false
    var hasVOD = false
    var hasLivestream = false
    
    // Streaming configuration
    var streamingPlatforms = Set<StreamingPlatform>()
    var streamingKey: String?
    
    // Languages configuration
    var audioOnlyLanguages: Set<String> = []
    var recordingLanguages: Set<String> = []
    var broadcastLanguages: Set<String> = []
    
    // Additional info
    var xmlComments = [String]()
    
    func toRecordingConfiguration() -> AudioVideoRecording.RecordingConfiguration {
        return AudioVideoRecording.RecordingConfiguration(
            isAudioOnly: isAudioOnly,
            isVideoRecording: isVideoRecording,
            isInternalUseOnly: isInternalUseOnly,
            isDownloadable: isDownloadable,
            hasVOD: hasVOD,
            hasLivestream: hasLivestream,
            streamingPlatforms: streamingPlatforms,
            streamingKey: streamingKey,
            audioOnlyLanguages: audioOnlyLanguages,
            recordingLanguages: recordingLanguages,
            broadcastLanguages: broadcastLanguages,
            xmlComments: xmlComments.joined(separator: "\n")
        )
    }
}

private func parseStreamingSection(lines: [String], config: inout ConfigurationData) {
    config.hasLivestream = true
    config.isVideoRecording = true
    
    for line in lines {
        let trimmedLine = line.trimmingCharacters(in: .whitespaces)
        config.xmlComments.append(trimmedLine)
        
        if trimmedLine.contains("streaming key") {
            config.streamingKey = trimmedLine.split(separator: ":")
                .last?
                .trimmingCharacters(in: .whitespaces)
        }
        
        if trimmedLine.contains("Languages to be broadcasted") {
            if let languages = parseSectionLanguages(line: trimmedLine) {
                config.broadcastLanguages.formUnion(languages)
            }
        }
        
    
        // Détecter les plateformes
        if trimmedLine.contains("Facebook") {
            config.streamingPlatforms.insert(.facebook)
        }
        if trimmedLine.contains("YouTube") {
            config.streamingPlatforms.insert(.youtube)
        }
    }
}

private func parseVODSection(lines: [String], config: inout ConfigurationData) {
    config.hasVOD = true
    config.isVideoRecording = true
    
    for line in lines {
        let trimmedLine = line.trimmingCharacters(in: .whitespaces)
        config.xmlComments.append(trimmedLine)
        
        if trimmedLine.contains("Downloadable") {
            config.isDownloadable = true
        }
    }
}

private func parseSectionLanguages(line: String) -> Set<String>? {
    var languages = Set<String>()
    
    // Ajouter la langue originale si mentionnée
    if line.contains("in addition to the original") {
        languages.insert(Language.original.rawValue)
    }
    
    // Parser les langues listées
    if let languagesStr = line.split(separator: ":").last {
        let languagesList = languagesStr.split { $0 == "/" || $0 == "," }
        for lang in languagesList {
            let cleanLang = lang.trimmingCharacters(in: .whitespaces)
            if let language = Language.from(string: cleanLang) {
                languages.insert(language.rawValue)
            } else if !cleanLang.isEmpty {
                languages.insert(cleanLang)
            }
        }
    }
    
    return languages
}

private func parseCommonConfig(line: String, config: inout ConfigurationData) {
    let trimmedLine = line.trimmingCharacters(in: .whitespaces)
    config.xmlComments.append(trimmedLine)
}

private func parseOnlinePlatformConfiguration(from serviceCard: String) -> (hasDocuments: Bool, needsInterpreting: Bool, needsConnectionTest: Bool, participantCount: Int) {
    let hasDocuments = serviceCard.contains("I have documents/videos that I would like to show to the participants")
    let needsInterpreting = serviceCard.contains("I have requested interpreting services")
    let needsConnectionTest = serviceCard.contains("connection test session")
    
    let participantCount: Int
    if serviceCard.contains("More than 500") {
        participantCount = 501
    } else if serviceCard.contains("From 1 to 500") {
        participantCount = 500
    } else {
        participantCount = 0
    }
    
    return (hasDocuments, needsInterpreting, needsConnectionTest, participantCount)
}


extension ParsedEntry {
    func parseOnlinePlatformDetails(from serviceCard: String) -> OnlinePlatformDetails {
        // 1. Nettoyage et normalisation du texte
        let cleanedCard = serviceCard
            .replacingOccurrences(of: "&#xD;&#xA;", with: "\n")
            .replacingOccurrences(of: "&#x9;", with: "\t")
            .replacingOccurrences(of: ": :", with: ":")  // Normaliser les doubles séparateurs
        
        var hasDocuments = false
        var needsInterpreting = false
        var connectionTestType: ConnectionTestType = .none
        var participantRange: ParticipantRange = .small
        var hasExistingLink = false
        var platformLink: String?
        var meetingId: String?
        var passcode: String?
        var hostKey: String?
        var comments: String?
        
        // 2. Découper en sections pour un meilleur parsing
        let sections = cleanedCard.components(separatedBy: "\n\n")
        
        // 3. Parser chaque ligne
        for section in sections {
            let lines = section.components(separatedBy: .newlines)
            
            for line in lines {
                let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
             //   print("Parsing line: \(trimmedLine)") // Debug
                
                // 4. Configuration de base
                if trimmedLine.contains("documents/videos that I would like to show") {
                    hasDocuments = trimmedLine.localizedCaseInsensitiveContains(": Yes")
                }
                else if trimmedLine.contains("interpreting services") {
                    needsInterpreting = trimmedLine.localizedCaseInsensitiveContains(": Yes")
                }
                else if trimmedLine.contains("connection test session") {
                    if trimmedLine.contains("15 minutes before") {
                        connectionTestType = .minutes15
                    } else if trimmedLine.contains("30 minutes before") {
                        connectionTestType = .minutes30
                    }
                }
                else if trimmedLine.contains("number of online participants") {
                    participantRange = trimmedLine.contains("More than 500") ? .large : .small
                }
                
                // 5. Détection du lien existant
                if trimmedLine.localizedCaseInsensitiveContains("already have a link") ||
                   trimmedLine.localizedCaseInsensitiveContains("existing link") {
                    hasExistingLink = true
                    continue
                }
                
                // 6. Extraction des informations de plateforme
                // Utiliser des patterns plus flexibles pour la détection
                let patterns = [
                    "Link:": { str in platformLink = str },
                    "Link :": { str in platformLink = str },
                    "Meeting ID:": { str in meetingId = str },
                    "Meeting ID :": { str in meetingId = str },
                    "Passcode:": { str in passcode = str },
                    "Passcode :": { str in passcode = str },
                    "Host key:": { str in hostKey = str },
                    "Host key :": { str in hostKey = str },
                    "Comments:": { str in comments = str },
                    "Comments :": { str in comments = str }
                ]
                
                for (pattern, setter) in patterns {
                    if trimmedLine.starts(with: pattern) {
                        let value = trimmedLine
                            .replacingOccurrences(of: pattern, with: "")
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        if !value.isEmpty {
                            setter(value)
                            
                            // Si on trouve un lien ou un meeting ID, on considère qu'il y a un lien existant
                            if pattern.contains("Link") || pattern.contains("Meeting ID") {
                                hasExistingLink = true
                            }
                        }
                    }
                }
            }
        }
        
//        // 7. Debug logging
//        print("""
//        Parsed Platform Details:
//        - hasDocuments: \(hasDocuments)
//        - needsInterpreting: \(needsInterpreting)
//        - connectionTestType: \(connectionTestType)
//        - participantRange: \(participantRange)
//        - hasExistingLink: \(hasExistingLink)
//        - platformLink: \(platformLink ?? "nil")
//        - meetingId: \(meetingId ?? "nil")
//        - passcode: \(passcode ?? "nil")
//        - hostKey: \(hostKey ?? "nil")
//        """)
        
        return OnlinePlatformDetails(
            hasDocuments: hasDocuments,
            needsInterpreting: needsInterpreting,
            connectionTestType: connectionTestType,
            participantRange: participantRange,
            hasExistingLink: hasExistingLink,
            platformLink: platformLink,
            meetingId: meetingId,
            passcode: passcode,
            hostKey: hostKey,
            comments: comments
        )
    }
}
