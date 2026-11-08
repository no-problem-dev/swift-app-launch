import AppLaunchCore
import SwiftUI

/// Shows a release's pages one at a time: an illustration on the upper half to 60 percent, a
/// heading and one line below it, and one button.
///
/// The app draws the illustrations and supplies the words; the pager owns the rest: the close
/// button, moving between pages, Reduce Motion, and how the screen was closed.
///
/// - Every page but a permission page has a close button, so the screen can be closed at any time.
/// - A screen title (such as "What's New") may sit at the top, beside the close button. It names the
///   screen; each page keeps its one heading and one line.
/// - A page's button may move the page to a next step the app draws, such as choosing a time
///   (``WhatsNewAction/step(_:asksPermission:content:)``).
/// - Pages change with a slide, or a fade when Reduce Motion is on, and illustrations are told to
///   stand still (``WhatsNewArtContext/animates``).
/// - It reports `whats_new_shown` once when it appears and `whats_new_closed` once when it closes,
///   by the close button, the last page's button, or being pulled down.
///
/// - The release may change while on screen, such as a page added once a feature flag is known:
///   pass the new release (same version) and the pager keeps the page on screen and redraws the
///   dots (``WhatsNewSession/update(from:to:)``).
///
/// Present it full screen or in a sheet, and remove it when `onClose` is called. Style the main
/// button with `.buttonStyle(_:)` on the pager.
public struct WhatsNewPager<Page: Hashable & Sendable, Art: View>: View {

    private let release: Release<Page>
    private let title: Text?
    private let artFraction: CGFloat
    private let labels: WhatsNewLabels
    private let text: @MainActor (Page) -> WhatsNewPageText
    private let action: @MainActor (Page) -> WhatsNewAction?
    private let art: @MainActor (Page, WhatsNewArtContext) -> Art
    private let onEvent: @MainActor (WhatsNewEvent) -> Void
    private let onClose: @MainActor (WhatsNewCloseVia) -> Void

    @State private var session: WhatsNewSession
    /// The release the session follows. Changes together with the session, so a page and its
    /// position never disagree.
    @State private var shown: Release<Page>
    @State private var isPerforming = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// - Parameters:
    ///   - release: The release to show. Its pages may change while on screen; its version may not.
    ///   - title: The screen's title at the top, beside the close button, or `nil` for none. Style it
    ///     with `Text` modifiers; it is read as a header.
    ///   - artFraction: How much of the page height the illustration takes, kept between 0.5 and 0.6.
    ///   - labels: The pager's own button labels.
    ///   - onEvent: Receives `whats_new_shown` and `whats_new_closed` for analytics.
    ///   - onClose: Called once when the screen closes, with how. Remove the pager here.
    ///   - text: The heading and line for a page.
    ///   - action: A page's own main button, such as a permission request; `nil` for "Next".
    ///   - art: The illustration for a page.
    public init(
        _ release: Release<Page>,
        title: Text? = nil,
        artFraction: CGFloat = 0.6,
        labels: WhatsNewLabels = .standard,
        onEvent: @escaping @MainActor (WhatsNewEvent) -> Void = { _ in },
        onClose: @escaping @MainActor (WhatsNewCloseVia) -> Void,
        text: @escaping @MainActor (Page) -> WhatsNewPageText,
        action: @escaping @MainActor (Page) -> WhatsNewAction? = { _ in nil },
        @ViewBuilder art: @escaping @MainActor (Page, WhatsNewArtContext) -> Art
    ) {
        self.release = release
        self.title = title
        self.artFraction = min(max(artFraction, 0.5), 0.6)
        self.labels = labels
        self.text = text
        self.action = action
        self.art = art
        self.onEvent = onEvent
        self.onClose = onClose
        _session = State(initialValue: WhatsNewSession(release))
        _shown = State(initialValue: release)
    }

    private var page: Page { shown.pages[session.index] }
    private var pageAction: WhatsNewAction? { action(page) }
    private var step: WhatsNewAction.Step? { session.isInStep ? pageAction?.step : nil }
    private var asksPermission: Bool {
        if let step { return step.asksPermission }
        return pageAction?.asksPermission == true
    }

    public var body: some View {
        VStack(spacing: 0) {
            header
            if let step {
                step.content(WhatsNewStepContext(animates: !reduceMotion, finish: advance))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.opacity)
                    .accessibilityIdentifier("whatsNew.step.\(session.pageNumber)")
            } else {
                GeometryReader { proxy in
                    pageView(artHeight: proxy.size.height * artFraction)
                        .id(page)
                        .transition(reduceMotion ? .opacity : .asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }
                .clipped()
                footer
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .interactiveDismissDisabled(asksPermission)
        .onAppear {
            if let event = session.appear() { onEvent(event) }
        }
        .onChange(of: release) { _, new in
            // A closed screen is on its way out; keep drawing what was closed.
            guard session.closedVia == nil else { return }
            withAnimation(reduceMotion ? nil : .snappy) {
                session.update(from: shown, to: new)
                shown = new
            }
        }
        .onDisappear {
            // Gone without either button: pulled down, or removed by the app.
            close(via: .swipeDown)
        }
    }

    // MARK: Page

    private func pageView(artHeight: CGFloat) -> some View {
        let words = text(page)
        return VStack(spacing: 0) {
            art(page, WhatsNewArtContext(animates: !reduceMotion, index: session.index))
                .frame(maxWidth: .infinity)
                .frame(height: artHeight)
                .clipped()
                .accessibilityHidden(true)
            VStack(spacing: 10) {
                words.title
                    .font(.title2.weight(.bold))
                    .lineLimit(3)
                    .minimumScaleFactor(0.7)
                    .accessibilityAddTraits(.isHeader)
                words.message
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 24)
            .padding(.top, 20)
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("whatsNew.page.\(session.pageNumber)")
    }

    // MARK: Buttons

    private var header: some View {
        HStack {
            if let title {
                title
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("whatsNew.title")
                    .padding(.leading, 16)
            }
            Spacer()
            if !asksPermission {
                Button { close(via: .closeButton) } label: {
                    Image(systemName: "xmark")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(labels.close)
                .accessibilityIdentifier("whatsNew.close")
            }
        }
        .frame(height: 44)
        .padding(.horizontal, 8)
    }

    private var footer: some View {
        VStack(spacing: 16) {
            if shown.pages.count > 1 { dots }
            Button(action: primary) {
                (pageAction?.label ?? (session.isLast ? labels.done : labels.next))
                    .frame(maxWidth: .infinity)
            }
            .disabled(isPerforming)
            .accessibilityIdentifier("whatsNew.primary")
        }
    }

    private var dots: some View {
        HStack(spacing: 6) {
            ForEach(shown.pages.indices, id: \.self) { index in
                Capsule()
                    .fill(index == session.index ? AnyShapeStyle(.primary) : AnyShapeStyle(.tertiary))
                    .frame(width: index == session.index ? 18 : 6, height: 6)
            }
        }
        .animation(reduceMotion ? nil : .snappy, value: session.index)
        .accessibilityHidden(true)
    }

    private func primary() {
        guard let pageAction else { return advance() }
        if pageAction.opensStep {
            withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .snappy) { session.enterStep() }
            return
        }
        isPerforming = true
        Task { @MainActor in
            await pageAction.perform()
            isPerforming = false
            advance()
        }
    }

    private func advance() {
        var event: WhatsNewEvent?
        withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .snappy) {
            event = session.advance()
        }
        if let event { finish(event, via: .finished) }
    }

    private func close(via: WhatsNewCloseVia) {
        if let event = session.close(via: via) { finish(event, via: via) }
    }

    private func finish(_ event: WhatsNewEvent, via: WhatsNewCloseVia) {
        onEvent(event)
        onClose(via)
    }
}
