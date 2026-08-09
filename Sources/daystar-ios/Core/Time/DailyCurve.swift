import Foundation

public enum DailyMetric: String, Sendable, Hashable, CaseIterable, Identifiable {
    case irradiance
    case relativeUVPotential
    case accumulatedUVDose
    case sunElevation

    public var id: String { rawValue }
}

public struct DailyCurvePoint: Sendable, Equatable {
    public let date: Date
    public let value: Double
}

public enum DailyCurveGenerator {
    public static func curve(
        for metric: DailyMetric,
        on date: Date,
        location: Location,
        timeStepMinutes: Int = 15
    ) -> [DailyCurvePoint] {
        let tz = location.timeZone
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz

        let dayStart = cal.startOfDay(for: date)
        guard let dayEnd = cal.date(byAdding: .day, value: 1, to: dayStart) else { return [] }

        var points: [DailyCurvePoint] = []
        var t = dayStart
        var cumulativeDose = 0.0
        var previousUVIrradiance: Double?

        // Resolved once: `localDateParts` builds a Calendar and walks the year on every call, and
        // the day-of-year only feeds the annual orbital correction (~0.02% change per day).
        let dayOfYear = localDateParts(for: dayStart, timeZone: tz).dayOfYear

        while t <= dayEnd {
            let position = SolarCalculator.position(at: t, location: location)
            let irradiance = IrradianceCalculator.clearSky(
                position: position,
                elevationMeters: location.elevationMeters,
                dayOfYear: dayOfYear
            )
            let uvEstimate = UVModel.estimate(position: position, clearSkyIrradiance: irradiance)

            let value: Double
            switch metric {
            case .irradiance:
                value = irradiance.globalHorizontal.wattsPerSquareMeter
            case .relativeUVPotential:
                value = uvEstimate.modeledUVIndex ?? 0
            case .sunElevation:
                value = position.elevationDegrees
            case .accumulatedUVDose:
                if let last = points.last, let prev = previousUVIrradiance {
                    let dt = t.timeIntervalSince(last.date)
                    cumulativeDose += ((prev + uvEstimate.erythemalIrradiance.wattsPerSquareMeter) / 2.0) * dt
                }
                value = cumulativeDose
            }

            points.append(DailyCurvePoint(date: t, value: value))
            previousUVIrradiance = uvEstimate.erythemalIrradiance.wattsPerSquareMeter
            t = t.addingTimeInterval(Double(timeStepMinutes * 60))
        }

        return points
    }
}
