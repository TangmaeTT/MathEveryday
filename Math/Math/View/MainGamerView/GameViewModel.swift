import Foundation
import SwiftUI
import Combine

@MainActor
final class GameViewModel: ObservableObject {
    @Published var selectedOperator: MathOperator = .mixed
    @Published var currentQuestion: MathQuestion? = nil
    @Published var answerText: String = ""
    @Published var timeRemaining: Int = 60
    @Published var score: Int = 0
    @Published var isRunning: Bool = false
    @Published var didFinish: Bool = false
    @Published var allTimeHigh: Int = 0
    @Published var streak: Int = 0

    private var timerCancellable: AnyCancellable?

    // Live services
    private let authVM: AuthViewModel
    private let userRepo = FirestoreUserRepository()

    init(authVM: AuthViewModel) {
        self.authVM = authVM
    }

    func startGame() {
        score = 0
        timeRemaining = 60
        didFinish = false
        isRunning = true
        nextQuestion()

        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    self.finishGame()
                }
            }
    }

    func stopGame() {
        isRunning = false
        timerCancellable?.cancel()
    }

    func finishGame() {
        guard isRunning else { return }
        stopGame()
        didFinish = true

        Task {
            // บันทึกสถิติจริงลง Firestore
            guard let uid = authVM.currentUser?.id else { return }

            do {
                // ดึงข้อมูลผู้ใช้ล่าสุด (เพื่อได้ allTimeHigh/streak/lastPlayDate เดิม)
                let existing = try await userRepo.get(uid: uid)

                let previousAllTime = existing?.allTimeHigh ?? 0
                let previousStreak = existing?.streak ?? 0
                let previousLast = existing?.lastPlayDate

                // คำนวณ allTimeHigh ใหม่
                let newAllTime = max(previousAllTime, score)

                // คำนวณ streak ตามตรรกะ mock เดิม
                let today = Date()
                let cal = Calendar.current
                var newStreak = 1

                if let last = previousLast {
                    if cal.isDate(today, inSameDayAs: last) {
                        // เล่นวันเดียวกันซ้ำ: คง streak เดิม
                        newStreak = previousStreak
                    } else if let yesterday = cal.date(byAdding: .day, value: -1, to: today),
                              cal.isDate(last, inSameDayAs: yesterday) {
                        // ต่อเนื่องจากเมื่อวาน
                        newStreak = previousStreak + 1
                    } else {
                        // ขาดช่วง: เริ่มใหม่ที่ 1
                        newStreak = 1
                    }
                }

                // อัปเดต Firestore
                try await userRepo.updateStats(uid: uid, allTimeHigh: newAllTime, streak: newStreak, lastPlayDate: today)

                // อัปเดตค่าที่ใช้แสดงผล
                self.allTimeHigh = newAllTime
                self.streak = newStreak
            } catch {
                // ถ้ามีปัญหา ให้คงค่าเดิมในหน้าสรุปไปก่อน และ log
                print("Failed to update stats: \(error)")
            }
        }
    }

    func submitAnswer() {
        guard let q = currentQuestion, let num = Int(answerText.trimmingCharacters(in: .whitespaces)) else { return }
        if num == q.answer {
            score += 1
        }
        answerText = ""
        nextQuestion()
    }

    private func nextQuestion() {
        let op = selectedOperator == .mixed ? MathOperator.allCases.filter { $0 != .mixed }.randomElement()! : selectedOperator
        currentQuestion = Self.makeQuestion(op: op)
    }

    private static func makeQuestion(op: MathOperator) -> MathQuestion {
        switch op {
        case .plus:
            return MathQuestion(a: Int.random(in: 0...99), b: Int.random(in: 0...99), op: .plus)
        case .minus:
            let a = Int.random(in: 0...99)
            let b = Int.random(in: 0...a)
            return MathQuestion(a: a, b: b, op: .minus)
        case .multiply:
            return MathQuestion(a: Int.random(in: 0...12), b: Int.random(in: 0...12), op: .multiply)
        case .modulo:
            let b = Int.random(in: 1...12)
            let a = Int.random(in: 0...99)
            return MathQuestion(a: a, b: b, op: .modulo)
        case .mixed:
            return MathQuestion(a: 0, b: 0, op: .plus) // placeholder, will be replaced by caller
        }
    }
}
