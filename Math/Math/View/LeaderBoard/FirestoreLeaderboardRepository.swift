import Foundation
import FirebaseFirestore
import FirebaseFirestoreCombineSwift

struct FirestoreLeaderboardRepository {
    private let db = Firestore.firestore()
    private let usersCollection = "users"
    private let friendshipsCollection = "friendships"

    // Top N global users by allTimeHigh. Default limit 100.
    func globalTop(limit: Int = 100) async throws -> [LeaderboardEntry] {
        let snapshot = try await db.collection(usersCollection)
            .order(by: "allTimeHigh", descending: true)
            .limit(to: limit)
            .getDocuments()

        // Map to entries and assign ranks by order
        let entries: [LeaderboardEntry] = snapshot.documents.enumerated().compactMap { index, doc in
            do {
                let dto = try doc.data(as: AppUserDTO.self)
                let user = dto.toModel(id: doc.documentID)
                return LeaderboardEntry(
                    id: user.id,
                    userId: user.id,
                    username: user.username,
                    displayName: user.displayName,
                    score: user.allTimeHigh,
                    rank: index + 1
                )
            } catch {
                // Skip malformed documents
                return nil
            }
        }
        return entries
    }

    // Top friends (including self) by allTimeHigh.
    // This queries friendships where status == "accepted" and either side equals selfId.
    func friendsTop(selfId: String, limit: Int = 100) async throws -> [LeaderboardEntry] {
        // Fetch accepted friendships involving self
        async let q1 = db.collection(friendshipsCollection)
            .whereField("status", isEqualTo: "accepted")
            .whereField("requesterId", isEqualTo: selfId)
            .getDocuments()

        async let q2 = db.collection(friendshipsCollection)
            .whereField("status", isEqualTo: "accepted")
            .whereField("addresseeId", isEqualTo: selfId)
            .getDocuments()

        let (snap1, snap2) = try await (q1, q2)

        var friendIds = Set<String>()
        for doc in snap1.documents {
            let data = doc.data()
            let rid = data["requesterId"] as? String ?? ""
            let aid = data["addresseeId"] as? String ?? ""
            let other = rid == selfId ? aid : rid
            if !other.isEmpty { friendIds.insert(other) }
        }
        for doc in snap2.documents {
            let data = doc.data()
            let rid = data["requesterId"] as? String ?? ""
            let aid = data["addresseeId"] as? String ?? ""
            let other = aid == selfId ? rid : aid
            if !other.isEmpty { friendIds.insert(other) }
        }

        // Include self
        friendIds.insert(selfId)

        if friendIds.isEmpty {
            return []
        }

        // Firestore 'in' queries support up to 10 values per query; batch if needed.
        let chunks: [[String]] = friendIds.chunked(into: 10)

        var users: [AppUser] = []
        for chunk in chunks {
            let snap = try await db.collection(usersCollection)
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments()
            for doc in snap.documents {
                do {
                    let dto = try doc.data(as: AppUserDTO.self)
                    users.append(dto.toModel(id: doc.documentID))
                } catch {
                    continue
                }
            }
        }

        // Sort by allTimeHigh desc, take limit, and rank
        let sorted = users.sorted { $0.allTimeHigh > $1.allTimeHigh }.prefix(limit)
        let entries: [LeaderboardEntry] = sorted.enumerated().map { index, user in
            LeaderboardEntry(
                id: user.id,
                userId: user.id,
                username: user.username,
                displayName: user.displayName,
                score: user.allTimeHigh,
                rank: index + 1
            )
        }
        return entries
    }
}

// Reuse the DTO used by FirestoreUserRepository to decode user docs.
// Keep it internal here; it mirrors the other file.
private struct AppUserDTO: Codable {
    var username: String
    var displayName: String
    var photoURL: String?
    var createdAt: Date
    var allTimeHigh: Int
    var streak: Int
    var lastPlayDate: Date?

    func toModel(id: String) -> AppUser {
        AppUser(id: id, username: username, displayName: displayName, photoURL: photoURL.flatMap(URL.init(string:)), createdAt: createdAt, allTimeHigh: allTimeHigh, streak: streak, lastPlayDate: lastPlayDate)
    }
}

private extension Set where Element == String {
    func chunked(into size: Int) -> [[String]] {
        guard size > 0 else { return [Array(self)] }
        var result: [[String]] = []
        var current: [String] = []
        current.reserveCapacity(size)
        for id in self {
            current.append(id)
            if current.count == size {
                result.append(current)
                current.removeAll(keepingCapacity: true)
            }
        }
        if !current.isEmpty { result.append(current) }
        return result
    }
}
