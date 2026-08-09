import SwiftUI

/// WHO UV Index exposure bands.
enum UVCategory: String, CaseIterable {
    case low = "Low"
    case moderate = "Moderate"
    case high = "High"
    case veryHigh = "Very High"
    case extreme = "Extreme"

    init(uvIndex: Double) {
        switch uvIndex {
        case ..<3: self = .low
        case ..<6: self = .moderate
        case ..<8: self = .high
        case ..<11: self = .veryHigh
        default: self = .extreme
        }
    }

    var color: Color {
        switch self {
        case .low: Color(red: 0.35, green: 0.78, blue: 0.55)
        case .moderate: Color(red: 0.98, green: 0.80, blue: 0.30)
        case .high: Color(red: 0.98, green: 0.58, blue: 0.24)
        case .veryHigh: Color(red: 0.94, green: 0.35, blue: 0.31)
        case .extreme: Color(red: 0.76, green: 0.42, blue: 0.92)
        }
    }

    var guidance: String {
        switch self {
        case .low: "No protection needed for most people."
        case .moderate: "Seek shade near midday; cover up."
        case .high: "Protection required. Shade, hat, sunscreen."
        case .veryHigh: "Extra protection. Avoid direct midday sun."
        case .extreme: "Avoid being outside during midday hours."
        }
    }
}
