import Foundation

public struct City: Sendable, Equatable, Identifiable {
    public let id: String
    public let name: String
    public let region: String?
    public let country: String
    public let latitude: Double
    public let longitude: Double
    public let elevationMeters: Double?
    public let timeZoneIdentifier: String

    public init(
        name: String,
        region: String? = nil,
        country: String,
        latitude: Double,
        longitude: Double,
        elevationMeters: Double? = nil,
        timeZoneIdentifier: String
    ) {
        self.name = name
        self.region = region
        self.country = country
        self.latitude = latitude
        self.longitude = longitude
        self.elevationMeters = elevationMeters
        self.timeZoneIdentifier = timeZoneIdentifier
        let normalizedRegion = region ?? ""
        let normalizedLatitude = String(format: "%.6f", latitude)
        let normalizedLongitude = String(format: "%.6f", longitude)
        self.id = [name, normalizedRegion, country, normalizedLatitude, normalizedLongitude]
            .joined(separator: "|")
            .lowercased()
    }

    public var location: Location {
        Location(
            latitude: latitude,
            longitude: longitude,
            elevationMeters: elevationMeters,
            timeZoneIdentifier: timeZoneIdentifier
        )
    }
}
