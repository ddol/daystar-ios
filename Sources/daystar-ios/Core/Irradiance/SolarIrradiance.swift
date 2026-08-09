import Foundation

public struct ClearSkyIrradiance: Sendable, Equatable {
    public let extraterrestrialNormal: PowerPerArea
    public let directNormal: PowerPerArea
    public let globalHorizontal: PowerPerArea
}

public enum IrradianceCalculator {
    public static func clearSky(
        position: SolarPosition,
        elevationMeters: Double? = nil,
        dayOfYear: Int
    ) -> ClearSkyIrradiance {
        let cosZenith = max(0.0, cos(position.zenithDegrees * .pi / 180.0))
        let earthOrbitalFactor = 1.0 + 0.033 * cos(2.0 * .pi * Double(dayOfYear) / 365.0)
        let extraterrestrial = 1361.0 * earthOrbitalFactor

        guard cosZenith > 0 else {
            return ClearSkyIrradiance(
                extraterrestrialNormal: PowerPerArea(wattsPerSquareMeter: extraterrestrial),
                directNormal: PowerPerArea(wattsPerSquareMeter: 0),
                globalHorizontal: PowerPerArea(wattsPerSquareMeter: 0)
            )
        }

        let airMass = AirMass.relativeAirMass(forZenithDegrees: position.zenithDegrees)
        let altitude = max(0.0, elevationMeters ?? 0.0)
        let broadbandTransmittance = min(0.88, 0.75 + altitude * 2.0e-5)

        let directNormal = extraterrestrial * pow(broadbandTransmittance, min(airMass, 20.0))
        let directHorizontal = directNormal * cosZenith
        let diffuseHorizontal = 0.12 * extraterrestrial * cosZenith

        return ClearSkyIrradiance(
            extraterrestrialNormal: PowerPerArea(wattsPerSquareMeter: extraterrestrial),
            directNormal: PowerPerArea(wattsPerSquareMeter: max(0, directNormal)),
            globalHorizontal: PowerPerArea(wattsPerSquareMeter: max(0, directHorizontal + diffuseHorizontal))
        )
    }

    public static func clearSky(at date: Date, location: Location) -> ClearSkyIrradiance {
        let position = SolarCalculator.position(at: date, location: location)
        let day = localDateParts(for: date, timeZone: location.timeZone).dayOfYear
        return clearSky(position: position, elevationMeters: location.elevationMeters, dayOfYear: day)
    }
}
