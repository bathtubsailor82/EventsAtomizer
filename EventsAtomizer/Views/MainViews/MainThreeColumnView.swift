//
//  MainThreeColumnView.swift
//  EventsAtomizer
//
//  Created by localadmin on 28/01/2025.
//


import SwiftUI
import SwiftData
import WebKit
import AppKit

struct MainThreeColumnView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var services: [ServiceModel]
    @State private var selectedService: ServiceModel?
    @State public var filterText = ""
    @State public var selectedServiceType: ServiceType?
    @State public var selectedStatus: String?
    @State public var sortType: ServiceSortType = .date
    @State public var sortAscending = false
    @State private var showXMLDownload = false
    
    @State private var showExportOptions = false
    @State private var exportError: String?
    
    var filteredAndSortedServices: [ServiceModel] {
        var result = services.filter { service in
            let matchesText = filterText.isEmpty ||
            service.event?.name.localizedCaseInsensitiveContains(filterText) == true ||
            service.eventId.localizedCaseInsensitiveContains(filterText) == true
            let matchesType = selectedServiceType == nil || service.serviceType == selectedServiceType
            let matchesStatus = selectedStatus == nil || service.status == selectedStatus
            return matchesText && matchesType && matchesStatus
        }
        
        result.sort { first, second in
            let comparison: Bool
            switch sortType {
            case .date:
                comparison = (first.event?.startDateTime ?? .distantPast) < (second.event?.startDateTime ?? .distantPast)
            case .eventNumber:
                comparison = first.eventId < second.eventId
            case .venue:
                comparison = (first.venue?.name ?? "") < (second.venue?.name ?? "")
            case .eventName:
                comparison = (first.event?.name ?? "") < (second.event?.name ?? "")
            }
            return sortAscending ? comparison : !comparison
        }
        
        return result
    }
    
    
    
    var body: some View {
        NavigationSplitView {
            // Colonne de gauche
            VStack {
                ImportToolsView()
                    .padding()
                
                FilterSidebarView(
                    filterText: $filterText,
                    selectedServiceType: $selectedServiceType,
                    selectedStatus: $selectedStatus
                )
            }
            .frame(minWidth: 250)
            
                    
            
        } content: {
            // Colonne du milieu
            ServiceListView(
                services: filteredAndSortedServices,
                selectedService: $selectedService,
                sortType: $sortType,
                sortAscending: $sortAscending
            )
            .frame(minWidth: 300)
            
        } detail: {
            // Colonne de droite
            if let selectedService {
                ServiceDetailView(service: selectedService)
                    .frame(minWidth: 400)
            } else {
                Text("Sélectionnez un service")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

struct FilterSidebarView: View {
    @Binding var filterText: String
    @Binding var selectedServiceType: ServiceType?
    @Binding var selectedStatus: String?
    
    // Liste des status possibles
    let statusOptions = ["Requested", "Being Processed", "Delivery Confirmed", "Cancellation requested"]
    
    var body: some View {
        List {
            Section("Filtres") {
                TextField("Rechercher...", text: $filterText)
                    .textFieldStyle(.roundedBorder)
                
                Picker("Type de service", selection: $selectedServiceType) {
                    Text("Tous")
                        .tag(Optional<ServiceType>.none)
                    ForEach(ServiceType.allCases, id: \.self) { type in
                        Text(type.rawValue)
                            .tag(Optional(type))
                    }
                }
                
                Picker("Status", selection: $selectedStatus) {
                    Text("Tous")
                        .tag(Optional<String>.none)
                    ForEach(statusOptions, id: \.self) { status in
                        Text(status)
                            .tag(Optional(status))
                    }
                }
            }
        }
    }
}

struct ServiceListView: View {
    let services: [ServiceModel]
    @Binding var selectedService: ServiceModel?
    @Binding var sortType: ServiceSortType
    @Binding var sortAscending: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            ServiceListHeaderView(sortType: $sortType, sortAscending: $sortAscending)
            
            List(services, selection: $selectedService) { service in
                ServiceRowView(service: service)
                    .tag(service)
            }
        }
    }
}

// Badge générique réutilisable
struct ServiceBadge: View {
    let text: String
    let isEnabled: Bool
    var color: Color = .blue
    
    var body: some View {
        Text(text)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(isEnabled ? color.opacity(0.2) : .gray.opacity(0.1))
            .foregroundStyle(isEnabled ? color : .gray)
            .cornerRadius(4)
    }
}

struct ServiceRowView: View {
    let service: ServiceModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Titre et date
            HStack {
                VStack(alignment: .leading) {
                    Text(service.event?.name ?? "Inconnu")
                        .font(.headline)
                        .lineLimit(1)
                    Text(service.eventId)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let date = service.event?.startDateTime {
                    Text(date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Lieu et Status
            HStack {
                if let venue = service.venue?.name {
                    Text(venue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(service.status)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor)
                    .cornerRadius(4)
            }
            
            // Badges spécifiques au type de service
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    switch service.serviceType {
                    case .audioVideoRecording:
                        if let details = service.audioVideoDetails {
                            ServiceBadge(text: "Audio", isEnabled: details.isAudioOnly, color: .blue)
                            ServiceBadge(text: "Vidéo", isEnabled: details.isVideoRecording, color: .purple)
                            ServiceBadge(text: "Interne", isEnabled: details.isInternalUseOnly, color: .orange)
                            ServiceBadge(text: "DL", isEnabled: details.isDownloadable, color: .green)
                        }
                        
                    case .onlinePlatform:
                        if let details = service.onlinePlatformDetails {
                            HStack(spacing: 4) {
                                ServiceBadge(text: "Docs",
                                             isEnabled: details.hasDocuments,
                                             color: .blue)
                                ServiceBadge(text: "Interp",
                                             isEnabled: details.needsInterpreting,
                                             color: .orange)
                                if details.connectionTestType != .none {
                                    ServiceBadge(text: "Test",
                                                 isEnabled: true,
                                                 color: .green)
                                }
                                ServiceBadge(text: details.participantRange.rawValue,
                                             isEnabled: true,
                                             color: details.participantRange == .large ? .red : .green)
                                if details.hasExistingLink {
                                    ServiceBadge(text: "Link ✓",
                                                 isEnabled: true,
                                                 color: .purple)
                                }
                            }
                        }
                        
                        
                    default:
                        EmptyView()
                    }
                }
            }
            .padding(.top, 2)
        }
        .padding(.vertical, 4)
    }
    
    private var statusColor: Color {
        switch service.status {
        case "Requested":
            return Color.yellow.opacity(0.3)
        case "Being Processed":
            return Color.blue.opacity(0.3)
        case "Delivery Confirmed":
            return Color.green.opacity(0.3)
        case "Cancellation requested":
            return Color.red.opacity(0.3)
        default:
            return Color.gray.opacity(0.3)
        }
    }
}

struct ServiceDetailView: View {
    let service: ServiceModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // En-tête
                VStack(alignment: .leading) {
                    Text(service.event?.name ?? "")
                        .font(.title)
                    HStack {
                        if let date = service.event?.startDateTime {
                            Text(date.formatted(date: .long, time: .shortened))
                                .foregroundStyle(.secondary)
                        }
                        if let date = service.event?.endDateTime {
                            Text(date.formatted(date: .long, time: .shortened))
                                .foregroundStyle(.secondary)
                        }
                        
                    }
                    if let venue = service.venue?.name {
                        HStack {
                            Image(systemName: "building.2")
                            Text(venue)
                        }
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                    }
                }
                
                // Informations de base
                GroupBox("Informations") {
                    InfoRow(label: "EventID", value: service.eventId)
                    InfoRow(label: "Status", value: service.status)
                    InfoRow(label: "Type", value: service.serviceType.rawValue)
                    InfoRow(label: "ID", value: service.id)
                    InfoRow(label: "Venue", value: service.venue?.name ?? "n/a")
                    
                }
                .textSelection(.enabled)
                
                // Détails spécifiques selon le type
                switch service.serviceType {
                case .audioVideoRecording:
                    if let details = service.audioVideoDetails {
                        AudioVideoDetailView(details: details, service: service)
                    }
                    
                case .onlinePlatform:
                    if let details = service.onlinePlatformDetails {
                        OnlinePlatformDetailView(details: details)
                    }
                    
                default:
                    EmptyView()
                }
                
                // Notes locales
                if let notes = service.localNotes {
                    GroupBox("Notes") {
                        Text(notes)
                    }
                }
                
                // Service Card brute (ajoutée AVANT les détails spécifiques)
                GroupBox("Service Card brute") {
                    ScrollView {
                        Text(service.serviceCard ?? "Pas de service card disponible")
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 200)  // Limite la hauteur pour ne pas prendre trop de place
                }
                
                Spacer()
            }
            .padding()
        }
    }
}

struct ServiceConfigurationRow: View {
    let title: String
    let features: [ServiceBadgeData]
    let languages: Set<String>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(title)
                    .fontWeight(.medium)
                ForEach(features) { feature in
                    ServiceBadge(text: feature.text,
                                 isEnabled: feature.isEnabled,
                                 color: feature.color)
                }
            }
            if !languages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(Array(languages).sorted(), id: \.self) { langCode in
                            if let language = Language(rawValue: langCode) {
                                LanguageBadge(language: language)
                            }
                        }
                    }
                }
                .padding(.leading, 16)
            }
        }
    }
}

struct ServiceBadgeData: Identifiable {
    let id = UUID()
    let text: String
    let isEnabled: Bool
    let color: Color
}



struct AudioVideoDetailView: View {
    let details: AudioVideoRecordingDetails
    let service: ServiceModel
    @State private var showCommandEditor = false
    @State private var command: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GroupBox("Delivery Options") {
                Text(command)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                
                HStack {
                    Button("Copier Commande") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(command, forType: .string)
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Button(showCommandEditor ? "Fermer l'éditeur" : "Personnaliser la commande") {
                        showCommandEditor.toggle()
                    }
                    .buttonStyle(.bordered)
                }
                
                if showCommandEditor {
                    CommandEditorView(service: service)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .onAppear {
                command = service.audioVideoDetails?.generateDeliveryCommand() ?? ""
            }
            .onChange(of: service) { _, newValue in
                command = newValue.audioVideoDetails?.generateDeliveryCommand() ?? ""
            }
            
            
            
            // Configuration section
            GroupBox("Configuration") {
                VStack(alignment: .leading, spacing: 12) {
                    // Audio Only Section
                    if details.isAudioOnly {
                        ServiceConfigurationRow(
                            title: "Audio Only",
                            features: [
                                ServiceBadgeData(text: "Internal Use",
                                                 isEnabled: details.isInternalUseOnly,
                                                 color: .orange)
                            ],
                            languages: details.audioOnlyLanguages
                        )
                    }
                    
                    // VOD Section
                    if details.hasVOD {
                        if details.isAudioOnly { Divider() }
                        ServiceConfigurationRow(
                            title: "VOD",
                            features: [
                                ServiceBadgeData(text: "Downloadable",
                                                 isEnabled: details.isDownloadable,
                                                 color: .blue)
                            ],
                            languages: details.recordingLanguages
                        )
                    }
                    
                    // Livestream Section
                    if details.hasLivestream {
                        if details.hasVOD || details.isAudioOnly { Divider() }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Livestream")
                                .fontWeight(.medium)
                            // Platforms
                            if !details.streamingPlatformsEnum.isEmpty {
                                HStack {
                                    ForEach(Array(details.streamingPlatformsEnum).sorted(), id: \.self) { platform in
                                        StreamingPlatformBadge(platform: platform)
                                    }
                                }
                                .padding(.leading, 16)
                            }
                            // Languages
                            if !details.broadcastLanguages.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 4) {
                                        ForEach(Array(details.broadcastLanguages).sorted(), id: \.self) { langCode in
                                            if let language = Language(rawValue: langCode) {
                                                LanguageBadge(language: language)
                                            }
                                        }
                                    }
                                }
                                .padding(.leading, 16)
                            }
                        }
                    }
                }
            }
            
            // Processing Status
            GroupBox("Processing Status") {
                HStack {
                    Text(details.processingStatus.rawValue)
                        .foregroundStyle(processStatusColor)
                        .fontWeight(.medium)
                }
            }
            
            // Comments (only if specific comments exist)
            if let comments = details.xmlComments,
               comments.contains("Comments :") {
                GroupBox("Comments") {
                    if let commentLine = comments.components(separatedBy: .newlines)
                        .first(where: { $0.contains("Comments :") }) {
                        Text(commentLine.replacingOccurrences(of: "Comments :", with: "").trimmingCharacters(in: .whitespaces))
                            .font(.callout)
                    }
                }
            }
        }
        .padding()
    }
    
    private var processStatusColor: Color {
        switch details.processingStatus {
        case .pending: return .orange
        case .inProgress: return .blue
        case .completed: return .green
        case .failed: return .red
        case .cancelled: return .gray
        }
    }
}




struct OnlinePlatformDetailView: View {
    let details: OnlinePlatformDetails
    
    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Text("Configuration Plateforme")
                    .font(.headline)
                    .padding(.bottom, 4)
                
                // Options de base
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        ServiceBadge(text: "Documents",
                                     isEnabled: details.hasDocuments,
                                     color: .blue)
                        ServiceBadge(text: "Interprétation",
                                     isEnabled: details.needsInterpreting,
                                     color: .orange)
                    }
                    
                    HStack(spacing: 8) {
                        ServiceBadge(text: details.connectionTestType.rawValue,
                                     isEnabled: details.connectionTestType != .none,
                                     color: .green)
                        ServiceBadge(text: details.participantRange.rawValue,
                                     isEnabled: true,
                                     color: details.participantRange == .large ? .red : .green)
                    }
                    
                    if details.hasExistingLink {
                        ServiceBadge(text: "Lien existant",
                                     isEnabled: true,
                                     color: .purple)
                    }
                }
                
                // Détails du lien si disponible
                if details.hasExistingLink {
                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        if let link = details.platformLink {
                            InfoRow(label: "Lien", value: link)
                        }
                        if let meetingId = details.meetingId {
                            InfoRow(label: "Meeting ID", value: meetingId)
                        }
                        if let passcode = details.passcode {
                            InfoRow(label: "Passcode", value: passcode)
                        }
                        if let hostKey = details.hostKey {
                            InfoRow(label: "Host Key", value: hostKey)
                        }
                    }
                }
                
                // Commentaires si disponibles
                if let comments = details.comments {
                    Divider()
                    Text("Commentaires")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(comments)
                        .font(.callout)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
            
            // Bouton Copier
            Button(action: {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(value, forType: .string)
            }) {
                Image(systemName: "doc.on.doc")
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
            
            // Bouton Recherche web si le label est "EventID"
            if label == "EventID" {
                Button(action: {
                    let searchURL = "https://events.coe.int/search?q=\(value)"
                    if let url = URL(string: searchURL) {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}


func searchEventWithJS(eventId: String) {
    guard let url = URL(string: "https://events.coe.int/search") else { return }
    
    let script = """
    document.getElementById('search-event-id-field').value = '\(eventId)';
    document.getElementById('search-event-id-field').dispatchEvent(new Event('input', { bubbles: true }));
    """
    
    // Ouvrir la page
    NSWorkspace.shared.open(url)
    
    // Délai pour permettre le chargement de la page
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
        let config = WKWebViewConfiguration()
        let userScript = WKUserScript(
            source: script,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        config.userContentController.addUserScript(userScript)
        
        // Optionnel : créer un WebView temporaire pour exécuter le script
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.load(URLRequest(url: url))
    }
}
