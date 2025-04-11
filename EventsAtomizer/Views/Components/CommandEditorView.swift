struct CommandEditorView: View {
    let service: ServiceModel
    @State private var preferences = CommandPreferences()
    @State private var command: String = ""
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GroupBox("Command Editor") {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        // Size argument
                        Toggle(isOn: $preferences.useSizeArg) {
                            HStack {
                                Text("Size")
                                    .frame(width: 80, alignment: .leading)
                                if preferences.useSizeArg {
                                    TextField("Value", text: $preferences.sizeValue)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .frame(width: 100)
                                }
                            }
                        }
                        .onChange(of: preferences.useSizeArg) { _, _ in updateCommand() }
                        .onChange(of: preferences.sizeValue) { _, _ in updateCommand() }
                        
                        // Sort argument
                        Toggle(isOn: $preferences.useSortArg) {
                            HStack {
                                Text("Sort")
                                    .frame(width: 80, alignment: .leading)
                                if preferences.useSortArg {
                                    Picker("", selection: $preferences.sortValue) {
                                        Text("time").tag("time")
                                        Text("name").tag("name")
                                        Text("size").tag("size")
                                    }
                                    .frame(width: 100)
                                }
                            }
                        }
                        .onChange(of: preferences.useSortArg) { _, _ in updateCommand() }
                        .onChange(of: preferences.sortValue) { _, _ in updateCommand() }
                        
                        // Languages argument
                        Toggle(isOn: $preferences.useLangArg) {
                            Text("Include Languages")
                                .frame(width: 180, alignment: .leading)
                        }
                        .onChange(of: preferences.useLangArg) { _, _ in updateCommand() }
                        
                        // Custom event
                        Toggle(isOn: $preferences.useCustomEvent) {
                            HStack {
                                Text("Custom Event")
                                    .frame(width: 120, alignment: .leading)
                            }
                        }
                        .onChange(of: preferences.useCustomEvent) { _, _ in updateCommand() }
                        
                        if preferences.useCustomEvent {
                            TextField("Custom Event Value", text: $preferences.customEventValue)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onChange(of: preferences.customEventValue) { _, _ in updateCommand() }
                        }
                    }
                    .padding()
                }
                .frame(height: 200)
            }
            
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
        }
        .onAppear {
            // Charger les préférences existantes ou utiliser les valeurs par défaut
            loadPreferences()
            updateCommand()
        }
        .padding()
    }
    
    private func updateCommand() {
        command = service.audioVideoDetails?.generateDeliveryCommand(preferences: preferences) ?? ""
    }
    
    private func resetToDefault() {
        preferences = CommandPreferences()
        updateCommand()
    }
    
    private func loadPreferences() {
        // Ici, vous pourriez charger les préférences depuis SwiftData si vous souhaitez les persister
        // Pour l'instant, nous utilisons simplement les valeurs par défaut
    }
}