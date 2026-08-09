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

        // Anchor every event to a UTC instant rather than to minutes past local midnight.
        // On a DST-transition day the local day is 23 or 25 hours long, so "minutes past local
        // midnight" no longer maps onto wall-clock time and every event lands an hour off.
        let localNoon = localNoonInstant(for: date, calendar: cal)
        let utc = localDateParts(for: localNoon, timeZone: .gmt)
        let gamma = fractionalYear(dayOfYear: utc.dayOfYear, localHour: utc.localHour)

        let equationOfTime = solarEquationOfTimeMinutes(gamma: gamma)
        let declination = solarDeclinationRadians(gamma: gamma)

        // Minutes past UTC midnight on the UTC day that contains local noon. Anchoring on that
        // UTC day (rather than the local date) keeps far-east/far-west zones such as
        // Pacific/Kiritimati on the correct calendar day.
        let solarNoonMinutes = 720.0 - 4.0 * location.longitude - equationOfTime
        let utcDayStart = utcMidnight(containing: localNoon)

        let sunrise = eventTime(
            solarNoonMinutes: solarNoonMinutes,
            altitudeDegrees: -0.833,
            declinationRadians: declination,
            latitudeDegrees: location.latitude,
            dayStart: utcDayStart,
            rise: true
        )
        let sunset = eventTime(
            solarNoonMinutes: solarNoonMinutes,
            altitudeDegrees: -0.833,
            declinationRadians: declination,
            latitudeDegrees: location.latitude,
            dayStart: utcDayStart,
            rise: false
        )
        let civilDawn = eventTime(
            solarNoonMinutes: solarNoonMinutes,
            altitudeDegrees: -6.0,
            declinationRadians: declination,
            latitudeDegrees: location.latitude,
            dayStart: utcDayStart,
            rise: true
        )
        let civilDusk = eventTime(
            solarNoonMinutes: solarNoonMinutes,
            altitudeDegrees: -6.0,
            declinationRadians: declination,
            latitudeDegrees: location.latitude,
            dayStart: utcDayStart,
            rise: false
        )

        let morningGoldenEnd = eventTime(
            solarNoonMinutes: solarNoonMinutes,
            altitudeDegrees: 6.0,
            declinationRadians: declination,
            latitudeDegrees: location.latitude,
            dayStart: utcDayStart,
            rise: true
        )
        let eveningGoldenStart = eventTime(
            solarNoonMinutes: solarNoonMinutes,
            altitudeDegrees: 6.0,
            declinationRadians: declination,
            latitudeDegrees: location.latitude,
            dayStart: utcDayStart,
            rise: false
        )

        return SolarEvents(
            solarNoon: utcDayStart.addingTimeInterval(solarNoonMinutes * 60.0),
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

/// 12:00 local wall-clock on the calendar day containing `date`.
///
/// Built from date components rather than `startOfDay + 12h` so a DST shift earlier in the day
/// does not push the result to 11:00 or 13:00.
private func localNoonInstant(for date: Date, calendar: Calendar) -> Date {
    var comps = calendar.dateComponents([.year, .month, .day], from: date)
    comps.hour = 12
    comps.minute = 0
    comps.second = 0
    return calendar.date(from: comps) ?? date
}

/// Midnight UTC on the UTC calendar day containing `instant`.
private func utcMidnight(containing instant: Date) -> Date {
    var utcCalendar = Calendar(identifier: .gregorian)
    utcCalendar.timeZone = .gmt
    return utcCalendar.startOfDay(for: instant)
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
