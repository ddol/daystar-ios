import Foundation
import daystar_ios

enum Fmt {
    static func time(_ date: Date?, in timeZone: TimeZone) -> String {
        guard let date else { return "—" }
        var style = Date.FormatStyle.dateTime.hour().minute()
        style.timeZone = timeZone
        return date.formatted(style)
    }

    static func timeRange(_ start: Date?, _ end: Date?, in timeZone: TimeZone) -> String {
        guard let start, let end else { return "—" }
        return "\(time(start, in: timeZone))–\(time(end, in: timeZone))"
    }

    static func degrees(_ value: Double) -> String {
        "\(value.formatted(.number.precision(.fractionLength(0))))°"
    }

    static func wattsPerSquareMeter(_ value: Double) -> String {
        "\(value.formatted(.number.precision(.fractionLength(0)))) W/m²"
    }

    static func uvIndex(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(value < 10 ? 1 : 0)))
    }

    /// Minutes for short spans, `h m` beyond an hour, and an explicit ceiling past a day.
    static func minutes(_ duration: Duration) -> String {
        let totalMinutes = Int((Double(duration.components.seconds) / 60.0).rounded())
        if totalMinutes >= 60 * 24 { return "24 h+" }
        if totalMinutes >= 60 {
            let hours = totalMinutes / 60
            let rest = totalMinutes % 60
            return rest == 0 ? "\(hours) h" : "\(hours) h \(rest) m"
        }
        return "\(max(totalMinutes, 1)) min"
    }

    static func burnRange(_ estimate: BurnTimeEstimate?) -> String {
        guard let estimate else { return "—" }
        return "\(minutes(estimate.lowerBound))–\(minutes(estimate.upperBound))"
    }

    static func standardErythemaDoses(_ energy: EnergyPerArea) -> String {
        let sed = energy.joulesPerSquareMeter / 100.0
        return "\(sed.formatted(.number.precision(.fractionLength(sed < 10 ? 1 : 0)))) SED"
    }

    static func joulesPerSquareMeter(_ energy: EnergyPerArea) -> String {
        "\(energy.joulesPerSquareMeter.formatted(.number.precision(.fractionLength(0)))) J/m²"
    }

    static func localClock(_ date: Date, in timeZone: TimeZone) -> String {
        var style = Date.FormatStyle.dateTime.hour().minute()
        style.timeZone = timeZone
        return date.formatted(style)
    }
}

extension FitzpatrickType {
    var displayName: String {
        switch self {
        case .typeI: "Type I"
        case .typeII: "Type II"
        case .typeIII: "Type III"
        case .typeIV: "Type IV"
        case .typeV: "Type V"
        case .typeVI: "Type VI"
        }
    }
}

extension DailyMetric {
    /// Presentation order, most product-relevant metric first.
    static let displayOrder: [DailyMetric] = [.relativeUVPotential, .irradiance, .accumulatedUVDose, .sunElevation]

    var title: String {
        switch self {
        case .relativeUVPotential: "UV potential"
        case .irradiance: "Irradiance"
        case .accumulatedUVDose: "UV dose"
        case .sunElevation: "Sun elevation"
        }
    }

    var unit: String {
        switch self {
        case .relativeUVPotential: "modeled UV Index"
        case .irradiance: "W/m²"
        case .accumulatedUVDose: "J/m² accumulated"
        case .sunElevation: "degrees above horizon"
        }
    }

    func format(_ value: Double) -> String {
        switch self {
        case .relativeUVPotential: Fmt.uvIndex(value)
        case .irradiance: Fmt.wattsPerSquareMeter(value)
        case .accumulatedUVDose: Fmt.joulesPerSquareMeter(EnergyPerArea(joulesPerSquareMeter: value))
        case .sunElevation: Fmt.degrees(value)
        }
    }
}
