// CommandPreferences.swift
import Foundation
import SwiftData

@Model
class CommandPreferences {
    // Arguments activés par défaut
    var useSizeArg: Bool = true
    var sizeValue: String = "43M"
    
    // Arguments optionnels
    var useSortArg: Bool = false
    var sortValue: String = "time"
    
    var useLangArg: Bool = false
    // Les langues par défaut sont toujours incluses dans generateDeliveryCommand
    
    // Autres préférences possibles
    var useCustomEvent: Bool = false
    var customEventValue: String = ""
    
    init() {}
}