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
    /// The page's next step, for ``step(_:asksPermission:content:)``.
    var step: Step?

    struct Step {
        let asksPermission: Bool
        let content: @MainActor (WhatsNewStepContext) -> AnyView
    }

    /// Whether the button moves the page to its next step instead of moving on.
    public var opensStep: Bool { step != nil }

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

extension WhatsNewAction {
    /// A button that moves the page to its next step, drawn by the app, in place of the next page.
    ///
    /// For setting up the feature the page just showed, such as choosing a time for a reminder and
    /// then asking for notifications. The step takes the page's place, without the dots and the main
    /// button; it moves on by calling ``WhatsNewStepContext/finish()``.
    ///
    /// The screen's rules still hold in the step: no price, plan or purchase invitation, and no
    /// "Later" before a permission dialog. A step that leads to a permission dialog passes
    /// `asksPermission: true`: the close button is hidden and the screen cannot be pulled down
    /// there, and declining happens in the dialog (App Review Guideline 5.1.1(iv)). Otherwise the
    /// close button stays, and it is the way out of the step.
    /// - Parameters:
    ///   - label: The page's button, naming the step (such as "Choose a time").
    ///   - asksPermission: Whether the step leads to a system permission dialog.
    ///   - content: The step, given how to move on.
    public static func step<Content: View>(
        _ label: Text,
        asksPermission: Bool = false,
        @ViewBuilder content: @escaping @MainActor (WhatsNewStepContext) -> Content
    ) -> WhatsNewAction {
        WhatsNewAction(
            label: label,
            asksPermission: false,
            perform: {},
            step: Step(asksPermission: asksPermission, content: { AnyView(content($0)) })
        )
    }
}

/// What a page's next step needs: whether to move, and how to move on.
@MainActor
public struct WhatsNewStepContext {
    /// Whether to move. `false` when Reduce Motion is on.
    public let animates: Bool
    private let onFinish: @MainActor () -> Void

    /// - Parameters:
    ///   - animates: Whether to move.
    ///   - finish: Moves on to the next page, or closes the screen on the last one.
    public init(animates: Bool, finish: @escaping @MainActor () -> Void) {
        self.animates = animates
        self.onFinish = finish
    }

    /// Moves on to the next page, or closes the screen on the last one, as the page's button would.
    public func finish() { onFinish() }
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
