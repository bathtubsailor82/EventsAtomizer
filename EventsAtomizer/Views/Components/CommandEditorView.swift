//
//  CommandEditorView.swift
//  EventsAtomizer
//
//  Created by localadmin on 11/04/2025.
//

import SwiftUI

struct CommandEditorView: View {
    let service: ServiceModel
    @State private var preferences = CommandPreferences()
    @State private var command: String = ""
    @State private var selectedLanguages: Set<Language> = []
    @Environment(\.modelContext) private var modelContext
    
    // Langues de base qui sont toujours disponibles
    private let baseLanguages: [Language] = [.original, .english, .french]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Affichage de la commande
            GroupBox("Delivery Command") {
                Text(command)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
                
                HStack {
                    Button("Reset to Default") {
                        resetToDefault()
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Button("Copier Commande") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(command, forType: .string)
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            // Éditeur de commande simplifié
            GroupBox("Command Editor") {
                VStack(alignment: .leading, spacing: 16) {
                    // Options avec contrôles directement visibles
                    HStack(spacing: 20) {
                        // Size argument
                        HStack {
                            Toggle("Size:", isOn: $preferences.useSizeArg)
                                .fixedSize()
                            TextField("Value", text: $preferences.sizeValue)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 80)
                                .disabled(!preferences.useSizeArg)
                        }
                        
                        // Sort argument
                        HStack {
                            Toggle("Sort:", isOn: $preferences.useSortArg)
                                .fixedSize()
                            Picker("", selection: $preferences.sortValue) {
                                Text("time").tag("time")
                                Text("name").tag("name")
                                Text("size").tag("size")
                            }
                            .frame(width: 80)
                            .disabled(!preferences.useSortArg)
                        }
                    }
                        // Languages avec sélecteur amélioré
                    // Section des langues
                    HStack(alignment: .center, spacing: 8) {
                        // Toggle pour activer/désactiver l'option lang
                        Toggle("Lang:", isOn: $preferences.useLangArg)
                            .fixedSize()
                        
                        if preferences.useLangArg {
                            // Menu pour sélectionner les langues
                            Menu {
                                ForEach(availableLanguages, id: \.self) { lang in
                                    Button(action: {
                                        // Sélectionner ou désélectionner cette langue
                                        if selectedLanguages.contains(lang) {
                                            selectedLanguages.remove(lang)
                                        } else {
                                            selectedLanguages.insert(lang)
                                        }
                                        updateCommand()
                                    }) {
                                        HStack {
                                            Text(lang.displayName)
                                            if selectedLanguages.contains(lang) {
                                                Spacer()
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    Text("\(selectedLanguages.count) selected")
                                    Image(systemName: "chevron.down")
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(4)
                            }
                            
                            // Affichage des badges de langues sélectionnées sur la même ligne
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 4) {
                                    ForEach(Array(selectedLanguages).prefix(5), id: \.self) { lang in
                                        LanguageBadge(language: lang)
                                    }
                                    
                                    // Afficher un indicateur s'il y a plus de langues
                                    if selectedLanguages.count > 5 {
                                        Text("+\(selectedLanguages.count - 5)")
                                            .font(.caption2)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.gray.opacity(0.2))
                                            .foregroundColor(.gray)
                                            .cornerRadius(4)
                                    }
                                }
                            }
                            .frame(height: 24)
                        }
                    
                    }
                    
                  
                    // Custom event
                    HStack {
                        Toggle("Custom Event:", isOn: $preferences.useCustomEvent)
                            .fixedSize()
                        TextField("Event Value", text: $preferences.customEventValue)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .disabled(!preferences.useCustomEvent)
                    }
                }
                .padding()
            }
        }
        .onAppear {
            loadPreferences()
            initializeLanguages()
            updateCommand()
        }
        .onChange(of: preferences.useSizeArg) { _, _ in updateCommand() }
        .onChange(of: preferences.sizeValue) { _, _ in updateCommand() }
        .onChange(of: preferences.useSortArg) { _, _ in updateCommand() }
        .onChange(of: preferences.sortValue) { _, _ in updateCommand() }
        .onChange(of: preferences.useLangArg) { _, _ in updateCommand() }
        .onChange(of: preferences.useCustomEvent) { _, _ in updateCommand() }
        .onChange(of: preferences.customEventValue) { _, _ in updateCommand() }
        .padding()
    }
    
    // Obtenir toutes les langues disponibles pour ce service
    private var availableLanguages: [Language] {
        var languages = Set(baseLanguages)
        
        // Ajouter les langues du service
        if let details = service.audioVideoDetails {
            for langCode in details.audioOnlyLanguages {
                if let lang = Language(rawValue: langCode) {
                    languages.insert(lang)
                }
            }
            
            for langCode in details.recordingLanguages {
                if let lang = Language(rawValue: langCode) {
                    languages.insert(lang)
                }
            }
            
            for langCode in details.broadcastLanguages {
                if let lang = Language(rawValue: langCode) {
                    languages.insert(lang)
                }
            }
        }
        
        // Convertir en tableau et trier
        return Array(languages).sorted(by: { $0.displayName < $1.displayName })
    }
    
    private func initializeLanguages() {
        // Par défaut, sélectionner toutes les langues disponibles
        selectedLanguages = Set(availableLanguages)
    }
    
    private func updateCommand() {
        var cmd = "-c"
        
        // Paramètres fixes
        if let room = service.venue?.getRecordingRoomCode() {
            cmd += " -room \(room)"
        }
        
        if let date = service.event?.formattedDateForRecording() {
            cmd += " -date \(date)"
        }
        
        // Paramètres éditables
        if preferences.useSizeArg {
            cmd += " -size \(preferences.sizeValue)"
        }
        
        if preferences.useSortArg {
            cmd += " -sort \(preferences.sortValue)"
        }
        
        if preferences.useLangArg && !selectedLanguages.isEmpty {
            // Convertir les langues sélectionnées en codes ISO
            let isoCodes = selectedLanguages.map { $0.isoCode }
            let langString = isoCodes.sorted().joined(separator: ",")
            cmd += " -lang \(langString)"
        }
        
        // Event (custom ou par défaut)
        if preferences.useCustomEvent && !preferences.customEventValue.isEmpty {
            cmd += " -event \"\(preferences.customEventValue)\""
        } else if let event = service.event {
            cmd += " -event \"\(event.id) \(event.name)\""
        }
        
        command = cmd
    }
    
    private func resetToDefault() {
        preferences = CommandPreferences()
        initializeLanguages()
        updateCommand()
    }
    
    private func loadPreferences() {
        // Initialisation avec les valeurs par défaut
        if let event = service.event {
            preferences.customEventValue = "\(event.id) \(event.name)"
        }
    }
}


// MARK: - Preview
// MARK: - Preview
#Preview {
    // On crée une version simulée pour la prévisualisation
    struct MockServiceModel: View {
        var body: some View {
            CommandEditorView(service: createMockService())
                .frame(width: 600, height: 500)
                .padding()
        }
        
        // Création d'un service fictif pour la prévisualisation
        private func createMockService() -> ServiceModel {
            let mockEvent = Event(id: "70300/70301", eventID: "70300", name: "4th meeting of the CDDH-IA")
            let mockVenue = Venue(id: "G02", name: "G02 (Agora)")
            
            // Configuration de base
            let commonData = CommonServiceData(
                status: "Being Processed",
                xmlLastUpdate: Date(),
                localNotes: nil,
                localLastModified: Date(),
                eventId: "70300/70301",
                optionId: "70301"
            )
            
            // Création du service sans contexte SwiftData
            let service = ServiceModel(
                id: "mock-service",
                serviceType: .audioVideoRecording,
                commonData: commonData
            )
            
            // Assigner manuellement les propriétés
            service.event = mockEvent
            service.venue = mockVenue
            
            // Création des détails audio/vidéo manuellement
            let details = AudioVideoRecordingDetails(configuration:
                AudioVideoRecording.RecordingConfiguration(
                    isAudioOnly: true,
                    isVideoRecording: true,
                    isInternalUseOnly: false,
                    isDownloadable: true,
                    hasVOD: true,
                    hasLivestream: false,
                    streamingPlatforms: [.youtube],
                    audioOnlyLanguages: ["FRA", "ENG"],
                    recordingLanguages: ["FRA", "ENG", "DEU"],
                    broadcastLanguages: ["FRA", "ENG"]
                )
            )
            
            service.audioVideoDetails = details
            
            return service
        }
    }
    
    return MockServiceModel()
}

