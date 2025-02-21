//
//  StreamingPlatform.swift
//  EventsAtomizer
//
//  Created by localadmin on 19/02/2025.
//
import Foundation
import SwiftUI



enum StreamingPlatform: String, CaseIterable, Codable, Comparable {
    case youtube = "YouTube"
    case facebook = "Facebook"
    
    // Ajoutez cette méthode pour définir l'ordre de comparaison
        static func < (lhs: StreamingPlatform, rhs: StreamingPlatform) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
    
    var iconName: String {
        switch self {
        case .youtube: return "play.tv"
        case .facebook: return "video.badge.plus"
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .youtube: return Color.red.opacity(0.2)
        case .facebook: return Color.blue.opacity(0.2)
        }
    }
    
    var foregroundColor: Color {
        switch self {
        case .youtube: return .red
        case .facebook: return .blue
        }
    }
}


struct StreamingConfiguration {
    var platform: StreamingPlatform
    var streamKey: String?
    var streamURL: String?
    var isPrivate: Bool
}

struct AudioConfiguration {
    var isEnabled: Bool
    var recordingLanguages: Set<Language>
    var streamingLanguages: Set<Language>
    var isInternalUseOnly: Bool
    var isDownloadable: Bool
    var format: String? // Pour d'éventuels formats spécifiques
}

struct VideoConfiguration {
    var isEnabled: Bool
    var recordingLanguages: Set<Language>
    var streamingLanguages: Set<Language>
    var isInternalUseOnly: Bool
    var isDownloadable: Bool
    var streamingPlatforms: [StreamingConfiguration]
    var quality: String? // Pour d'éventuelles qualités spécifiques
}


// Vue pour le badge de plateforme de streaming
struct StreamingPlatformBadge: View {
    let platform: StreamingPlatform
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: platform.iconName)
            Text(platform.rawValue)
        }
        .font(.caption2)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(backgroundColor)
        .foregroundStyle(foregroundColor)
        .cornerRadius(4)
    }
    
    private var backgroundColor: Color {
        switch platform {
        case .youtube: return Color.red.opacity(0.2)
        case .facebook: return Color.blue.opacity(0.2)
        }
    }
    
    private var foregroundColor: Color {
        switch platform {
        case .youtube: return .red
        case .facebook: return .blue
        }
    }
}
