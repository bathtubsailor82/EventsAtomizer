//
//  Language.swift
//  EventsAtomizer
//
//  Created by localadmin on 19/02/2025.
//


// LanguagesManager.swift

enum Language: String, CaseIterable {
    // Langue spéciale pour "Original"
    case original = "ORI"
    
    // Langues principales du Parlement européen
    case english = "ENG"
    case french = "FRA"
    case german = "DEU"
    case italian = "ITA"
    case spanish = "SPA"
    case polish = "POL"
    case romanian = "RON"
    case dutch = "NLD"
    case greek = "ELL"
    case hungarian = "HUN"
    case portuguese = "POR"
    case czech = "CES"
    case bulgarian = "BUL"
    case swedish = "SWE"
    case danish = "DAN"
    case finnish = "FIN"
    case slovak = "SLK"
    case irish = "GLE"
    case croatian = "HRV"
    case lithuanian = "LIT"
    case slovenian = "SLV"
    case latvian = "LAV"
    case estonian = "EST"
    case maltese = "MLT"
    case ukrainian = "UKR"
    
    var isoCode: String {
            switch self {
            case .original: return "or"  // Pas de vrai code ISO pour "original"
            case .english: return "en"
            case .french: return "fr"
            case .german: return "de"
            case .italian: return "it"
            case .spanish: return "es"
            case .polish: return "pl"
            case .romanian: return "ro"
            case .dutch: return "nl"
            case .greek: return "el"
            case .hungarian: return "hu"
            case .portuguese: return "pt"
            case .czech: return "cs"
            case .bulgarian: return "bg"
            case .swedish: return "sv"
            case .danish: return "da"
            case .finnish: return "fi"
            case .slovak: return "sk"
            case .irish: return "ga"
            case .croatian: return "hr"
            case .lithuanian: return "lt"
            case .slovenian: return "sl"
            case .latvian: return "lv"
            case .estonian: return "et"
            case .maltese: return "mt"
            case .ukrainian: return "uk"
            }
        }
    
    
    var displayName: String {
        switch self {
        case .original: return "Original"
        case .english: return "English"
        case .french: return "Français"
        case .german: return "Deutsch"
        case .italian: return "Italiano"
        case .spanish: return "Español"
        case .polish: return "Polski"
        case .romanian: return "Română"
        case .dutch: return "Nederlands"
        case .greek: return "Ελληνικά"
        case .hungarian: return "Magyar"
        case .portuguese: return "Português"
        case .czech: return "Čeština"
        case .bulgarian: return "Български"
        case .swedish: return "Svenska"
        case .danish: return "Dansk"
        case .finnish: return "Suomi"
        case .slovak: return "Slovenčina"
        case .irish: return "Gaeilge"
        case .croatian: return "Hrvatski"
        case .lithuanian: return "Lietuvių"
        case .slovenian: return "Slovenščina"
        case .latvian: return "Latviešu"
        case .estonian: return "Eesti"
        case .maltese: return "Malti"
        case .ukrainian: return "українська"
        }
    }
    
    var englishName: String {
        switch self {
        case .original: return "Original"
        case .english: return "English"
        case .french: return "French"
        case .german: return "German"
        case .italian: return "Italian"
        case .spanish: return "Spanish"
        case .polish: return "Polish"
        case .romanian: return "Romanian"
        case .dutch: return "Dutch"
        case .greek: return "Greek"
        case .hungarian: return "Hungarian"
        case .portuguese: return "Portuguese"
        case .czech: return "Czech"
        case .bulgarian: return "Bulgarian"
        case .swedish: return "Swedish"
        case .danish: return "Danish"
        case .finnish: return "Finnish"
        case .slovak: return "Slovak"
        case .irish: return "Irish"
        case .croatian: return "Croatian"
        case .lithuanian: return "Lithuanian"
        case .slovenian: return "Slovenian"
        case .latvian: return "Latvian"
        case .estonian: return "Estonian"
        case .maltese: return "Maltese"
        case .ukrainian: return "Ukrainian"
        }
    }
    
    static func from(string: String) -> Language? {
            let normalizedString = string.trimmingCharacters(in: .whitespaces).lowercased()
            
            // 1. Chercher une correspondance exacte avec le code
            if let exactMatch = Language.allCases.first(where: {
                $0.rawValue.lowercased() == normalizedString ||
                $0.isoCode.lowercased() == normalizedString
            }) {
                return exactMatch
            }
            
            // 2. Chercher dans les noms localisés
            if let displayMatch = Language.allCases.first(where: {
                $0.displayName.lowercased() == normalizedString
            }) {
                return displayMatch
            }
            
            // 3. Chercher dans les noms anglais
            if let englishMatch = Language.allCases.first(where: {
                $0.englishName.lowercased() == normalizedString
            }) {
                return englishMatch
            }
            
            // 4. Chercher une correspondance partielle
            return Language.allCases.first { language in
                normalizedString.contains(language.englishName.lowercased()) ||
                normalizedString.contains(language.displayName.lowercased()) ||
                normalizedString.contains(language.isoCode.lowercased())
            }
        }
}
