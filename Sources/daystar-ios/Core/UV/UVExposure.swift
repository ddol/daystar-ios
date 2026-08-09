import Foundation

public struct ExposureInterval: Sendable, Equatable {
    public let start: Date
    public let end: Date
    public let totalSolarEnergy: EnergyPerArea
    public let estimatedErythemalDose: EnergyPerArea
}

public enum ExposureCalculator {
    public static func calculate(
        location: Location,
        start: Date,
        end: Date,
        timeStepSeconds: TimeInterval = 300
    ) -> ExposureInterval {
        precondition(end >= start, "end must be >= start")

        let duration = end.timeIntervalSince(start)
        if duration == 0 {
            return ExposureInterval(
                start: start,
                end: end,
                totalSolarEnergy: EnergyPerArea(joulesPerSquareMeter: 0),
                estimatedErythemalDose: EnergyPerArea(joulesPerSquareMeter: 0)
            )
        }

        var current = start
        var totalSolarJm2 = 0.0
        var totalErythemalJm2 = 0.0
        let startPosition = SolarCalculator.position(at: current, location: location)
        var irradianceA = IrradianceCalculator.clearSky(
            position: startPosition,
            elevationMeters: location.elevationMeters,
            dayOfYear: localDateParts(for: current, timeZone: location.timeZone).dayOfYear
        )
        var uvA = UVModel.estimate(position: startPosition, clearSkyIrradiance: irradianceA)

        while current < end {
            let next = min(current.addingTimeInterval(timeStepSeconds), end)
            let dt = next.timeIntervalSince(current)
            let positionB = SolarCalculator.position(at: next, location: location)
            let irradianceB = IrradianceCalculator.clearSky(
                position: positionB,
                elevationMeters: location.elevationMeters,
                dayOfYear: localDateParts(for: next, timeZone: location.timeZone).dayOfYear
            )
            let uvB = UVModel.estimate(position: positionB, clearSkyIrradiance: irradianceB)

            totalSolarJm2 += ((irradianceA.globalHorizontal.wattsPerSquareMeter + irradianceB.globalHorizontal.wattsPerSquareMeter) / 2.0) * dt
            totalErythemalJm2 += ((uvA.erythemalIrradiance.wattsPerSquareMeter + uvB.erythemalIrradiance.wattsPerSquareMeter) / 2.0) * dt

            irradianceA = irradianceB
            uvA = uvB
            current = next
        }

        return ExposureInterval(
            start: start,
            end: end,
            totalSolarEnergy: EnergyPerArea(joulesPerSquareMeter: totalSolarJm2),
            estimatedErythemalDose: EnergyPerArea(joulesPerSquareMeter: totalErythemalJm2)
        )
    }
}
