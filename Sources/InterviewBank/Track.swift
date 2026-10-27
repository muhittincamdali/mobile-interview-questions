/// A group of questions that shares an ID prefix and a folder under `questions/`.
public enum Track: String, CaseIterable, Sendable, Codable {
    case ios
    case android
    case flutter
    case reactNative = "react-native"
    case systemDesign = "system-design"
    case behavioral

    /// The prefix every question ID in this track starts with, such as `IOS` in `IOS-014`.
    public var idPrefix: String {
        switch self {
        case .ios: "IOS"
        case .android: "AND"
        case .flutter: "FLT"
        case .reactNative: "RN"
        case .systemDesign: "SD"
        case .behavioral: "BHV"
        }
    }

    /// The name shown to people.
    public var displayName: String {
        switch self {
        case .ios: "iOS"
        case .android: "Android"
        case .flutter: "Flutter"
        case .reactNative: "React Native"
        case .systemDesign: "System design"
        case .behavioral: "Behavioral"
        }
    }

    /// Technical answers must cite at least one primary source; behavioral answers describe
    /// how to tell a story and have nothing to cite.
    public var requiresReference: Bool {
        self != .behavioral
    }
}

/// How much experience a question expects.
public enum Level: String, CaseIterable, Sendable, Codable, Comparable {
    case junior
    case mid
    case senior

    private var rank: Int {
        switch self {
        case .junior: 0
        case .mid: 1
        case .senior: 2
        }
    }

    public static func < (lhs: Level, rhs: Level) -> Bool {
        lhs.rank < rhs.rank
    }
}
