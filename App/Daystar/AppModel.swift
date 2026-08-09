import Foundation
import Observation
import daystar_ios

/// Everything the UI reads for a single place and moment.
///
/// Assembled in one pass so the hero card, the chart callout and the exposure row can never
/// disagree about which instant they are describing.
struct SolarReading {
    let date: Date
    let city: City
    let position: SolarPosition
    let irradiance: ClearSkyIrradiance
    let uv: UVExposureEstimate
    let burn: BurnTimeEstimate?
    let events: SolarEvents

    var uvIndex: Double { uv.modeledUVIndex ?? 0 }
    var category: UVCategory { UVCategory(uvIndex: uvIndex) }
    var isDaylight: Bool { position.elevationDegrees > 0 }

    static func make(city: City, date: Date, skinType: FitzpatrickType) -> SolarReading {
        let location = city.location
        let position = SolarCalculator.position(at: date, location: location)
        let irradiance = IrradianceCalculator.clearSky(at: date, location: location)
        let uv = UVModel.estimate(position: position, clearSkyIrradiance: irradiance)
        return SolarReading(
            date: date,
            city: city,
            position: position,
            irradiance: irradiance,
            uv: uv,
            burn: BurnTimeEstimator.estimate(erythemalIrradiance: uv.erythemalIrradiance, skinType: skinType),
            events: SolarEventsCalculator.events(on: date, location: location)
        )
    }
}

@MainActor
@Observable
final class AppModel {
    private let store: any SkinTypeStoring
    private let database = CityDatabase.shared

    /// Wall-clock now, refreshed on a timer.
    private(set) var now: Date = .now

    var selectedCity: City
    /// Non-nil while the user is scrubbing the day chart.
    var scrubbedDate: Date?

    var skinType: FitzpatrickType {
        didSet { store.setSelectedSkinType(skinType) }
    }

    var cities: [City] { database.cities }

    init(store: any SkinTypeStoring = UserDefaultsSkinTypeStore()) {
        self.store = store
        self.skinType = store.selectedSkinType()
        self.selectedCity = database.cities.first!
    }

    /// The instant the whole UI is describing: a scrubbed time if the user is dragging the
    /// chart, otherwise the live clock.
    var effectiveDate: Date { scrubbedDate ?? now }

    var isScrubbing: Bool { scrubbedDate != nil }

    var reading: SolarReading {
        SolarReading.make(city: selectedCity, date: effectiveDate, skinType: skinType)
    }

    func curve(for metric: DailyMetric) -> [DailyCurvePoint] {
        DailyCurveGenerator.curve(for: metric, on: effectiveDate, location: selectedCity.location)
    }

    func search(_ query: String) -> [City] {
        database.search(query)
    }

    func tick() {
        now = .now
    }

    /// Exposure over the next `minutes` starting from the displayed instant.
    func exposureAhead(minutes: Int) -> ExposureInterval {
        let start = effectiveDate
        return ExposureCalculator.calculate(
            location: selectedCity.location,
            start: start,
            end: start.addingTimeInterval(Double(minutes) * 60)
        )
    }
}
