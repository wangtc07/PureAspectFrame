import Foundation
import Testing
@testable import PureAspectFrame

struct LayerStackTests {
    @Test func orderedStartsWithPhotoAndMoveBorderChangesOrder() throws {
        var stack = LayerStack()
        let first = try stack.addBorder(color: .white, sizing: .equal(Percent(5)))
        let second = try stack.addBorder(color: .black, sizing: .equal(Percent(12)))
        #expect(stack.ordered.first == .photo)
        stack.moveBorder(second, to: 0)
        #expect(stack.ordered == [.photo, .border(second), .border(first)])
        stack.removeBorder(first)
        stack.removeBorder(second)
        #expect(stack.ordered == [.photo])
        #expect(stack.removable.isEmpty)
    }

    @Test func percentClampAndSizingConversions() throws {
        #expect(Percent(80).value == 50)
        #expect(Percent(-4).value == 0)
        let perSide = BorderSizing.perSide(EdgeValues(
            top: Percent(7),
            bottom: Percent(9),
            left: Percent(3),
            right: Percent(4)
        ))
        #expect(perSide.convertedToEqual().value == 7)
        let equal = BorderSizing.equal(Percent(6)).convertedToPerSide()
        #expect(equal.top.value == 6)
        #expect(equal.bottom.value == 6)
        #expect(equal.left.value == 6)
        #expect(equal.right.value == 6)

        var stack = LayerStack()
        let driver = try stack.addBorder(color: .white, sizing: ratio(.r1x1, minimum: 5, role: .drives))
        #expect(throws: LayerEditError.twoDrivers) {
            try stack.addBorder(color: .black, sizing: ratio(.r4x5, minimum: 8, role: .drives))
        }
        #expect(stack.driverID == driver)
    }

    @Test func ratioLinkFollowsTheDriverAndDeletePromotesTheWiderFollower() throws {
        var stack = LayerStack()
        let driver = try stack.addBorder(color: .white, sizing: ratio(.r1x1, minimum: 5, role: .drives))
        let narrow = try stack.addBorder(color: .black, sizing: ratio(.r1x1, minimum: 8, role: .detached))
        let wide = try stack.addBorder(color: RGBColor(red: 0, green: 0, blue: 1), sizing: ratio(.r1x1, minimum: 12, role: .detached))
        try stack.linkRatio(follower: narrow, source: driver)
        try stack.linkRatio(follower: wide, source: driver)

        #expect(throws: LayerEditError.linkRequiresRatio) {
            var equalStack = LayerStack()
            let source = try equalStack.addBorder(color: .white, sizing: ratio(.r1x1, minimum: 5, role: .drives))
            let equal = try equalStack.addBorder(color: .black, sizing: .equal(Percent(6)))
            try equalStack.linkRatio(follower: equal, source: source)
        }

        var chain = LayerStack()
        let sourceB = try chain.addBorder(color: .white, sizing: ratio(.r1x1, minimum: 5, role: .drives))
        let followerA = try chain.addBorder(color: .black, sizing: ratio(.r1x1, minimum: 6, role: .detached))
        let otherC = try chain.addBorder(color: .white, sizing: ratio(.r4x5, minimum: 7, role: .detached))
        try chain.linkRatio(follower: followerA, source: sourceB)
        do {
            try chain.linkRatio(follower: sourceB, source: otherC)
            Issue.record("B 不該再跟著 C")
        } catch {
            #expect(chain.driverID == sourceB)
            #expect(chain.ratioLinks[sourceB] == nil)
            #expect(chain.ratioLinks[followerA] == sourceB)
        }

        try stack.setCanvasAspect(.r4x5, on: driver)
        #expect(stack.border(driver)?.sizing.ratioSizing?.aspect == .r4x5)
        #expect(stack.border(narrow)?.sizing.ratioSizing?.aspect == .r4x5)
        #expect(stack.border(wide)?.sizing.ratioSizing?.aspect == .r4x5)
        #expect(stack.driverID == driver)

        let driverColor = stack.border(driver)?.color
        let narrowColor = stack.border(narrow)?.color
        try stack.setCanvasAspect(.r3x2, on: narrow)
        #expect(stack.driverID == narrow)
        #expect(stack.border(driver)?.sizing.ratioSizing?.role == .detached)
        #expect(stack.border(driver)?.sizing.ratioSizing?.aspect == .r4x5)
        #expect(stack.border(driver)?.color == driverColor)
        #expect(stack.border(narrow)?.color == narrowColor)
        #expect(stack.border(wide)?.sizing.ratioSizing?.role == .live(narrow))

        try stack.setCanvasAspect(.r4x5, on: driver)
        #expect(stack.driverID == driver)
        #expect(stack.border(narrow)?.sizing.ratioSizing?.role == .detached)
        #expect(stack.border(wide)?.sizing.ratioSizing?.aspect == .r4x5)

        try stack.linkRatio(follower: narrow, source: driver)
        try stack.linkRatio(follower: wide, source: driver)
        try stack.unlinkRatio(narrow)
        #expect(stack.driverID == driver)
        #expect(stack.border(narrow)?.sizing.ratioSizing?.role == .detached)
        #expect(stack.ratioLinks[narrow] == nil)
        #expect(stack.border(narrow)?.sizing.ratioSizing?.aspect == .r4x5)

        try stack.linkRatio(follower: narrow, source: driver)
        stack.removeBorder(driver)
        #expect(stack.border(driver) == nil)
        #expect(stack.driverID == wide)
        #expect(stack.border(wide)?.sizing.ratioSizing?.aspect == .r4x5)
        #expect(stack.border(narrow)?.sizing.ratioSizing?.role == .detached)
        #expect(stack.border(narrow)?.sizing.ratioSizing?.aspect == .r4x5)
        #expect(stack.ratioLinks.isEmpty)
        stack.normalizeLinks()
        #expect(stack.driverID == wide)
    }

    @Test func infoSlotReplacesAndRefusesANinthBar() throws {
        #expect(InfoSlot.allCases.count == 8)
        var stack = LayerStack()
        let first = InfoBar(spacing: Percent(0), regions: [
            InfoRegion(alignment: .leading, bricks: [.fixedText("左")]),
            InfoRegion(alignment: .center, bricks: [.signature]),
            InfoRegion(alignment: .trailing, bricks: [.watermark]),
            InfoRegion(alignment: .leading, bricks: [.fixedText("丟掉")])
        ])
        #expect(first.regions.count == 3)
        stack.setInfo(first, at: .photoTop)
        stack.setInfo(InfoBar(spacing: Percent(2), regions: []), at: .photoTop)
        #expect(stack.infos.count == 1)
        #expect(stack.infos[.photoTop]?.spacing.value == 2)

        for slot in InfoSlot.allCases {
            stack.setInfo(InfoBar(spacing: Percent(0), regions: []), at: slot)
        }
        #expect(stack.infos.count == 8)
        #expect(throws: LayerEditError.noEmptyInfoSlot) {
            try stack.addInfo(InfoBar(spacing: Percent(1), regions: []))
        }
        #expect(stack.infos.count == 8)
    }

    @Test func splitCountClampsAndPlatformsOmitRedBook() throws {
        #expect(SplitLayer(count: 12, gap: .platform(.instagram)).count == 10)
        let encoded = try JSONEncoder().encode(SplitLayer(count: 2, gap: .custom(Percent(1))))
        var object = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        object["count"] = 12
        let rewritten = try JSONSerialization.data(withJSONObject: object)
        let decoded = try JSONDecoder().decode(SplitLayer.self, from: rewritten)
        #expect(decoded.count == 10)
        #expect(decoded.gap == .custom(Percent(1)))

        #expect(SNSPlatform.allCases.count == 3)
        let names = SNSPlatform.allCases.map(\.rawValue)
        #expect(names == ["instagram", "threads", "x"])
    }
}

private func ratio(_ aspect: CanvasAspect, minimum: Double, role: RatioRole) -> BorderSizing {
    let edge = Percent(minimum)
    return .ratio(RatioSizing(
        aspect: aspect,
        minimum: EdgeValues(top: edge, bottom: edge, left: edge, right: edge),
        role: role
    ))
}
