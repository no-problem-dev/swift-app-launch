import AppLaunchCore

enum Screen: LaunchItem {
    case onboarding
    case whatsNew(String)
    case trialOffer
    case question
    case otherQuestion
    case importBooks
    case deskCard

    var slot: LaunchSlot {
        switch self {
        case .onboarding: .onboarding
        case .whatsNew: .whatsNew
        case .trialOffer, .question, .otherQuestion: .followUp
        case .importBooks, .deskCard: .sheet
        }
    }
}
