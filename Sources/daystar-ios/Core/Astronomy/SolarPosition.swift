import Foundation

public struct SolarPosition: Sendable, Equatable {
    public let elevationDegrees: Double
    public let azimuthDegrees: Double
    public let zenithDegrees: Double
    public let declinationDegrees: Double
    public let equationOfTimeMinutes: Double
}

public enum SolarCalculator {
    public static func position(at date: Date, location: Location) -> SolarPosition {
        let local = localDateParts(for: date, timeZone: location.timeZone)
        let gamma = fractionalYear(dayOfYear: local.dayOfYear, localHour: local.localHour)

        let equationOfTime = solarEquationOfTimeMinutes(gamma: gamma)
        let declination = solarDeclinationRadians(gamma: gamma)

        let timeZoneOffsetHours = Double(location.timeZone.secondsFromGMT(for: date)) / 3600.0
        let trueSolarTimeMinutes = wrappingMinutes(
            local.localHour * 60.0
                + equationOfTime
                + 4.0 * location.longitude
                - 60.0 * timeZoneOffsetHours
        )

        var hourAngleDegrees = (trueSolarTimeMinutes / 4.0) - 180.0
        if hourAngleDegrees < -180.0 {
            hourAngleDegrees += 360.0
        }

        let latRad = location.latitude * .pi / 180.0
        let hourAngleRad = hourAngleDegrees * .pi / 180.0

        let cosZenith = max(-1.0, min(1.0,
            sin(latRad) * sin(declination) + cos(latRad) * cos(declination) * cos(hourAngleRad)
        ))
        let zenithRad = acos(cosZenith)
        let elevationRad = (.pi / 2.0) - zenithRad

        let azimuthRad = atan2(
            sin(hourAngleRad),
            cos(hourAngleRad) * sin(latRad) - tan(declination) * cos(latRad)
        ) + .pi

        return SolarPosition(
            elevationDegrees: elevationRad * 180.0 / .pi,
            azimuthDegrees: normalizedDegrees(azimuthRad * 180.0 / .pi),
            zenithDegrees: zenithRad * 180.0 / .pi,
            declinationDegrees: declination * 180.0 / .pi,
            equationOfTimeMinutes: equationOfTime
        )
    }
}

public enum AirMass {
    public static func relativeAirMass(forZenithDegrees zenithDegrees: Double) -> Double {
        guard zenithDegrees < 90.0 else { return .infinity }
        let z = zenithDegrees
        return 1.0 / (cos(z * .pi / 180.0) + 0.50572 * pow(96.07995 - z, -1.6364))
    }
}

func localDateParts(for date: Date, timeZone: TimeZone) -> (dayOfYear: Int, localHour: Double) {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = timeZone
    let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
    let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
    let hour = Double(comps.hour ?? 0)
    let minute = Double(comps.minute ?? 0)
    let second = Double(comps.second ?? 0)
    return (dayOfYear, hour + minute / 60.0 + second / 3600.0)
}

func fractionalYear(dayOfYear: Int, localHour: Double) -> Double {
    2.0 * .pi / 365.0 * (Double(dayOfYear) - 1.0 + (localHour - 12.0) / 24.0)
}

func solarEquationOfTimeMinutes(gamma: Double) -> Double {
    229.18 * (
        0.000075
            + 0.001868 * cos(gamma)
            - 0.032077 * sin(gamma)
            - 0.014615 * cos(2 * gamma)
            - 0.040849 * sin(2 * gamma)
    )
}

func solarDeclinationRadians(gamma: Double) -> Double {
    0.006918
        - 0.399912 * cos(gamma)
        + 0.070257 * sin(gamma)
        - 0.006758 * cos(2 * gamma)
        + 0.000907 * sin(2 * gamma)
        - 0.002697 * cos(3 * gamma)
        + 0.00148 * sin(3 * gamma)
}

func wrappingMinutes(_ value: Double) -> Double {
    let mod = value.truncatingRemainder(dividingBy: 1440.0)
    return mod >= 0 ? mod : mod + 1440.0
}

func normalizedDegrees(_ value: Double) -> Double {
    let mod = value.truncatingRemainder(dividingBy: 360.0)
    return mod >= 0 ? mod : mod + 360.0
}
