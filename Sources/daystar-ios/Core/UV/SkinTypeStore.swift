import Foundation

public protocol SkinTypeStoring: Sendable {
    func selectedSkinType() -> FitzpatrickType
    func setSelectedSkinType(_ type: FitzpatrickType)
}

public final class UserDefaultsSkinTypeStore: SkinTypeStoring, @unchecked Sendable {
    private let defaults: UserDefaults
    private let key = "settings.fitzpatrickSkinType"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func selectedSkinType() -> FitzpatrickType {
        let raw = defaults.integer(forKey: key)
        return FitzpatrickType(rawValue: raw) ?? .typeII
    }

    public func setSelectedSkinType(_ type: FitzpatrickType) {
        defaults.set(type.rawValue, forKey: key)
    }
}
