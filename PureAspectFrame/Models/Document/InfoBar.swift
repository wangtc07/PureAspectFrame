import Foundation

public nonisolated enum InfoSlot: String, Codable, CaseIterable, Hashable, Sendable {
    case photoTop
    case photoBottom
    case photoLeft
    case photoRight
    case frameTop
    case frameBottom
    case frameLeft
    case frameRight
}

public nonisolated enum InfoAlignment: String, Codable, Equatable, Sendable {
    case leading
    case center
    case trailing
}

public nonisolated enum InfoBrick: Codable, Equatable, Sendable {
    case fixedText(String)
    case signature
    case watermark
}

public nonisolated struct InfoRegion: Codable, Equatable, Sendable {
    public var alignment: InfoAlignment
    public var bricks: [InfoBrick]

    public init(alignment: InfoAlignment, bricks: [InfoBrick]) {
        self.alignment = alignment
        self.bricks = bricks
    }
}

public nonisolated struct InfoBar: Codable, Equatable, Sendable {
    public var spacing: Percent
    public var regions: [InfoRegion]
    /// 字高佔畫布短邊的比例。
    public var fontScale: Double

    public init(spacing: Percent, regions: [InfoRegion], fontScale: Double = 0.03) {
        self.spacing = spacing
        self.regions = Array(regions.prefix(3))
        self.fontScale = min(1, max(0, fontScale))
    }

    private enum CodingKeys: String, CodingKey {
        case spacing
        case regions
        case fontScale
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        spacing = try container.decode(Percent.self, forKey: .spacing)
        regions = Array((try container.decode([InfoRegion].self, forKey: .regions)).prefix(3))
        fontScale = min(1, max(0, try container.decodeIfPresent(Double.self, forKey: .fontScale) ?? 0.03))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(spacing, forKey: .spacing)
        try container.encode(regions, forKey: .regions)
        try container.encode(fontScale, forKey: .fontScale)
    }
}
