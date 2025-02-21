//
//  ServiceType.swift
//  EventsAtomizer
//
//  Created by localadmin on 13/02/2025.
//

import Foundation

// ServiceType.swift
enum ServiceType: String, Codable, CaseIterable {
    case audioVideoRecording = "Audio and Video recording"
    case onlinePlatform = "Online platform (Zoom or Kudo)"
    case soundSystem = "Sound system (official events)"
    case technicalSupport = "In room technical support"
    case other = "Other"
    
    static func fromXMLString(_ serviceTypeString: String) -> ServiceType {
        Self.allCases.first { serviceTypeString.contains($0.rawValue) } ?? .other
    }
}
