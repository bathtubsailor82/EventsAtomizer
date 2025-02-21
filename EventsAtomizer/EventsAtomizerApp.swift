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
    let sharedModelContainer: ModelContainer = {
        // Définir le schéma
        let schema = Schema([
            ServiceModel.self,
            AudioVideoRecordingDetails.self,
            OnlinePlatformDetails.self,
            Event.self,
            Option.self,
            Venue.self
        ])
        
        // Configuration en mémoire pour le développement
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

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
    try await container.mainContext.delete(model: ServiceModel.self)
    try await container.mainContext.delete(model: AudioVideoRecordingDetails.self)
    try await container.mainContext.delete(model: OnlinePlatformDetails.self)
    try await container.mainContext.delete(model: Event.self)
    try await container.mainContext.delete(model: Option.self)
    try await container.mainContext.delete(model: Venue.self)
}
