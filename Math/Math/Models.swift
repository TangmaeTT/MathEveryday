import Foundation

// MARK: - Core Models

struct AppUser: Identifiable, Equatable, Hashable {
    let id: String
    var username: String
    var displayName: String
    var photoURL: URL?
    var createdAt: Date
    var allTimeHigh: Int
    var streak: Int
    var lastPlayDate: Date?
}

enum MathOperator: String, CaseIterable, Identifiable, Codable, Hashable {
    case plus = "+"
    case minus = "-"
    case multiply = "×"
    case modulo = "%"
    case mixed = "All"

    var id: String { rawValue }
}

struct MathQuestion: Identifiable, Equatable {
    let id = UUID()
    let a: Int
    let b: Int
    let op: MathOperator

    var prompt: String {
        switch op {
        case .plus:     return "\(a) + \(b) = ?"
        case .minus:    return "\(a) - \(b) = ?"
        case .multiply: return "\(a) × \(b) = ?"
        case .modulo:   return "\(a) % \(b) = ?"
        case .mixed:
            // Should not happen at render time; mixed is generation-time choice
            return "\(a) ? \(b) = ?"
        }
    }

    var answer: Int {
        switch op {
        case .plus:     return a + b
        case .minus:    return a - b
        case .multiply: return a * b
        case .modulo:   return b == 0 ? 0 : (a % b)
        case .mixed:
            // Not used; generation resolves concrete op.
            return 0
        }
    }
}

struct Friendship: Identifiable, Equatable, Hashable {
    let id: String
    let requesterId: String
    let addresseeId: String
    var status: Status
    let createdAt: Date

    enum Status: String, Codable {
        case pending
        case accepted
    }
}

struct LeaderboardEntry: Identifiable, Equatable, Hashable {
    let id: String
    let userId: String
    let username: String
    let displayName: String
    let score: Int
    var rank: Int?
}
