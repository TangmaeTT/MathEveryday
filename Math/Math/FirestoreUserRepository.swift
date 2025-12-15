import Foundation
import FirebaseFirestore
import FirebaseFirestoreCombineSwift

struct FirestoreUserRepository {
    private let db = Firestore.firestore()
    private let collection = "users"

    func get(uid: String) async throws -> AppUser? {
        let doc = try await db.collection(collection).document(uid).getDocument()
        guard doc.exists else { return nil }
        return try doc.data(as: AppUserDTO.self).toModel(id: uid)
    }

    func createIfMissing(uid: String, displayName: String?, photoURL: URL?) async throws -> AppUser {
        if let existing = try await get(uid: uid) { return existing }
        let now = Date()
        let username = generateUsername(from: displayName) // temporary; can change later
        let dto = AppUserDTO(username: username, displayName: displayName ?? "User", photoURL: photoURL?.absoluteString, createdAt: now, allTimeHigh: 0, streak: 0, lastPlayDate: nil)
        try db.collection(collection).document(uid).setData(from: dto)
        return dto.toModel(id: uid)
    }

    func updateStats(uid: String, allTimeHigh: Int, streak: Int, lastPlayDate: Date) async throws {
        try await db.collection(collection).document(uid).updateData([
            "allTimeHigh": allTimeHigh,
            "streak": streak,
            "lastPlayDate": Timestamp(date: lastPlayDate)
        ])
    }

    func setUsername(uid: String, username: String) async throws {
        try await db.collection(collection).document(uid).updateData([
            "username": username
        ])
    }

    // NEW: อัปเดต URL รูปโปรไฟล์
    func updatePhotoURL(uid: String, url: URL?) async throws {
        try await db.collection(collection).document(uid).updateData([
            "photoURL": url?.absoluteString as Any
        ])
    }

    private func generateUsername(from name: String?) -> String {
        let base = (name ?? "user").replacingOccurrences(of: " ", with: "").lowercased()
        let suffix = Int.random(in: 1000...9999)
        return "\(base)_\(suffix)"
    }
}

// Firestore DTO
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
