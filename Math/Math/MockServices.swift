import Foundation

// MARK: - In-Memory User Store

actor UserStoreMock {
    private(set) var users: [String: AppUser] = [:] // key: userId
    private var usernameIndex: [String: String] = [:] // username -> userId
    private(set) var friendships: [String: Friendship] = [:] // id -> friendship
    private(set) var dailyScores: [String: [String: Int]] = [:] // userId -> [yyyy-MM-dd: score]

    func upsertUser(_ user: AppUser) {
        users[user.id] = user
        usernameIndex[user.username.lowercased()] = user.id
    }

    func getUser(id: String) -> AppUser? { users[id] }

    func findUser(byUsername username: String) -> AppUser? {
        guard let uid = usernameIndex[username.lowercased()] else { return nil }
        return users[uid]
    }

    func isUsernameAvailable(_ username: String) -> Bool {
        usernameIndex[username.lowercased()] == nil
    }

    func setUsername(userId: String, username: String) -> Bool {
        guard isUsernameAvailable(username), var u = users[userId] else { return false }
        // remove old index
        usernameIndex[u.username.lowercased()] = nil
        u.username = username
        users[userId] = u
        usernameIndex[username.lowercased()] = userId
        return true
    }

    // MARK: Friendships

    func addFriendship(requesterId: String, addresseeId: String) -> Friendship {
        let id = UUID().uuidString
        let f = Friendship(id: id, requesterId: requesterId, addresseeId: addresseeId, status: .accepted, createdAt: Date())
        friendships[id] = f
        return f
    }

    func removeFriendship(between a: String, and b: String) {
        friendships = friendships.filter { !isPair($0.value, a, b) }
    }

    func listFriends(of userId: String) -> [AppUser] {
        let pairs = friendships.values.filter {
            $0.status == .accepted && ( $0.requesterId == userId || $0.addresseeId == userId )
        }
        let friendIds = pairs.map { $0.requesterId == userId ? $0.addresseeId : $0.requesterId }
        return friendIds.compactMap { users[$0] }
    }

    private func isPair(_ f: Friendship, _ a: String, _ b: String) -> Bool {
        (f.requesterId == a && f.addresseeId == b) || (f.requesterId == b && f.addresseeId == a)
    }

    // MARK: Scores & Streak

    func saveScore(userId: String, dateKey: String, score: Int) {
        var map = dailyScores[userId] ?? [:]
        map[dateKey] = max(score, map[dateKey] ?? 0)
        dailyScores[userId] = map
    }

    func getScore(userId: String, dateKey: String) -> Int? {
        dailyScores[userId]?[dateKey]
    }

    func getAllTimeHigh(userId: String) -> Int {
        let map = dailyScores[userId] ?? [:]
        return map.values.max() ?? 0
    }
}

// MARK: - Auth Service Mock

actor AuthServiceMock {
    private let userStore: UserStoreMock
    private(set) var currentUser: AppUser?

    init(userStore: UserStoreMock) {
        self.userStore = userStore
    }

    func signIn(provider: String) async -> AppUser {
        // Create or return a mock user per provider
        let baseName: String
        switch provider {
        case "apple": baseName = "apple_user"
        case "google": baseName = "google_user"
        default: baseName = "guest"
        }
        let uid = UUID().uuidString
        let username = uniqueUsername(baseName)
        let user = AppUser(
            id: uid,
            username: username,
            displayName: provider.capitalized + " User",
            photoURL: nil,
            createdAt: Date(),
            allTimeHigh: 0,
            streak: 0,
            lastPlayDate: nil
        )
        await userStore.upsertUser(user)
        currentUser = user
        return user
    }

    func signOut() {
        currentUser = nil
    }

    private func uniqueUsername(_ base: String) -> String {
        let suffix = Int.random(in: 1000...9999)
        return "\(base)_\(suffix)"
    }
}

// MARK: - Friend Service Mock

actor FriendServiceMock {
    private let store: UserStoreMock

    init(store: UserStoreMock) {
        self.store = store
    }

    func search(username: String) async -> AppUser? {
        await store.findUser(byUsername: username)
    }

    func addFriend(selfId: String, friendId: String) async {
        _ = await store.addFriendship(requesterId: selfId, addresseeId: friendId)
    }

    func removeFriend(selfId: String, friendId: String) async {
        await store.removeFriendship(between: selfId, and: friendId)
    }

    func listFriends(selfId: String) async -> [AppUser] {
        await store.listFriends(of: selfId)
    }
}

// MARK: - Score/Streak Service Mock

actor ScoreServiceMock {
    private let store: UserStoreMock

    init(store: UserStoreMock) {
        self.store = store
    }

    func submitScore(userId: String, score: Int, on date: Date) async -> (allTimeHigh: Int, streak: Int) {
        let key = Self.dayKey(for: date)
        await store.saveScore(userId: userId, dateKey: key, score: score)
        let allTime = await store.getAllTimeHigh(userId: userId)

        // Streak calculation
        var streak = 1
        if var u = await store.getUser(id: userId) {
            if let last = u.lastPlayDate {
                let cal = Calendar.current
                if cal.isDate(date, inSameDayAs: last) {
                    // already counted today
                    streak = u.streak
                } else if let yesterday = cal.date(byAdding: .day, value: -1, to: date),
                          cal.isDate(last, inSameDayAs: yesterday) {
                    streak = u.streak + 1
                } else {
                    streak = 1
                }
            }
            u.streak = streak
            u.lastPlayDate = date
            u.allTimeHigh = max(u.allTimeHigh, allTime)
            await store.upsertUser(u)
        }
        return (allTime, streak)
    }

    static func dayKey(for date: Date) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}

// MARK: - Leaderboard Service Mock

actor LeaderboardServiceMock {
    private let store: UserStoreMock

    init(store: UserStoreMock) {
        self.store = store
    }

    func globalTop(limit: Int = 50) async -> [LeaderboardEntry] {
        let users = await store.users.values
        let sorted = users.sorted { $0.allTimeHigh > $1.allTimeHigh }
        return Array(sorted.prefix(limit)).enumerated().map { idx, u in
            LeaderboardEntry(id: u.id, userId: u.id, username: u.username, displayName: u.displayName, score: u.allTimeHigh, rank: idx + 1)
        }
    }

    func friendsTop(selfId: String, limit: Int = 50) async -> [LeaderboardEntry] {
        let friends = await store.listFriends(of: selfId)
        let me = await store.getUser(id: selfId)
        let list = ([me].compactMap { $0 } + friends).unique(by: \.id)
        let sorted = list.sorted { $0.allTimeHigh > $1.allTimeHigh }
        return Array(sorted.prefix(limit)).enumerated().map { idx, u in
            LeaderboardEntry(id: u.id, userId: u.id, username: u.username, displayName: u.displayName, score: u.allTimeHigh, rank: idx + 1)
        }
    }
}

private extension Array {
    func unique<ID: Hashable>(by keyPath: KeyPath<Element, ID>) -> [Element] {
        var seen = Set<ID>()
        return self.filter { seen.insert($0[keyPath: keyPath]).inserted }
    }
}

// MARK: - Notification Mock

actor NotificationManagerMock {
    private(set) var scheduledHour: Int? = nil
    private(set) var scheduledMinute: Int? = nil

    func scheduleDaily(hour: Int, minute: Int) async {
        scheduledHour = hour
        scheduledMinute = minute
    }

    func cancelAll() async {
        scheduledHour = nil
        scheduledMinute = nil
    }
}
