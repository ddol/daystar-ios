import Foundation

public enum FitzpatrickType: Int, CaseIterable, Sendable, Codable {
    case typeI = 1
    case typeII = 2
    case typeIII = 3
    case typeIV = 4
    case typeV = 5
    case typeVI = 6

    public var shortDescription: String {
        switch self {
        case .typeI: "Always burns, does not tan"
        case .typeII: "Usually burns, tans minimally"
        case .typeIII: "Sometimes burns, gradually tans"
        case .typeIV: "Burns minimally, tans readily"
        case .typeV: "Rarely burns, tans easily"
        case .typeVI: "Very rarely burns"
        }
    }
}

public struct ErythemalThreshold: Sendable, Equatable {
    public let lowerBoundJoulesPerSquareMeter: Double
    public let upperBoundJoulesPerSquareMeter: Double
}

public enum FitzpatrickThresholds {
    public static func erythemaThreshold(for skinType: FitzpatrickType) -> ErythemalThreshold {
        switch skinType {
        case .typeI:
            ErythemalThreshold(lowerBoundJoulesPerSquareMeter: 150, upperBoundJoulesPerSquareMeter: 200)
        case .typeII:
            ErythemalThreshold(lowerBoundJoulesPerSquareMeter: 200, upperBoundJoulesPerSquareMeter: 250)
        case .typeIII:
            ErythemalThreshold(lowerBoundJoulesPerSquareMeter: 250, upperBoundJoulesPerSquareMeter: 350)
        case .typeIV:
            ErythemalThreshold(lowerBoundJoulesPerSquareMeter: 350, upperBoundJoulesPerSquareMeter: 450)
        case .typeV:
            ErythemalThreshold(lowerBoundJoulesPerSquareMeter: 450, upperBoundJoulesPerSquareMeter: 600)
        case .typeVI:
            ErythemalThreshold(lowerBoundJoulesPerSquareMeter: 600, upperBoundJoulesPerSquareMeter: 1000)
        }
    }
}
