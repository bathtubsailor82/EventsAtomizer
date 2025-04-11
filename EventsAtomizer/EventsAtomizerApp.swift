//
//  EventsAtomizerApp.swift
//  EventsAtomizer
//
//  Created by localadmin on 24/01/2025.
//

import SwiftUI
import SwiftData

@main
struct EventsAtomizerApp: App {
    // Dans EventsAtomizerApp.swift
    let sharedModelContainer: ModelContainer = {
        // Définir le schéma
        let schema = Schema([
            ServiceModel.self,
            AudioVideoRecordingDetails.self,
            OnlinePlatformDetails.self,
            Event.self,
            Option.self,
            Venue.self,
            CommandPreferences.self
        ])
        
        // Configuration pour macOS 14.x
        // Utiliser uniquement les paramètres disponibles
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true  // Garde seulement les paramètres existants
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            // Nettoyer les données au démarrage
            Task { @MainActor in
                try? await wipeAllData(in: container)
            }
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainThreeColumnView()
        }
        .modelContainer(sharedModelContainer)
    }
}

@MainActor
func wipeAllData(in container: ModelContainer) async throws {
    // Supprimer tous les services d'abord (à cause des relations)
    try container.mainContext.delete(model: ServiceModel.self)
    try container.mainContext.delete(model: AudioVideoRecordingDetails.self)
    try container.mainContext.delete(model: OnlinePlatformDetails.self)
    try container.mainContext.delete(model: Event.self)
    try container.mainContext.delete(model: Option.self)
    try container.mainContext.delete(model: Venue.self)
}
