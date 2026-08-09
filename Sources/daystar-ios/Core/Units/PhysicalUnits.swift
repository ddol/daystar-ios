import Foundation

public struct PowerPerArea: Sendable, Equatable, Comparable {
    public let wattsPerSquareMeter: Double

    public init(wattsPerSquareMeter: Double) {
        self.wattsPerSquareMeter = wattsPerSquareMeter
    }

    public static func < (lhs: PowerPerArea, rhs: PowerPerArea) -> Bool {
        lhs.wattsPerSquareMeter < rhs.wattsPerSquareMeter
    }
}

public struct EnergyPerArea: Sendable, Equatable, Comparable {
    public let joulesPerSquareMeter: Double

    public init(joulesPerSquareMeter: Double) {
        self.joulesPerSquareMeter = joulesPerSquareMeter
    }

    public static func < (lhs: EnergyPerArea, rhs: EnergyPerArea) -> Bool {
        lhs.joulesPerSquareMeter < rhs.joulesPerSquareMeter
    }

    public var wattHoursPerSquareMeter: Double {
        joulesPerSquareMeter / 3600.0
    }
}
