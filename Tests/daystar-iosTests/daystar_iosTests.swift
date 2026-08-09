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

/// Absolute-magnitude checks.
///
/// The ordering assertions above all passed while the erythemal scale was ~160x too large
/// (modeled UVI 1772, five-second burn times), because scaling every value by one constant
/// preserves ordering. These pin the physical scale.
struct PhysicalMagnitudeTests {
    @Test func modeledUVIndexStaysInPhysicalRange() throws {
        // Highest UV Index ever recorded at sea level is ~14; high-altitude Andes readings
        // reach ~20. Nothing this model produces should exceed that.
        for city in CityDatabase.shared.cities {
            let location = city.location
            for month in [1, 3, 6, 9, 12] {
                for hour in stride(from: 0, through: 23, by: 1) {
                    let date = try dateInTimeZone(
                        year: 2026, month: month, day: 15, hour: hour, minute: 0, timeZone: location.timeZone
                    )
                    let uvIndex = UVModel.estimate(at: date, location: location).modeledUVIndex ?? 0
                    #expect(
                        uvIndex >= 0 && uvIndex <= 20,
                        "\(city.name) month \(month) hour \(hour): modeled UVI \(uvIndex) is outside the physical range"
                    )
                }
            }
        }
    }

    @Test func tropicalNoonUVIndexMatchesPublishedClearSkyValues() throws {
        let location = CityDatabase.shared.search("Singapore").first!.location
        let noon = try dateInTimeZone(year: 2026, month: 3, day: 20, hour: 12, minute: 0, timeZone: location.timeZone)

        let estimate = UVModel.estimate(at: noon, location: location)
        let uvIndex = try #require(estimate.modeledUVIndex)

        // Clear-sky equatorial equinox noon sits around UVI 11-12.
        #expect(uvIndex > 9 && uvIndex < 14, "equatorial clear-sky noon UVI was \(uvIndex)")
        // WHO convention: UVI = erythemal W/m² x 40.
        #expect(abs(estimate.erythemalIrradiance.wattsPerSquareMeter - uvIndex / 40.0) < 1e-9)
    }

    @Test func burnTimeUnderStrongSunIsTensOfMinutes() throws {
        let location = CityDatabase.shared.search("Singapore").first!.location
        let noon = try dateInTimeZone(year: 2026, month: 3, day: 20, hour: 12, minute: 0, timeZone: location.timeZone)

        let estimate = try #require(BurnTimeEstimator.estimate(at: noon, location: location, skinType: .typeII))
        let lowerMinutes = durationSeconds(estimate.lowerBound) / 60.0
        let upperMinutes = durationSeconds(estimate.upperBound) / 60.0

        #expect(lowerMinutes > 5 && lowerMinutes < 30, "type II lower-bound burn time was \(lowerMinutes) min")
        #expect(upperMinutes > lowerMinutes)
    }

    @Test func oneNoonHourIsASmallNumberOfStandardErythemaDoses() throws {
        let location = CityDatabase.shared.search("Singapore").first!.location
        let start = try dateInTimeZone(year: 2026, month: 3, day: 20, hour: 11, minute: 0, timeZone: location.timeZone)
        let end = try dateInTimeZone(year: 2026, month: 3, day: 20, hour: 12, minute: 0, timeZone: location.timeZone)

        let interval = ExposureCalculator.calculate(location: location, start: start, end: end)
        let sed = interval.estimatedErythemalDose.joulesPerSquareMeter / 100.0

        // A whole clear tropical day is roughly 40-60 SED, so the peak hour is single digits.
        #expect(sed > 2 && sed < 15, "one hour before solar noon integrated to \(sed) SED")
    }

    @Test func solarNoonMatchesNOAAReference() throws {
        // NOAA solar calculator, San Francisco 2026-06-21: solar noon 13:11:23 PDT.
        let location = CityDatabase.shared.search("San Francisco").first!.location
        let date = try dateInTimeZone(year: 2026, month: 6, day: 21, hour: 12, minute: 0, timeZone: location.timeZone)
        let reference = try dateInTimeZone(year: 2026, month: 6, day: 21, hour: 13, minute: 11, timeZone: location.timeZone)

        let events = SolarEventsCalculator.events(on: date, location: location)
        #expect(abs(events.solarNoon.timeIntervalSince(reference)) < 120)
    }
}

struct DaylightSavingTests {
    /// Regression: event times were anchored to minutes past local midnight, so on a
    /// spring-forward day the 23-hour local day pushed every event an hour late.
    @Test func eventsDoNotJumpAcrossTheDSTTransition() throws {
        let location = CityDatabase.shared.search("New York").first!.location

        let transitionDay = try dateInTimeZone(year: 2026, month: 3, day: 8, hour: 12, minute: 0, timeZone: location.timeZone)
        let dayAfter = try dateInTimeZone(year: 2026, month: 3, day: 9, hour: 12, minute: 0, timeZone: location.timeZone)

        let transitionEvents = SolarEventsCalculator.events(on: transitionDay, location: location)
        let followingEvents = SolarEventsCalculator.events(on: dayAfter, location: location)

        let transitionSunrise = try wallClockMinutes(of: #require(transitionEvents.sunrise), in: location.timeZone)
        let followingSunrise = try wallClockMinutes(of: #require(followingEvents.sunrise), in: location.timeZone)
        let transitionNoon = wallClockMinutes(of: transitionEvents.solarNoon, in: location.timeZone)
        let followingNoon = wallClockMinutes(of: followingEvents.solarNoon, in: location.timeZone)

        // Consecutive days shift by a couple of minutes, never by an hour.
        #expect(abs(transitionSunrise - followingSunrise) < 10, "sunrise moved \(abs(transitionSunrise - followingSunrise)) min across the DST boundary")
        #expect(abs(transitionNoon - followingNoon) < 10, "solar noon moved \(abs(transitionNoon - followingNoon)) min across the DST boundary")
    }

    @Test func dstDaySunriseMatchesNOAAReference() throws {
        // NOAA solar calculator, New York 2026-03-08 (spring forward): sunrise 07:19:37 EDT.
        let location = CityDatabase.shared.search("New York").first!.location
        let date = try dateInTimeZone(year: 2026, month: 3, day: 8, hour: 12, minute: 0, timeZone: location.timeZone)

        let sunrise = try #require(SolarEventsCalculator.events(on: date, location: location).sunrise)
        #expect(abs(wallClockMinutes(of: sunrise, in: location.timeZone) - (7 * 60 + 19.6)) < 3)
    }
}

struct ExposureEdgeCaseTests {
    @Test func invertedRangeReturnsZeroInsteadOfTrapping() throws {
        let location = CityDatabase.shared.search("Dublin").first!.location
        let later = try dateInTimeZone(year: 2026, month: 6, day: 21, hour: 14, minute: 0, timeZone: location.timeZone)
        let earlier = try dateInTimeZone(year: 2026, month: 6, day: 21, hour: 13, minute: 0, timeZone: location.timeZone)

        let interval = ExposureCalculator.calculate(location: location, start: later, end: earlier)
        #expect(interval.estimatedErythemalDose.joulesPerSquareMeter == 0)
        #expect(interval.totalSolarEnergy.joulesPerSquareMeter == 0)
    }

    @Test func nonPositiveTimeStepTerminates() throws {
        let location = CityDatabase.shared.search("Dublin").first!.location
        let start = try dateInTimeZone(year: 2026, month: 6, day: 21, hour: 13, minute: 0, timeZone: location.timeZone)
        let end = try dateInTimeZone(year: 2026, month: 6, day: 21, hour: 13, minute: 1, timeZone: location.timeZone)

        let interval = ExposureCalculator.calculate(location: location, start: start, end: end, timeStepSeconds: 0)
        #expect(interval.estimatedErythemalDose.joulesPerSquareMeter > 0)
    }

    @Test func nightBurnEstimateIsUnavailableRatherThanInstant() throws {
        let location = CityDatabase.shared.search("Dublin").first!.location
        let midnight = try dateInTimeZone(year: 2026, month: 1, day: 15, hour: 0, minute: 30, timeZone: location.timeZone)

        #expect(BurnTimeEstimator.estimate(at: midnight, location: location, skinType: .typeI) == nil)
    }
}

private func wallClockMinutes(of date: Date, in timeZone: TimeZone) -> Double {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = timeZone
    let comps = calendar.dateComponents([.hour, .minute, .second], from: date)
    return Double(comps.hour ?? 0) * 60.0 + Double(comps.minute ?? 0) + Double(comps.second ?? 0) / 60.0
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
