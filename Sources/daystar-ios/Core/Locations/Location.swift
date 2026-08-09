import Foundation

public struct Location: Sendable, Equatable {
    public let latitude: Double
    public let longitude: Double
    public let elevationMeters: Double?
    public let timeZoneIdentifier: String

    public init(latitude: Double, longitude: Double, elevationMeters: Double? = nil, timeZoneIdentifier: String) {
        self.latitude = latitude
        self.longitude = longitude
        self.elevationMeters = elevationMeters
        self.timeZoneIdentifier = timeZoneIdentifier
    }

    public var timeZone: TimeZone {
        TimeZone(identifier: timeZoneIdentifier) ?? .gmt
    }
}
