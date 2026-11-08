import Foundation
import Testing
@testable import AppLaunchCore

@Suite("起動ごとの記録と持ち越し")
struct WhatsNewTrackerTests {
    private func tracker(_ record: LaunchRecord = LaunchRecord()) -> (WhatsNewTracker<NewsPage>, InMemoryLaunchRecordStore) {
        let store = InMemoryLaunchRecordStore(record)
        return (WhatsNewTracker(catalog: Fixture.catalog, store: store), store)
    }

    @Test("新しく入れた最初の起動では出さず、版を記録する")
    func freshInstall() {
        let (tracker, store) = tracker()
        let start = tracker.begin(currentVersion: "1.8.0")
        #expect(start == LaunchStart(change: .fresh, release: nil))
        #expect(store.record == LaunchRecord(lastLaunchedVersion: "1.8.0"))
    }

    @Test("更新した最初の起動で出し、閉じるまで持ち越す")
    func carriesUntilSettled() {
        let (tracker, store) = tracker(LaunchRecord(lastLaunchedVersion: "1.6.0"))
        #expect(tracker.begin(currentVersion: "1.6.1").release == Fixture.v161)
        #expect(store.record.pendingRelease == "1.6.1")

        // The app was closed before the release was: the next launch shows it again.
        let again = tracker.begin(currentVersion: "1.6.1")
        #expect(again == LaunchStart(change: .same, release: Fixture.v161))
        #expect(tracker.pending == Fixture.v161)

        tracker.settle()
        #expect(tracker.begin(currentVersion: "1.6.1").release == nil)
        #expect(store.record == LaunchRecord(lastLaunchedVersion: "1.6.1"))
    }

    @Test("出せなかった版のまま新しい版に上げたら、新しい方だけ")
    func newerReplacesCarried() {
        let (tracker, _) = tracker(LaunchRecord(lastLaunchedVersion: "1.6.0", pendingRelease: "1.6.0"))
        #expect(tracker.begin(currentVersion: "1.8.0").release == Fixture.v180)
    }

    @Test("記録の無い前の利用は、渡した版からの更新")
    func untrackedEarlierUse() {
        let (tracker, _) = tracker()
        let start = tracker.begin(currentVersion: "1.6.1", untrackedEarlierUse: "1.5")
        #expect(start == LaunchStart(change: .upgraded(from: "1.5"), release: Fixture.v161))
    }

    @Test("記録があれば、前の利用の手がかりは見ない")
    func recordWins() {
        let (tracker, _) = tracker(LaunchRecord(lastLaunchedVersion: "1.6.1"))
        #expect(tracker.begin(currentVersion: "1.6.1", untrackedEarlierUse: "1.5").release == nil)
    }

    @Test("読めない版の起動では何も書かず、何も出さない")
    func unreadableVersion() {
        let (tracker, store) = tracker(LaunchRecord(lastLaunchedVersion: "1.6.0", pendingRelease: "1.6.0"))
        #expect(tracker.begin(currentVersion: "dev") == LaunchStart(change: .same, release: nil))
        #expect(store.record == LaunchRecord(lastLaunchedVersion: "1.6.0", pendingRelease: "1.6.0"))
    }

    @Test("UserDefaults に文字列のまま、渡したキーで残す")
    func userDefaultsStore() throws {
        let suite = "swift-app-launch.tests.\(UUID().uuidString)"
        defer { UserDefaults().removePersistentDomain(forName: suite) }
        let store = try #require(UserDefaultsLaunchRecordStore(suiteName: suite, lastLaunchedVersionKey: "last", pendingReleaseKey: "pending"))
        #expect(store.load() == LaunchRecord())

        store.save(LaunchRecord(lastLaunchedVersion: "1.6.0", pendingRelease: "1.6.0"))
        let defaults = try #require(UserDefaults(suiteName: suite))
        #expect(defaults.string(forKey: "last") == "1.6.0")
        #expect(defaults.string(forKey: "pending") == "1.6.0")

        store.save(LaunchRecord(lastLaunchedVersion: "1.6.1"))
        #expect(defaults.object(forKey: "pending") == nil)
        #expect(store.load() == LaunchRecord(lastLaunchedVersion: "1.6.1"))
    }

    @Test("アプリが持っている UserDefaults に、そのまま読み書きする")
    func userDefaultsInstance() throws {
        let suite = "swift-app-launch.tests.\(UUID().uuidString)"
        defer { UserDefaults().removePersistentDomain(forName: suite) }
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.set("1.5.0", forKey: "appVersion")

        let store = UserDefaultsLaunchRecordStore(defaults: defaults, lastLaunchedVersionKey: "appVersion")
        #expect(store.load() == LaunchRecord(lastLaunchedVersion: "1.5.0"))

        store.save(LaunchRecord(lastLaunchedVersion: "1.6.0", pendingRelease: "1.6.0"))
        #expect(defaults.string(forKey: "appVersion") == "1.6.0")
        #expect(defaults.string(forKey: "whatsNew.pending") == "1.6.0")
    }

    @Test("settle は待っているお知らせだけを消し、読んだだけの版を端末に書き戻さない")
    func settleLeavesVersionUnwritten() throws {
        let suite = "swift-app-launch.tests.\(UUID().uuidString)"
        defer { UserDefaults().removePersistentDomain(forName: suite) }
        let defaults = try #require(UserDefaults(suiteName: suite))
        let store = UserDefaultsLaunchRecordStore(defaults: defaults)
        let tracker = WhatsNewTracker(catalog: Fixture.catalog, store: store)
        #expect(tracker.begin(currentVersion: "1.6.1", untrackedEarlierUse: "1.6.0").release == Fixture.v161)

        // A test passes the previous version as a launch argument: read, but not kept on the device.
        defaults.removeObject(forKey: "launch.lastVersion")
        defaults.register(defaults: ["launch.lastVersion": "1.5.0"])
        tracker.settle()

        let kept = defaults.persistentDomain(forName: suite) ?? [:]
        #expect(kept["launch.lastVersion"] == nil)
        #expect(kept["whatsNew.pending"] == nil)
        #expect(tracker.pending == nil)
    }

    @Test("自前の保存先は、既定の save(pendingRelease:) で版を残したまま消せる")
    func settleThroughDefaultImplementation() {
        final class Recording: LaunchRecordStore, @unchecked Sendable {
            var record = LaunchRecord(lastLaunchedVersion: "1.6.1", pendingRelease: "1.6.1")
            func load() -> LaunchRecord { record }
            func save(_ record: LaunchRecord) { self.record = record }
        }
        let store = Recording()
        WhatsNewTracker(catalog: Fixture.catalog, store: store).settle()
        #expect(store.record == LaunchRecord(lastLaunchedVersion: "1.6.1"))
    }
}

@Suite("バンドルから版を読む")
struct BundleVersionTests {
    private func bundle(version: String?) throws -> Bundle {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).bundle")
        let contents = root.appendingPathComponent("Contents")
        try FileManager.default.createDirectory(at: contents, withIntermediateDirectories: true)
        var info: [String: Any] = ["CFBundleIdentifier": "test.\(UUID().uuidString)"]
        if let version { info["CFBundleShortVersionString"] = version }
        let data = try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0)
        try data.write(to: contents.appendingPathComponent("Info.plist"))
        return try #require(Bundle(url: root))
    }

    @Test("CFBundleShortVersionString を使う")
    func readsVersion() throws {
        let store = InMemoryLaunchRecordStore(LaunchRecord(lastLaunchedVersion: "1.6.0"))
        let tracker = WhatsNewTracker(catalog: Fixture.catalog, store: store)
        #expect(tracker.begin(bundle: try bundle(version: "1.6.1")).release == Fixture.v161)
    }

    @Test("版の無いバンドルでは何も書かない")
    func noVersion() throws {
        let store = InMemoryLaunchRecordStore(LaunchRecord(lastLaunchedVersion: "1.6.0"))
        let tracker = WhatsNewTracker(catalog: Fixture.catalog, store: store)
        #expect(tracker.begin(bundle: try bundle(version: nil)).release == nil)
        #expect(store.record == LaunchRecord(lastLaunchedVersion: "1.6.0"))
    }
}

@Suite("まだお知らせの無いアプリ")
struct EmptyCatalogTests {

    @Test("空のカタログは何も出さないが、起動ごとの版は残す")
    func recordsVersionsWithoutReleases() {
        let store = InMemoryLaunchRecordStore(LaunchRecord(lastLaunchedVersion: "1.0.3"))
        let tracker = WhatsNewTracker<Never>(catalog: .empty, store: store)
        #expect(tracker.catalog.releases.isEmpty)
        #expect(tracker.begin(currentVersion: "1.1.0") == LaunchStart(change: .upgraded(from: "1.0.3"), release: nil))
        #expect(store.record == LaunchRecord(lastLaunchedVersion: "1.1.0"))
    }

    @Test("空のカタログは配列リテラルの [] と同じ")
    func sameAsEmptyLiteral() {
        let literal: ReleaseCatalog<NewsPage> = []
        #expect(ReleaseCatalog<NewsPage>.empty == literal)
    }
}
