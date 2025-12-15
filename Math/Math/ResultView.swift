import SwiftUI

struct ResultView: View {
    let score: Int
    let allTimeHigh: Int
    let streak: Int
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("จบเกมแล้ว!")
                .font(.title.bold())
            Text("คะแนนรอบนี้: \(score)")
                .font(.title2)
            Text("สถิติสูงสุด (All-time): \(allTimeHigh)")
            Text("สถิติต่อเนื่อง (Streak): \(streak) วัน")

            Button("ปิด") {
                onClose()
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 12)
        }
        .padding()
    }
}
