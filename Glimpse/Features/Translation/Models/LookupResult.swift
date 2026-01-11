//
//  LookupResult.swift
//  Glimpse
//

/// The type of lookup result shown in the panel.
enum LookupResultType {
    case definition
    case translation

    /// Human-readable label for display.
    var displayLabel: String {
        switch self {
        case .definition: return "Definition"
        case .translation: return "Translation"
        }
    }
}
