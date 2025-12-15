import Foundation
import FirebaseFirestore
import FirebaseFirestoreCombineSwift

struct FirestoreFriendRepository {
    private let db = Firestore.firestore()
    private let usersCollection = "users"
    private let friendshipsCollection = "friendships"

    // Search a user by exact username (case-insensitive not supported natively; store lowercase in DB if needed)
    func search(username: String) async throws -> AppUser? {
        let snap = try await db.collection(usersCollection)
            .whereField("username", isEqualTo: username)
            .limit(to: 1)
            .getDocuments()

        guard let doc = snap.documents.first else { return nil }
        let dto = try doc.data(as: AppUserDTO.self)
        return dto.toModel(id: doc.documentID)
    }

    // Add friendship as accepted (simple model)
    func addFriend(selfId: String, friendId: String) async throws {
        // Prevent duplicate friendships (both directions)
        let existing = try await findFriendship(between: selfId, and: friendId)
        if existing != nil { return }

        let data: [String: Any] = [
            "requesterId": selfId,
            "addresseeId": friendId,
            "status": "accepted",
            "createdAt": FieldValue.serverTimestamp()
        ]
        _ = try await db.collection(friendshipsCollection).addDocument(data: data)
    }

    // Remove friendship in either direction
    func removeFriend(selfId: String, friendId: String) async throws {
        let docs = try await friendshipsBetween(selfId, friendId)
        for doc in docs {
            try await db.collection(friendshipsCollection).document(doc.documentID).delete()
        }
    }

    // List accepted friends of selfId and return their AppUser models
    func listFriends(selfId: String) async throws -> [AppUser] {
        // Fetch friendships where accepted and involves selfId
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
            if let aid = data["addresseeId"] as? String { friendIds.insert(aid) }
        }
        for doc in snap2.documents {
            let data = doc.data()
            if let rid = data["requesterId"] as? String { friendIds.insert(rid) }
        }

        guard !friendIds.isEmpty else { return [] }

        // Firestore 'in' query supports up to 10 ids per batch
        let chunks = Array(friendIds).chunked(into: 10)
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
                    // Skip malformed
                    continue
                }
            }
        }
        return users
    }

    // MARK: - Helpers

    private func friendshipsBetween(_ a: String, _ b: String) async throws -> [QueryDocumentSnapshot] {
        // query both directions since we don't know requester/addressee order
        async let q1 = db.collection(friendshipsCollection)
            .whereField("requesterId", isEqualTo: a)
            .whereField("addresseeId", isEqualTo: b)
            .getDocuments()
        async let q2 = db.collection(friendshipsCollection)
            .whereField("requesterId", isEqualTo: b)
            .whereField("addresseeId", isEqualTo: a)
            .getDocuments()
        let (s1, s2) = try await (q1, q2)
        return s1.documents + s2.documents
    }

    private func findFriendship(between a: String, and b: String) async throws -> QueryDocumentSnapshot? {
        let docs = try await friendshipsBetween(a, b)
        return docs.first
    }
}

// Local DTO mirroring FirestoreUserRepository’s DTO
private struct AppUserDTO: Codable {
    var username: String
    var displayName: String
    var photoURL: String?
    var createdAt: Date
    var allTimeHigh: Int
    var streak: Int
    var lastPlayDate: Date?

    func toModel(id: String) -> AppUser {
        AppUser(
            id: id,
            username: username,
            displayName: displayName,
            photoURL: photoURL.flatMap(URL.init(string:)),
            createdAt: createdAt,
            allTimeHigh: allTimeHigh,
            streak: streak,
            lastPlayDate: lastPlayDate
        )
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        var result: [[Element]] = []
        var current: [Element] = []
        current.reserveCapacity(size)
        for e in self {
            current.append(e)
            if current.count == size {
                result.append(current)
                current.removeAll(keepingCapacity: true)
            }
        }
        if !current.isEmpty { result.append(current) }
        return result
    }
}
