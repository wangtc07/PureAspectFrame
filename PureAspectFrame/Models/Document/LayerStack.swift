import Foundation

public nonisolated enum LayerEditError: Error, Equatable {
    case twoDrivers
    case linkRequiresRatio
    case sourceMustBeDriver
    case sourceCannotFollow
    case missingBorder
    case noEmptyInfoSlot
}

public nonisolated enum LayerRef: Equatable, Sendable {
    case photo
    case border(BorderRing.ID)
    case info(InfoSlot)
    case split
}

public nonisolated enum RemovableLayer: Equatable, Sendable {
    case border(BorderRing.ID)
    case info(InfoSlot)
    case split
}

public nonisolated struct LayerStack: Codable, Equatable, Sendable {
    public var photo: PhotoLayer
    public private(set) var borders: [BorderRing]
    public private(set) var infos: [InfoSlot: InfoBar]
    public private(set) var split: SplitLayer?
    public private(set) var ratioLinks: [BorderRing.ID: BorderRing.ID]

    public init(photo: PhotoLayer = PhotoLayer()) {
        self.photo = photo
        borders = []
        infos = [:]
        split = nil
        ratioLinks = [:]
    }

    public var ordered: [LayerRef] {
        var refs: [LayerRef] = [.photo]
        refs.append(contentsOf: borders.map { .border($0.id) })
        refs.append(contentsOf: InfoSlot.allCases.compactMap { infos[$0] == nil ? nil : .info($0) })
        if split != nil {
            refs.append(.split)
        }
        return refs
    }

    public var removable: [RemovableLayer] {
        var refs = borders.map { RemovableLayer.border($0.id) }
        refs.append(contentsOf: InfoSlot.allCases.compactMap { infos[$0] == nil ? nil : .info($0) })
        if split != nil {
            refs.append(.split)
        }
        return refs
    }

    public var driverID: BorderRing.ID? {
        borders.first { $0.sizing.isDriving }?.id
    }

    public func border(_ id: BorderRing.ID) -> BorderRing? {
        borders.first { $0.id == id }
    }

    @discardableResult
    public mutating func addBorder(color: RGBColor, opacity: Double = 1, sizing: BorderSizing) throws -> BorderRing.ID {
        if sizing.isDriving, driverID != nil {
            throw LayerEditError.twoDrivers
        }
        let ring = BorderRing(color: color, opacity: opacity, sizing: sizing)
        borders.append(ring)
        return ring.id
    }

    public mutating func moveBorder(_ id: BorderRing.ID, to newIndex: Int) {
        guard let current = borders.firstIndex(where: { $0.id == id }) else { return }
        let ring = borders.remove(at: current)
        let destination = min(max(0, newIndex), borders.count)
        borders.insert(ring, at: destination)
    }

    public mutating func removeBorder(_ id: BorderRing.ID) {
        guard let ring = border(id) else { return }
        let followerIDs = ratioLinks.filter { $0.value == id }.map(\.key)
        let wasDriver = ring.sizing.isDriving
        borders.removeAll { $0.id == id }
        ratioLinks = ratioLinks.filter { $0.key != id && $0.value != id }
        guard wasDriver else { return }

        let candidates = borders.filter { followerIDs.contains($0.id) }
        let winnerID = candidates.max { lhs, rhs in
            let leftReach = lhs.sizing.reach()
            let rightReach = rhs.sizing.reach()
            if leftReach != rightReach { return leftReach < rightReach }
            let leftIndex = borders.firstIndex { $0.id == lhs.id } ?? 0
            let rightIndex = borders.firstIndex { $0.id == rhs.id } ?? 0
            return leftIndex < rightIndex
        }?.id
        for index in borders.indices where followerIDs.contains(borders[index].id) {
            if borders[index].id == winnerID {
                setRole(.drives, at: index)
            } else {
                setRole(.detached, at: index)
            }
        }
        ratioLinks = [:]
    }

    public mutating func setAppearance(color: RGBColor, opacity: Double, on id: BorderRing.ID) {
        guard let index = index(of: id) else { return }
        borders[index].color = color
        borders[index].opacity = min(1, max(0, opacity))
    }

    public mutating func setSizing(_ sizing: BorderSizing, on id: BorderRing.ID) throws {
        guard let index = index(of: id) else { throw LayerEditError.missingBorder }
        if sizing.isDriving, let driverID, driverID != id {
            throw LayerEditError.twoDrivers
        }
        borders[index].sizing = sizing
        if !sizing.isDriving {
            ratioLinks = ratioLinks.filter { $0.value != id }
        }
        normalizeLinks()
    }

    public mutating func setCanvasAspect(_ aspect: CanvasAspect, on id: BorderRing.ID) throws {
        guard let index = index(of: id) else { throw LayerEditError.missingBorder }
        let previousDriver = driverID
        if previousDriver == id {
            updateAspect(aspect, at: index)
            syncFollowers(of: id, to: aspect)
            return
        }

        let minimum = borders[index].sizing.convertedToPerSide()
        borders[index].sizing = .ratio(RatioSizing(aspect: aspect, minimum: minimum, role: .drives))
        if let previousDriver, let driverIndex = self.index(of: previousDriver) {
            setRole(.detached, at: driverIndex)
        }
        var links: [BorderRing.ID: BorderRing.ID] = [:]
        for (follower, source) in ratioLinks where follower != id && source == previousDriver {
            guard let followerIndex = self.index(of: follower) else { continue }
            setLive(aspect, source: id, at: followerIndex)
            links[follower] = id
        }
        ratioLinks = links
    }

    public mutating func linkRatio(follower: BorderRing.ID, source: BorderRing.ID) throws {
        guard let followerIndex = index(of: follower), let sourceIndex = index(of: source) else {
            throw LayerEditError.missingBorder
        }
        guard borders[followerIndex].sizing.ratioSizing != nil else {
            throw LayerEditError.linkRequiresRatio
        }
        guard borders[sourceIndex].sizing.isDriving else {
            throw LayerEditError.sourceMustBeDriver
        }
        let sourceIsFollowed = ratioLinks.values.contains(follower) || borders[followerIndex].sizing.isDriving
        let sourceAlreadyFollows = ratioLinks[source] != nil
        if follower == source || sourceIsFollowed || sourceAlreadyFollows {
            throw LayerEditError.sourceCannotFollow
        }
        guard let aspect = borders[sourceIndex].sizing.ratioSizing?.aspect else {
            throw LayerEditError.sourceMustBeDriver
        }
        setLive(aspect, source: source, at: followerIndex)
        ratioLinks[follower] = source
    }

    public mutating func unlinkRatio(_ id: BorderRing.ID) throws {
        guard let index = index(of: id) else { throw LayerEditError.missingBorder }
        guard borders[index].sizing.ratioSizing != nil else { throw LayerEditError.linkRequiresRatio }
        if borders[index].sizing.isDriving { return }
        setRole(.detached, at: index)
        ratioLinks[id] = nil
    }

    public mutating func normalizeLinks() {
        let driverIndexes = borders.indices.filter { borders[$0].sizing.isDriving }
        for index in driverIndexes.dropFirst() {
            setRole(.detached, at: index)
        }
        guard let driver = borders.first(where: { $0.sizing.isDriving }) else {
            ratioLinks = [:]
            for index in borders.indices {
                if borders[index].sizing.ratioSizing?.role != nil {
                    setRole(.detached, at: index)
                }
            }
            return
        }
        guard let aspect = border(driver.id)?.sizing.ratioSizing?.aspect else {
            ratioLinks = [:]
            return
        }
        var links: [BorderRing.ID: BorderRing.ID] = [:]
        for index in borders.indices {
            guard case .ratio(var sizing) = borders[index].sizing else { continue }
            switch sizing.role {
            case .drives:
                continue
            case .live(let source) where source == driver.id && borders[index].id != driver.id:
                sizing.aspect = aspect
                sizing.role = .live(driver.id)
                borders[index].sizing = .ratio(sizing)
                links[borders[index].id] = driver.id
            default:
                sizing.role = .detached
                borders[index].sizing = .ratio(sizing)
            }
        }
        ratioLinks = links
    }

    public mutating func removeInfo(_ slot: InfoSlot) {
        infos[slot] = nil
    }

    public mutating func setInfo(_ bar: InfoBar, at slot: InfoSlot) {
        infos[slot] = bar
    }

    public mutating func addInfo(_ bar: InfoBar) throws {
        guard infos.count < InfoSlot.allCases.count,
              let slot = InfoSlot.allCases.first(where: { infos[$0] == nil }) else {
            throw LayerEditError.noEmptyInfoSlot
        }
        infos[slot] = bar
    }

    public mutating func setSplit(_ split: SplitLayer?) {
        self.split = split
    }

    private func index(of id: BorderRing.ID) -> Int? {
        borders.firstIndex { $0.id == id }
    }

    private mutating func updateAspect(_ aspect: CanvasAspect, at index: Int) {
        guard case .ratio(var sizing) = borders[index].sizing else { return }
        sizing.aspect = aspect
        borders[index].sizing = .ratio(sizing)
    }

    private mutating func syncFollowers(of source: BorderRing.ID, to aspect: CanvasAspect) {
        for index in borders.indices {
            guard case .ratio(var sizing) = borders[index].sizing else { continue }
            guard case .live(let liveSource) = sizing.role, liveSource == source else { continue }
            sizing.aspect = aspect
            borders[index].sizing = .ratio(sizing)
        }
    }

    private mutating func setLive(_ aspect: CanvasAspect, source: BorderRing.ID, at index: Int) {
        guard case .ratio(var sizing) = borders[index].sizing else { return }
        sizing.aspect = aspect
        sizing.role = .live(source)
        borders[index].sizing = .ratio(sizing)
    }

    private mutating func setRole(_ role: RatioRole, at index: Int) {
        guard case .ratio(var sizing) = borders[index].sizing else { return }
        sizing.role = role
        borders[index].sizing = .ratio(sizing)
    }
}
