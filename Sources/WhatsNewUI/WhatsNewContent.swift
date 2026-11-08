import SwiftUI

/// The words on one page: a heading and one short line. Never a list.
public struct WhatsNewPageText {
    /// The heading, large and short.
    public let title: Text
    /// One short line under the heading.
    public let message: Text

    /// - Parameters:
    ///   - title: The heading.
    ///   - message: One short line under the heading.
    public init(title: Text, message: Text) {
        self.title = title
        self.message = message
    }
}

/// A page's own main button, in place of "Next".
///
/// The only place a what's-new screen asks for a permission is the page that shows the feature
/// needing it, through ``permission(_:request:)``.
public struct WhatsNewAction {
    /// The button's label.
    public let label: Text
    /// Whether the button leads to a system permission dialog.
    public let asksPermission: Bool
    let perform: @MainActor () async -> Void

    /// A button that asks for a permission, then moves on whatever the answer.
    ///
    /// On this page the close button is hidden and the screen cannot be pulled down: an
    /// explanation before a permission dialog must lead to the dialog, and declining happens there
    /// (App Review Guideline 5.1.1(iv)).
    /// - Parameters:
    ///   - label: The button's label, naming what is asked (such as "Allow step count").
    ///   - request: Shows the system dialog and returns when it is answered.
    public static func permission(_ label: Text, request: @escaping @MainActor () async -> Void) -> WhatsNewAction {
        WhatsNewAction(label: label, asksPermission: true, perform: request)
    }

    /// A button that does something of the app's, then moves on.
    /// - Parameters:
    ///   - label: The button's label.
    ///   - body: The work to do before moving on.
    public static func perform(_ label: Text, _ body: @escaping @MainActor () async -> Void) -> WhatsNewAction {
        WhatsNewAction(label: label, asksPermission: false, perform: body)
    }
}

/// What an illustration needs to know to draw itself.
public struct WhatsNewArtContext: Hashable, Sendable {
    /// Whether to move. `false` when Reduce Motion is on: draw the finished state and stay still.
    public let animates: Bool
    /// The page's position, from 0.
    public let index: Int

    public init(animates: Bool, index: Int) {
        self.animates = animates
        self.index = index
    }
}

/// The labels the pager uses for its own buttons.
public struct WhatsNewLabels {
    /// The main button on every page but the last.
    public var next: Text
    /// The main button on the last page.
    public var done: Text
    /// The close button's accessibility label.
    public var close: Text

    /// - Parameters:
    ///   - next: The main button on every page but the last.
    ///   - done: The main button on the last page.
    ///   - close: The close button's accessibility label.
    public init(next: Text, done: Text, close: Text) {
        self.next = next
        self.done = done
        self.close = close
    }

    /// The package's own labels, in English and Japanese.
    public static var standard: WhatsNewLabels {
        WhatsNewLabels(
            next: Text(WhatsNewStrings.next),
            done: Text(WhatsNewStrings.done),
            close: Text(WhatsNewStrings.close)
        )
    }
}

enum WhatsNewStrings {
    static var next: String { String(localized: "whats_new.next", bundle: .module) }
    static var done: String { String(localized: "whats_new.done", bundle: .module) }
    static var close: String { String(localized: "whats_new.close", bundle: .module) }
}
