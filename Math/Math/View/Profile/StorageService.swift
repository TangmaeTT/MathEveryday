import Foundation
import FirebaseStorage

struct StorageService {
    private let storage = Storage.storage()
    private let profilePath = "profileImages"

    func uploadProfileImage(uid: String, data: Data, contentType: String = "image/jpeg") async throws -> URL {
        let ref = storage.reference().child("\(profilePath)/\(uid).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = contentType

        _ = try await ref.putDataAsync(data, metadata: metadata)
        let url = try await ref.downloadURL()
        return url
    }

    func deleteProfileImage(uid: String) async throws {
        let ref = storage.reference().child("\(profilePath)/\(uid).jpg")
        try await ref.delete()
    }
}

private extension StorageReference {
    func putDataAsync(_ uploadData: Data, metadata: StorageMetadata?) async throws -> StorageMetadata {
        try await withCheckedThrowingContinuation { cont in
            self.putData(uploadData, metadata: metadata) { meta, error in
                if let e = error { cont.resume(throwing: e) }
                else { cont.resume(returning: meta ?? StorageMetadata()) }
            }
        }
    }

    func downloadURL() async throws -> URL {
        try await withCheckedThrowingContinuation { cont in
            self.downloadURL { url, error in
                if let e = error { cont.resume(throwing: e) }
                else if let u = url { cont.resume(returning: u) }
            }
        }
    }

    func delete() async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            self.delete { error in
                if let e = error { cont.resume(throwing: e) }
                else { cont.resume() }
            }
        }
    }
}
