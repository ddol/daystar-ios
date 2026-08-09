import Foundation

public struct UVExposureEstimate: Sendable, Equatable {
    public let erythemalIrradiance: PowerPerArea
    public let modeledUVIndex: Double?
    public let confidence: EstimateConfidence

    public init(erythemalIrradiance: PowerPerArea, modeledUVIndex: Double?, confidence: EstimateConfidence) {
        self.erythemalIrradiance = erythemalIrradiance
        self.modeledUVIndex = modeledUVIndex
        self.confidence = confidence
    }
}

public enum EstimateConfidence: String, Sendable {
    case clearSkyModeled
    case lowSunOrNoData
}

public enum UVModel {
    // Clear-sky proxy coefficients tuned for conservative erythemal weighting from broadband irradiance.
    private static let uvFractionBase = 0.02
    private static let uvFractionAmplitude = 0.02
    private static let uvFractionZenithExponent = 0.35

    public static func estimate(
        position: SolarPosition,
        clearSkyIrradiance: ClearSkyIrradiance
    ) -> UVExposureEstimate {
        guard position.elevationDegrees > 0 else {
            return UVExposureEstimate(
                erythemalIrradiance: PowerPerArea(wattsPerSquareMeter: 0),
                modeledUVIndex: nil,
                confidence: .lowSunOrNoData
            )
        }

        let cosZenith = max(0.0, cos(position.zenithDegrees * .pi / 180.0))
        // Clear-sky proxy: maps broadband shortwave to erythemally weighted UV.
        // This is a modeled approximation, not an observed UV sensor value.
        let uvFraction = uvFractionBase + uvFractionAmplitude * pow(cosZenith, uvFractionZenithExponent)
        let erythemalWm2 = max(0, clearSkyIrradiance.globalHorizontal.wattsPerSquareMeter * uvFraction)
        // WHO/ICNIRP erythemal weighting convention uses UVI = Eery * 40.
        let uvIndex = erythemalWm2 * 40.0

        return UVExposureEstimate(
            erythemalIrradiance: PowerPerArea(wattsPerSquareMeter: erythemalWm2),
            modeledUVIndex: uvIndex,
            confidence: .clearSkyModeled
        )
    }

    public static func estimate(at date: Date, location: Location) -> UVExposureEstimate {
        let position = SolarCalculator.position(at: date, location: location)
        let irradiance = IrradianceCalculator.clearSky(at: date, location: location)
        return estimate(position: position, clearSkyIrradiance: irradiance)
    }
}

public struct UVConditions: Sendable, Equatable {
    public let uvIndex: Double
    public let ozoneDobsonUnits: Double?
    public let cloudCoverFraction: Double?
    public let atmosphericAttenuation: Double?
    public let aerosolOpticalDepth: Double?
    public let temperatureCelsius: Double?
    public let weatherSummary: String?

    public init(
        uvIndex: Double,
        ozoneDobsonUnits: Double? = nil,
        cloudCoverFraction: Double? = nil,
        atmosphericAttenuation: Double? = nil,
        aerosolOpticalDepth: Double? = nil,
        temperatureCelsius: Double? = nil,
        weatherSummary: String? = nil
    ) {
        self.uvIndex = uvIndex
        self.ozoneDobsonUnits = ozoneDobsonUnits
        self.cloudCoverFraction = cloudCoverFraction
        self.atmosphericAttenuation = atmosphericAttenuation
        self.aerosolOpticalDepth = aerosolOpticalDepth
        self.temperatureCelsius = temperatureCelsius
        self.weatherSummary = weatherSummary
    }
}

public protocol UVConditionsProvider: Sendable {
    func conditions(for location: Location, at date: Date) async throws -> UVConditions
}
