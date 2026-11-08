/// The kinds of thing that can appear at launch, highest priority first.
public enum LaunchSlot: Int, Hashable, Sendable, Comparable, CaseIterable {
    /// The first-run flow, including a paywall at its end.
    case onboarding
    /// What changed in this version.
    case whatsNew
    /// The app's own screen asking for a rating, typically right after what's new.
    case reviewAsk
    /// Any other single question or invitation the app wants to put to someone at launch.
    case followUp
    /// Everything else: sheets that wait until nothing above is due.
    case sheet

    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

/// Something the app may show at launch. The app's own type, usually an enum.
///
/// ```swift
/// enum LaunchScreen: LaunchItem {
///     case onboarding, whatsNew(Release<NewsPage>), reviewAsk, readingQuestion, importOldBooks
///
///     var slot: LaunchSlot {
///         switch self {
///         case .onboarding: .onboarding
///         case .whatsNew: .whatsNew
///         case .reviewAsk: .reviewAsk
///         case .readingQuestion: .followUp
///         case .importOldBooks: .sheet
///         }
///     }
/// }
/// ```
public protocol LaunchItem: Hashable, Sendable {
    /// Where the item stands in the order, and which rules apply to it.
    var slot: LaunchSlot { get }
}

/// What to do now: show an item, wait for the one on screen, or nothing.
public enum LaunchStep<Item: LaunchItem>: Hashable, Sendable {
    /// Show this item.
    case present(Item)
    /// This item is on screen. Show nothing else.
    case busy(Item)
    /// Nothing is due. Other screens may appear.
    case idle
}

/// Decides what appears at launch, one thing at a time, so screens never stack.
///
/// The app lists what could appear; the queue owns the order and the rules:
///
/// 1. One thing at a time. While an item is on screen, nothing else is due.
/// 2. Highest ``LaunchSlot`` first: onboarding, what's new, a review ask, a follow-up, then sheets.
///    Within a slot, in the order added.
/// 3. A launch that showed onboarding shows no announcements. What's new is **dropped** (someone
///    who just onboarded has nothing to catch up on); a review ask and follow-ups are **held** for
///    a later launch.
/// 4. A launch that showed a paywall holds what's new, the review ask and follow-ups for a later
///    launch.
/// 5. At most one of a review ask or a follow-up per launch. What's new may come before it; that
///    pair is the most a launch shows. The rest are held.
/// 6. Sheets are never held.
///
/// ``next`` is a pure reading of the state; the mutating methods report what happened.
public struct LaunchQueue<Item: LaunchItem>: Hashable, Sendable {

    /// Items not yet shown, in the order added.
    public private(set) var waiting: [Item]
    /// The item on screen.
    public private(set) var presenting: Item?
    /// Items this launch decided never to show.
    public private(set) var dropped: [Item] = []
    /// Whether this launch showed onboarding.
    public private(set) var hasShownOnboarding = false
    /// Whether this launch showed a paywall.
    public private(set) var hasShownPaywall = false
    /// Whether this launch showed a review ask or a follow-up.
    public private(set) var hasShownFollowUp = false

    /// - Parameter items: What could appear at this launch, in any order.
    public init(_ items: [Item] = []) {
        waiting = []
        for item in items { add(item) }
    }

    /// What to do now.
    public var next: LaunchStep<Item> {
        if let presenting { return .busy(presenting) }
        let ordered = waiting.enumerated().sorted { ($0.element.slot, $0.offset) < ($1.element.slot, $1.offset) }
        return ordered.first { isAllowed($0.element) }.map { .present($0.element) } ?? .idle
    }

    /// Whether nothing is due, so screens outside the queue may appear.
    public var isIdle: Bool { next == .idle }

    /// Items still waiting that this launch will not show. Keep them for the next launch if they
    /// should come back.
    public var held: [Item] {
        waiting.filter { !isAllowed($0) }
    }

    /// Adds an item. An item already waiting or on screen is not added twice.
    /// - Parameter item: What could appear.
    public mutating func add(_ item: Item) {
        guard item != presenting, !waiting.contains(item) else { return }
        waiting.append(item)
    }

    /// Takes an item away without showing it.
    /// - Parameter item: The item to remove.
    public mutating func withdraw(_ item: Item) {
        waiting.removeAll { $0 == item }
    }

    /// An item appeared on screen.
    ///
    /// Returns what this dropped: when onboarding appears, any waiting what's new.
    /// - Parameter item: The item now on screen.
    @discardableResult
    public mutating func presented(_ item: Item) -> [Item] {
        waiting.removeAll { $0 == item }
        presenting = item
        switch item.slot {
        case .onboarding:
            hasShownOnboarding = true
            let whatsNew = waiting.filter { $0.slot == .whatsNew }
            waiting.removeAll { $0.slot == .whatsNew }
            dropped += whatsNew
            return whatsNew
        case .reviewAsk, .followUp:
            hasShownFollowUp = true
            return []
        case .whatsNew, .sheet:
            return []
        }
    }

    /// An item left the screen.
    ///
    /// Pass what should follow it in `then`, decided before it closes, so nothing else slips in
    /// between (such as a review ask decided when what's new closes).
    /// - Parameters:
    ///   - item: The item that closed.
    ///   - followers: Items to add as it closes.
    public mutating func dismissed(_ item: Item, then followers: [Item] = []) {
        if presenting == item { presenting = nil }
        waiting.removeAll { $0 == item }
        for follower in followers { add(follower) }
    }

    /// A paywall appeared at this launch, inside the queue or outside it.
    public mutating func paywallShown() {
        hasShownPaywall = true
    }

    private func isAllowed(_ item: Item) -> Bool {
        switch item.slot {
        case .onboarding, .sheet:
            true
        case .whatsNew:
            !hasShownOnboarding && !hasShownPaywall
        case .reviewAsk, .followUp:
            !hasShownOnboarding && !hasShownPaywall && !hasShownFollowUp
        }
    }
}
