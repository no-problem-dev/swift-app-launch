import AppLaunchCore

enum NewsPage: Hashable, Sendable {
    case unlimitedBooks, memoOnShelf, reminder, yearCards, yearNotes
}

enum Fixture {
    static let v160 = Release(version: "1.6.0", pages: [NewsPage.unlimitedBooks, .memoOnShelf, .reminder])
    static let v161 = Release(version: "1.6.1", pages: [NewsPage.yearCards, .yearNotes])
    static let v180 = Release(version: "1.8.0", pages: [NewsPage.memoOnShelf])
    static let catalog: ReleaseCatalog<NewsPage> = [v180, v160, v161]
}

enum Screen: LaunchItem {
    case onboarding
    case whatsNew(String)
    case reviewAsk
    case question
    case otherQuestion
    case importBooks
    case deskCard

    var slot: LaunchSlot {
        switch self {
        case .onboarding: .onboarding
        case .whatsNew: .whatsNew
        case .reviewAsk: .reviewAsk
        case .question, .otherQuestion: .followUp
        case .importBooks, .deskCard: .sheet
        }
    }
}
