import Testing
import AppLaunchCore

@Suite("起動のときに出す順番")
struct LaunchQueueTests {
    @Test("優先の順に1つずつ。出している間はほかを出さない")
    func priorityOneAtATime() {
        var queue = LaunchQueue<Screen>([.importBooks, .trialOffer, .whatsNew("1.6.1")])
        #expect(queue.next == .present(.whatsNew("1.6.1")))
        queue.presented(.whatsNew("1.6.1"))
        #expect(queue.next == .busy(.whatsNew("1.6.1")))
        #expect(!queue.isIdle)
        queue.dismissed(.whatsNew("1.6.1"))
        #expect(queue.next == .present(.trialOffer))
        queue.presented(.trialOffer)
        queue.dismissed(.trialOffer)
        #expect(queue.next == .present(.importBooks))
        queue.presented(.importBooks)
        queue.dismissed(.importBooks)
        #expect(queue.next == .idle)
        #expect(queue.isIdle)
    }

    @Test("オンボーディングを出した起動では、お知らせは捨て、質問は次に回す。シートは出す")
    func onboardingDropsAndHolds() {
        var queue = LaunchQueue<Screen>([.whatsNew("1.6.1"), .question, .onboarding, .importBooks])
        #expect(queue.next == .present(.onboarding))
        #expect(queue.presented(.onboarding) == [.whatsNew("1.6.1")])
        queue.dismissed(.onboarding)
        #expect(queue.dropped == [.whatsNew("1.6.1")])
        #expect(queue.next == .present(.importBooks))
        queue.presented(.importBooks)
        queue.dismissed(.importBooks)
        #expect(queue.next == .idle)
        #expect(queue.held == [.question])
    }

    @Test("ペイウォールを出した起動では、お知らせと質問を次に回す（捨てない）")
    func paywallHolds() {
        var queue = LaunchQueue<Screen>([.whatsNew("1.6.1"), .question, .deskCard])
        queue.paywallShown()
        #expect(queue.next == .present(.deskCard))
        #expect(queue.held == [.whatsNew("1.6.1"), .question])
        #expect(queue.dropped.isEmpty)
    }

    @Test("閉じるときに決めた後続は、間にシートを挟まず出す")
    func followersComeNext() {
        var queue = LaunchQueue<Screen>([.whatsNew("1.6.1"), .deskCard])
        queue.presented(.whatsNew("1.6.1"))
        queue.dismissed(.whatsNew("1.6.1"), then: [.trialOffer])
        #expect(queue.next == .present(.trialOffer))
    }

    @Test("誘いと質問は1回の起動で合わせて1つまで。足した順")
    func oneFollowUpPerLaunch() {
        var queue = LaunchQueue<Screen>([.trialOffer, .question, .otherQuestion])
        #expect(queue.next == .present(.trialOffer))
        queue.presented(.trialOffer)
        queue.dismissed(.trialOffer)
        #expect(queue.next == .idle)
        #expect(queue.held == [.question, .otherQuestion])
    }

    @Test("お知らせの無い起動でも、前から回ってきた質問は1つ出す")
    func carriedQuestionAlone() {
        var queue = LaunchQueue<Screen>([.otherQuestion, .question])
        #expect(queue.next == .present(.otherQuestion))
        queue.presented(.otherQuestion)
        queue.dismissed(.otherQuestion)
        #expect(queue.held == [.question])
    }

    @Test("同じ物は2度入らず、取り下げた物は出さない")
    func addAndWithdraw() {
        var queue = LaunchQueue<Screen>([.deskCard, .deskCard])
        #expect(queue.waiting == [.deskCard])
        queue.presented(.deskCard)
        queue.add(.deskCard)
        #expect(queue.waiting.isEmpty)
        queue.dismissed(.deskCard)
        queue.add(.importBooks)
        queue.withdraw(.importBooks)
        #expect(queue.next == .idle)
    }

    @Test("同じ段の中は足した順")
    func insertionOrderWithinSlot() {
        let queue = LaunchQueue<Screen>([.importBooks, .deskCard])
        #expect(queue.next == .present(.importBooks))
    }
}
