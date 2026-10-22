import Foundation

public nonisolated enum SNSPlatform: String, Codable, CaseIterable, Equatable, Hashable, Sendable {
    case instagram
    case threads
    case x
}

public nonisolated enum SplitGap: Codable, Equatable, Sendable {
    case custom(Percent)
    case platform(SNSPlatform)
}

public nonisolated struct SplitLayer: Codable, Equatable, Sendable {
    public private(set) var count: Int
    public var gap: SplitGap

    public init(count: Int, gap: SplitGap) {
        self.count = Self.clampedCount(count)
        self.gap = gap
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        count = Self.clampedCount(try container.decode(Int.self, forKey: .count))
        gap = try container.decode(SplitGap.self, forKey: .gap)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(count, forKey: .count)
        try container.encode(gap, forKey: .gap)
    }

    private enum CodingKeys: String, CodingKey {
        case count
        case gap
    }

    private static func clampedCount(_ count: Int) -> Int {
        min(10, max(2, count))
    }
}
