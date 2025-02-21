//
//  LanguageBadge.swift
//  EventsAtomizer
//
//  Created by localadmin on 19/02/2025.
//

import SwiftUI

// Vue pour afficher un badge de langue
struct LanguageBadge: View {
    let language: Language
    var color: Color = .blue
    
    var body: some View {
        Text(language.rawValue)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .foregroundStyle(color)
            .cornerRadius(4)
    }
}

// Badge pour les langues non reconnues
struct UnknownLanguageBadge: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.gray.opacity(0.2))
            .foregroundStyle(Color.gray)
            .cornerRadius(4)
    }
}
