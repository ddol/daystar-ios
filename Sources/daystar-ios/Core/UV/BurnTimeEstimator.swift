import Foundation

public struct BurnTimeEstimate: Sendable, Equatable {
    public let lowerBound: Duration
    public let upperBound: Duration
    public let skinType: FitzpatrickType
}

public enum BurnTimeEstimator {
    public static func estimate(
        erythemalIrradiance: PowerPerArea,
        skinType: FitzpatrickType
    ) -> BurnTimeEstimate? {
        let irradiance = erythemalIrradiance.wattsPerSquareMeter
        guard irradiance > 0.001 else { return nil }

        let threshold = FitzpatrickThresholds.erythemaThreshold(for: skinType)
        let lowerSeconds = threshold.lowerBoundJoulesPerSquareMeter / irradiance
        let upperSeconds = threshold.upperBoundJoulesPerSquareMeter / irradiance

        return BurnTimeEstimate(
            lowerBound: .seconds(lowerSeconds),
            upperBound: .seconds(upperSeconds),
            skinType: skinType
        )
    }

    public static func estimate(at date: Date, location: Location, skinType: FitzpatrickType) -> BurnTimeEstimate? {
        let uvEstimate = UVModel.estimate(at: date, location: location)
        return estimate(erythemalIrradiance: uvEstimate.erythemalIrradiance, skinType: skinType)
    }
}
