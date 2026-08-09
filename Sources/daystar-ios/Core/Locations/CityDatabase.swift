import Foundation

public struct CityDatabase: Sendable {
    public static let shared = CityDatabase()
    private static let defaultCities: [City] = [
        City(name: "San Francisco", region: "CA", country: "USA", latitude: 37.7749, longitude: -122.4194, elevationMeters: 16, timeZoneIdentifier: "America/Los_Angeles"),
        City(name: "Dublin", country: "Ireland", latitude: 53.3498, longitude: -6.2603, elevationMeters: 20, timeZoneIdentifier: "Europe/Dublin"),
        City(name: "New York", region: "NY", country: "USA", latitude: 40.7128, longitude: -74.0060, elevationMeters: 10, timeZoneIdentifier: "America/New_York"),
        City(name: "Singapore", country: "Singapore", latitude: 1.3521, longitude: 103.8198, elevationMeters: 15, timeZoneIdentifier: "Asia/Singapore"),
        City(name: "Sydney", region: "NSW", country: "Australia", latitude: -33.8688, longitude: 151.2093, elevationMeters: 58, timeZoneIdentifier: "Australia/Sydney"),
        City(name: "Reykjavik", country: "Iceland", latitude: 64.1466, longitude: -21.9426, elevationMeters: 61, timeZoneIdentifier: "Atlantic/Reykjavik"),
        City(name: "Tokyo", country: "Japan", latitude: 35.6764, longitude: 139.6500, elevationMeters: 40, timeZoneIdentifier: "Asia/Tokyo")
    ]

    public let cities: [City]

    public init(cities: [City]) {
        self.cities = cities
    }

    public init() {
        self.cities = CityDatabase.defaultCities
    }

    public func search(_ query: String) -> [City] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return cities }
        let q = trimmed.lowercased()
        return cities.filter {
            $0.name.lowercased().contains(q)
            || ($0.region?.lowercased().contains(q) ?? false)
            || $0.country.lowercased().contains(q)
        }
    }
}
