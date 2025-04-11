//
//  ImportToolsView.swift
//  EventsAtomizer
//
//  Created by localadmin on 12/02/2025.
//


import SwiftUI
import SwiftData



class ExcelSheetParser: NSObject, XMLParserDelegate {
    // On va réutiliser ParsedEntry comme structure de sortie
    private var entries: [ParsedEntry] = []
    
    func parse(xmlData: Data) -> [ParsedEntry] {
        entries.removeAll()
        let parser = XMLParser(data: xmlData)
        parser.delegate = self
        parser.parse()
        return entries
    }
    
    // On implémentera les méthodes delegate une fois qu'on aura vu la structure du XML
}


struct ImportStats {
    var totalServices: Int = 0
    var byType: [ServiceType: Int] = [:]
    var events: Int = 0
    var options: Int = 0
    
    mutating func addService(_ type: ServiceType) {
        totalServices += 1
        byType[type, default: 0] += 1
    }
}

struct ImportToolsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var services: [ServiceModel]
    @Query private var existingEvents: [Event]
    @Query private var existingOptions: [Option]
    
    @State private var importStats: ImportStats?
    @State private var isImporting = false
    @State private var importError: String?
    @State private var showImportSuccess = false
    @State private var showXMLDownload = false  // Add this
    
    var body: some View {
        VStack(spacing: 20) {
            // Current Stats
            GroupBox("État actuel") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Services: \(services.count)")
                        .fontWeight(.medium)
                    
                    
                    
                    // Services breakdown
                    ForEach(ServiceType.allCases, id: \.self) { type in
                        let count = services.filter { $0.serviceType == type }.count
                        if count > 0 {
                            HStack {
                                Text(type.rawValue)
                                Spacer()
                                Text("\(count)")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    Text("Events: \(existingEvents.count)")
                    Text("Options: \(existingOptions.count)")
                }
                .padding(.vertical, 4)
            }
            
            // Import Actions
            HStack(spacing: 20) {
                Button {
                    showXMLDownload = true
                } label: {
                    Label("Download XML", systemImage: "arrow.down.doc")
                }
                .buttonStyle(.borderedProminent)
                .disabled(isImporting)
                
                Button(action: importFile) {
                    HStack {
                        if isImporting {
                            ProgressView()
                                .controlSize(.small)
                        }
                        Label("Import", systemImage: "square.and.arrow.down")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isImporting)
                
                Button(action: resetAll) {
                    Label("Reset", systemImage: "trash")
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .disabled(isImporting)
            }
            
            // Import Results
            if let error = importError {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.callout)
            }
            
            if let stats = importStats {
                GroupBox("Résultats import") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Services importés: \(stats.totalServices)")
                            .fontWeight(.medium)
                        
                        ForEach(ServiceType.allCases, id: \.self) { type in
                            if let count = stats.byType[type], count > 0 {
                                HStack {
                                    Text(type.rawValue)
                                    Spacer()
                                    Text("\(count)")
                                }
                                .font(.caption)
                            }
                        }
                        
                        Divider()
                        
                        Text("Events: \(stats.events)")
                        Text("Options: \(stats.options)")
                    }
                    .padding(.vertical, 4)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding()
        .frame(maxWidth: 300)
        .sheet(isPresented: $showXMLDownload) {
            XMLDownloadView()}
        .animation(.spring(duration: 0.3), value: importError)
        .alert("Import réussi", isPresented: $showImportSuccess) {
            Button("OK") { }
        } message: {
            if let stats = importStats {
                Text("Importé \(stats.totalServices) services et \(stats.events) événements")
            }
        }
    }
    
    private func importFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canCreateDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.xml, .spreadsheet]  // Ajout de .spreadsheet
        
        panel.begin { response in
            if response == .OK {
                guard let url = panel.url else { return }
                Task { @MainActor in
                    await importFile(from: url)
                }
            }
        }
    }
    
    // Modification de la fonction importFile pour gérer les deux formats
    private func importFile(from url: URL) async {
        guard url.startAccessingSecurityScopedResource() else {
            importError = "Impossible d'accéder au fichier"
            return
        }
        
        defer { url.stopAccessingSecurityScopedResource() }
        
        isImporting = true
        importError = nil
        importStats = nil
        
        do {
            print("🔄 Début importation XML")
            
            let xmlData: Data
            
            // Déterminer la source et obtenir le XML
            if url.pathExtension.lowercased() == "xlsx" {
                print("Traitement du fichier Excel...")
                xmlData = try extractSheetFromExcel(excelURL: url)
            } else {
                print("Traitement du fichier XML...")
                xmlData = try Data(contentsOf: url)
            }
            
            print("📤 Fichier lu, taille: \(xmlData.count) octets")
            
            // Choisir le parser approprié
            var entries: [ParsedEntry]
            if url.pathExtension.lowercased() == "xlsx" {
                let excelSheetParser = ExcelSheetParser()
                entries = excelSheetParser.parse(xmlData: xmlData)
            } else {
                let xmlParser = ServiceXMLParser()
                entries = xmlParser.parse(xmlData: xmlData)
            }
            
            print("🔍 Parsing terminé, \(entries.count) entrées trouvées")
            
            // Déduplication simple: garder seulement la première occurrence de chaque serviceId
            var uniqueServiceIds = Set<String>()
            var uniqueEntries: [ParsedEntry] = []
            
            for entry in entries {
                if !uniqueServiceIds.contains(entry.serviceId) {
                    uniqueServiceIds.insert(entry.serviceId)
                    uniqueEntries.append(entry)
                } else {
                    print("⚠️ Entrée ignorée (serviceId dupliqué): \(entry.serviceId)")
                }
            }
            
            print("🧹 Après déduplication: \(entries.count) entrées originales -> \(uniqueEntries.count) entrées uniques")
            
            // Traiter les entrées dédupliquées
            var stats = ImportStats()
            
            for entry in uniqueEntries {
                do {
                    let (event, option, service) = entry.toSwiftDataModels(context: modelContext)
                    modelContext.insert(event)
                    modelContext.insert(option)
                    modelContext.insert(service)
                    stats.addService(service.serviceType)
                    stats.events += 1
                    stats.options += 1
                } catch {
                    print("❌ Erreur lors du traitement de l'entrée \(entry.readableId): \(error)")
                }
            }
            
            try modelContext.save()
            importStats = stats
            showImportSuccess = true
            print("🎉 Importation terminée avec succès: \(stats.totalServices) services importés")
            
        } catch {
            print("Erreur détaillée:", error)
            importError = "Erreur: \(error.localizedDescription)"
        }
        
        isImporting = false
    }
    
    private func extractSheetFromExcel(excelURL: URL) throws -> Data {
        print("Début de l'extraction du fichier Excel...")
        
        // Créer un dossier temporaire avec un nom unique
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ExcelExtract_\(UUID().uuidString)")
        
        print("Dossier temporaire créé:", tempDir.path)
        
        try FileManager.default.createDirectory(at: tempDir,
                                              withIntermediateDirectories: true)
        
        // Configuration du process unzip
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = [
            "-j",  // Junk paths (ne pas créer la structure de dossiers)
            excelURL.path,
            "xl/worksheets/sheet1.xml",
            "-d",
            tempDir.path
        ]
        
        // Capture de la sortie pour le debugging
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        print("Lancement de unzip...")
        
        // Exécuter unzip
        try process.run()
        process.waitUntilExit()
        
        // Vérifier le résultat
        let status = process.terminationStatus
        let output = String(data: outputPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let error = String(data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        
        print("Status unzip:", status)
        print("Output:", output)
        if !error.isEmpty {
            print("Erreur:", error)
        }
        
        guard status == 0 else {
            throw NSError(domain: "", code: Int(status),
                         userInfo: [NSLocalizedDescriptionKey: "Erreur d'extraction: \(error)"])
        }
        
        // Lire le XML extrait
        let xmlPath = tempDir.appendingPathComponent("sheet1.xml")
        let xmlData = try Data(contentsOf: xmlPath)
        
        print("XML extrait, taille:", xmlData.count, "bytes")
        
        // Nettoyer
        try FileManager.default.removeItem(at: tempDir)
        print("Nettoyage effectué")
        
        return xmlData
    }
    
    private func resetAll() {
        importError = nil
        importStats = nil
        
        services.forEach { modelContext.delete($0) }
        existingEvents.forEach { modelContext.delete($0) }
        existingOptions.forEach { modelContext.delete($0) }
        
        do {
            try modelContext.save()
        } catch {
            importError = "Erreur lors du reset: \(error.localizedDescription)"
        }
    }
}
