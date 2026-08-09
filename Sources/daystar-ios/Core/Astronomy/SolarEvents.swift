import Foundation

public struct SolarEvents: Sendable, Equatable {
    public let solarNoon: Date
    public let sunrise: Date?
    public let sunset: Date?
    public let civilDawn: Date?
    public let civilDusk: Date?
    public let goldenHourMorningStart: Date?
    public let goldenHourMorningEnd: Date?
    public let goldenHourEveningStart: Date?
    public let goldenHourEveningEnd: Date?
}

public enum SolarEventsCalculator {
    public static func events(on date: Date, location: Location) -> SolarEvents {
        let tz = location.timeZone
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz

        let startOfDay = cal.startOfDay(for: date)
        let noon = cal.date(byAdding: .hour, value: 12, to: startOfDay) ?? date

        let local = localDateParts(for: noon, timeZone: tz)
        let gamma = fractionalYear(dayOfYear: local.dayOfYear, localHour: local.localHour)

        let equationOfTime = solarEquationOfTimeMinutes(gamma: gamma)
        let declination = solarDeclinationRadians(gamma: gamma)

        let offsetHours = Double(tz.secondsFromGMT(for: noon)) / 3600.0
        let solarNoonMinutes = 720.0 - 4.0 * location.longitude - equationOfTime + (offsetHours * 60.0)

        let sunrise = eventTime(
            solarNoonMinutes: solarNoonMinutes,
            altitudeDegrees: -0.833,
            declinationRadians: declination,
            latitudeDegrees: location.latitude,
            dayStart: startOfDay,
            rise: true
        )
        let sunset = eventTime(
            solarNoonMinutes: solarNoonMinutes,
            altitudeDegrees: -0.833,
            declinationRadians: declination,
            latitudeDegrees: location.latitude,
            dayStart: startOfDay,
            rise: false
        )
        let civilDawn = eventTime(
            solarNoonMinutes: solarNoonMinutes,
            altitudeDegrees: -6.0,
            declinationRadians: declination,
            latitudeDegrees: location.latitude,
            dayStart: startOfDay,
            rise: true
        )
        let civilDusk = eventTime(
            solarNoonMinutes: solarNoonMinutes,
            altitudeDegrees: -6.0,
            declinationRadians: declination,
            latitudeDegrees: location.latitude,
            dayStart: startOfDay,
            rise: false
        )

        let morningGoldenEnd = eventTime(
            solarNoonMinutes: solarNoonMinutes,
            altitudeDegrees: 6.0,
            declinationRadians: declination,
            latitudeDegrees: location.latitude,
            dayStart: startOfDay,
            rise: true
        )
        let eveningGoldenStart = eventTime(
            solarNoonMinutes: solarNoonMinutes,
            altitudeDegrees: 6.0,
            declinationRadians: declination,
            latitudeDegrees: location.latitude,
            dayStart: startOfDay,
            rise: false
        )

        return SolarEvents(
            solarNoon: startOfDay.addingTimeInterval(solarNoonMinutes * 60.0),
            sunrise: sunrise,
            sunset: sunset,
            civilDawn: civilDawn,
            civilDusk: civilDusk,
            goldenHourMorningStart: sunrise,
            goldenHourMorningEnd: morningGoldenEnd,
            goldenHourEveningStart: eveningGoldenStart,
            goldenHourEveningEnd: sunset
        )
    }
}

private func eventTime(
    solarNoonMinutes: Double,
    altitudeDegrees: Double,
    declinationRadians: Double,
    latitudeDegrees: Double,
    dayStart: Date,
    rise: Bool
) -> Date? {
    let lat = latitudeDegrees * .pi / 180.0
    let zenith = (90.0 - altitudeDegrees) * .pi / 180.0

    let numerator = cos(zenith) - sin(lat) * sin(declinationRadians)
    let denominator = cos(lat) * cos(declinationRadians)
    guard denominator != 0 else { return nil }

    let cosHourAngle = numerator / denominator
    guard cosHourAngle >= -1.0, cosHourAngle <= 1.0 else { return nil }

    let hourAngle = acos(cosHourAngle) * 180.0 / .pi
    let minutes = rise
        ? solarNoonMinutes - 4.0 * hourAngle
        : solarNoonMinutes + 4.0 * hourAngle

    return dayStart.addingTimeInterval(minutes * 60.0)
}
