import Foundation
import Testing
@testable import daystar_ios

struct CityDatabaseTests {
    @Test func searchFindsCityOffline() {
        let results = CityDatabase.shared.search("dublin")
        #expect(results.contains { $0.name == "Dublin" })
    }
}

struct SolarPositionTests {
    @Test func equinoxNoonAtEquatorIsHighSun() throws {
        let location = Location(latitude: 0, longitude: 0, timeZoneIdentifier: "Etc/UTC")
        let date = try dateUTC(year: 2026, month: 3, day: 20, hour: 12, minute: 0)

        let position = SolarCalculator.position(at: date, location: location)
        #expect(position.elevationDegrees > 85)
    }

    @Test func highLatitudeWinterNoonIsLowSun() throws {
        let location = CityDatabase.shared.search("Reykjavik").first!.location
        let date = try dateInTimeZone(year: 2026, month: 12, day: 21, hour: 12, minute: 0, timeZone: location.timeZone)

        let position = SolarCalculator.position(at: date, location: location)
        #expect(position.elevationDegrees < 10)
    }

    @Test func solarEventsHaveExpectedOrdering() throws {
        let location = CityDatabase.shared.search("San Francisco").first!.location
        let date = try dateInTimeZone(year: 2026, month: 6, day: 21, hour: 12, minute: 0, timeZone: location.timeZone)

        let events = SolarEventsCalculator.events(on: date, location: location)
        #expect(events.sunrise != nil)
        #expect(events.sunset != nil)
        #expect(events.sunrise! < events.solarNoon)
        #expect(events.solarNoon < events.sunset!)
        #expect(events.goldenHourMorningStart == events.sunrise)
        #expect(events.goldenHourEveningEnd == events.sunset)
    }
}

struct IrradianceAndUVTests {
    @Test func irradianceCurvePeaksNearNoon() throws {
        let location = CityDatabase.shared.search("New York").first!.location

        let morning = try dateInTimeZone(year: 2026, month: 6, day: 21, hour: 9, minute: 0, timeZone: location.timeZone)
        let noon = try dateInTimeZone(year: 2026, month: 6, day: 21, hour: 12, minute: 0, timeZone: location.timeZone)
        let evening = try dateInTimeZone(year: 2026, month: 6, day: 21, hour: 17, minute: 0, timeZone: location.timeZone)

        let im = IrradianceCalculator.clearSky(at: morning, location: location).globalHorizontal.wattsPerSquareMeter
        let inoon = IrradianceCalculator.clearSky(at: noon, location: location).globalHorizontal.wattsPerSquareMeter
        let ie = IrradianceCalculator.clearSky(at: evening, location: location).globalHorizontal.wattsPerSquareMeter

        #expect(inoon > im)
        #expect(inoon > ie)
    }

    @Test func burnTimeRangeUpdatesByTimeAndSkinType() throws {
        let location = CityDatabase.shared.search("Sydney").first!.location
        let morning = try dateInTimeZone(year: 2026, month: 1, day: 15, hour: 8, minute: 0, timeZone: location.timeZone)
        let noon = try dateInTimeZone(year: 2026, month: 1, day: 15, hour: 12, minute: 0, timeZone: location.timeZone)

        let morningEstimate = BurnTimeEstimator.estimate(at: morning, location: location, skinType: .typeII)
        let noonEstimate = BurnTimeEstimator.estimate(at: noon, location: location, skinType: .typeII)
        let noonTypeI = BurnTimeEstimator.estimate(at: noon, location: location, skinType: .typeI)
        let noonTypeVI = BurnTimeEstimator.estimate(at: noon, location: location, skinType: .typeVI)

        #expect(morningEstimate != nil)
        #expect(noonEstimate != nil)
        #expect(noonTypeI != nil)
        #expect(noonTypeVI != nil)

        let morningLowerMinutes = durationSeconds(morningEstimate!.lowerBound) / 60.0
        let noonLowerMinutes = durationSeconds(noonEstimate!.lowerBound) / 60.0
        let noonI = durationSeconds(noonTypeI!.lowerBound) / 60.0
        let noonVI = durationSeconds(noonTypeVI!.lowerBound) / 60.0

        #expect(noonLowerMinutes < morningLowerMinutes)
        #expect(noonI < noonVI)
    }

    @Test func exposureIntegrationProducesPositiveDose() throws {
        let location = CityDatabase.shared.search("Singapore").first!.location
        let start = try dateInTimeZone(year: 2026, month: 3, day: 20, hour: 10, minute: 0, timeZone: location.timeZone)
        let end = try dateInTimeZone(year: 2026, month: 3, day: 20, hour: 11, minute: 0, timeZone: location.timeZone)

        let interval = ExposureCalculator.calculate(location: location, start: start, end: end)
        #expect(interval.totalSolarEnergy.joulesPerSquareMeter > 0)
        #expect(interval.estimatedErythemalDose.joulesPerSquareMeter > 0)
    }

    @Test func dstTransitionStillReturnsOrderedEvents() throws {
        let location = CityDatabase.shared.search("New York").first!.location
        let date = try dateInTimeZone(year: 2026, month: 3, day: 8, hour: 12, minute: 0, timeZone: location.timeZone)

        let events = SolarEventsCalculator.events(on: date, location: location)
        #expect(events.sunrise != nil)
        #expect(events.sunset != nil)
        #expect(events.sunrise! < events.sunset!)
    }
}

private func dateUTC(year: Int, month: Int, day: Int, hour: Int, minute: Int) throws -> Date {
    guard let tz = TimeZone(identifier: "Etc/UTC") else { throw DateError.invalid }
    return try dateInTimeZone(year: year, month: month, day: day, hour: hour, minute: minute, timeZone: tz)
}

private func dateInTimeZone(year: Int, month: Int, day: Int, hour: Int, minute: Int, timeZone: TimeZone) throws -> Date {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = timeZone
    var comps = DateComponents()
    comps.year = year
    comps.month = month
    comps.day = day
    comps.hour = hour
    comps.minute = minute
    guard let date = calendar.date(from: comps) else { throw DateError.invalid }
    return date
}

private enum DateError: Error {
    case invalid
}

private func durationSeconds(_ duration: Duration) -> Double {
    let c = duration.components
    return Double(c.seconds) + (Double(c.attoseconds) / 1_000_000_000_000_000_000.0)
}
