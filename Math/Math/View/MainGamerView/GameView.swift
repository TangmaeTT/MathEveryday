import SwiftUI

struct GameView: View {
    @ObservedObject var vm: GameViewModel

    // ตั้งค่าสูงสุดเวลาต่อเกม (ต้องสอดคล้องกับ startGame() ที่ตั้ง 60 วินาที)
    private let totalSeconds: Double = 60.0

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Label("เหลือเวลา: \(vm.timeRemaining)s", systemImage: "timer")
                Spacer()
                Label("คะแนน: \(vm.score)", systemImage: "checkmark.circle")
                    .fontWeight(.semibold)
            }
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.9))

            if let q = vm.currentQuestion {
                VStack(spacing: 12) {
                    Text(q.prompt)
                        .font(.largeTitle.bold())
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                        .foregroundStyle(.white)

                    TextField("คำตอบ", text: $vm.answerText, onCommit: {
                        vm.submitAnswer()
                        vm.answerText = "" // ล้างเมื่อกด Return
                    })
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 6)
                .padding(.top, 8)
            }

            VStack(spacing: 8) {
                HStack {
                    Button {
                        vm.submitAnswer()
                        vm.answerText = "" // ล้างเมื่อกดปุ่มส่ง
                    } label: {
                        Label("ส่งคำตอบ", systemImage: "paperplane.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.white.opacity(0.9))

                    Button {
                        vm.finishGame()
                    } label: {
                        Label("ยอมแพ้", systemImage: "flag.slash.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red.opacity(0.9))
                }

                // แถบเวลาลดจากเต็ม -> ว่างเมื่อหมดเวลา
                TimeProgressBar(progress: remainingProgress, isLowTime: isLowTime)
                    .frame(height: 8)
                    .clipShape(Capsule())
                    .accessibilityLabel("เวลาที่เหลือ")
                    .accessibilityValue("\(Int(remainingProgress * 100)) เปอร์เซ็นต์")
            }
            .padding(.top, 8)

            Spacer(minLength: 0)
        }
        .padding()
        .background(Color("AccentColor").ignoresSafeArea())
        .onDisappear {
            if vm.isRunning { vm.stopGame() }
        }
        // แสดงผลลัพธ์เมื่อเกมจบ
        .sheet(isPresented: Binding(
            get: { vm.didFinish },
            set: { newValue in
                // เมื่อปิดชีต ให้รีเซ็ตแฟลก
                if !newValue {
                    vm.didFinish = false
                }
            })
        ) {
            ResultView(
                score: vm.score,
                allTimeHigh: vm.allTimeHigh,
                streak: vm.streak
            ) {
                // onClose: ปิดผลลัพธ์
                vm.didFinish = false
            }
            .presentationDetents([.medium, .large])
        }
    }

    // สัดส่วนเวลาที่เหลือ 1.0 -> 0.0
    private var remainingProgress: Double {
        let remaining = max(0.0, min(totalSeconds, Double(vm.timeRemaining)))
        return remaining / totalSeconds
    }

    // ใกล้หมดเวลาหรือยัง (เช่น เหลือ ≤ 10 วินาที)
    private var isLowTime: Bool {
        Double(vm.timeRemaining) <= 10.0
    }
}

// แถบความคืบหน้าแบบลดลง (พื้นจาง + แถบไล่สีตามสัดส่วนที่เหลือ)
// เมื่อเวลาใกล้หมด จะเปลี่ยนเป็นสีแดง และกระพริบเล็กน้อย
private struct TimeProgressBar: View {
    let progress: Double // 1...0 (เวลาที่เหลือ)
    let isLowTime: Bool

    @State private var pulse: Bool = false

    var body: some View {
        ZStack(alignment: .leading) {
            Color.white.opacity(0.25)

            barColor
                .frame(maxWidth: .infinity)
                .mask(
                    GeometryReader { geo in
                        Rectangle()
                            .frame(width: max(0, min(geo.size.width, geo.size.width * progress)))
                    }
                )
                .scaleEffect(y: isLowTime && pulse ? 1.12 : 1.0, anchor: .center) // pulse เล็กน้อยเมื่อใกล้หมด
                .animation(isLowTime ? .easeInOut(duration: 0.6).repeatForever(autoreverses: true) : .default, value: pulse)
        }
        .onChange(of: isLowTime) { low in
            if low {
                pulse = true
            } else {
                pulse = false
            }
        }
        .onAppear {
            if isLowTime { pulse = true }
        }
        .animation(.linear(duration: 0.2), value: progress)
    }

    private var barColor: some View {
        Group {
            if isLowTime {
                LinearGradient(
                    colors: [
                        .red.opacity(0.95),
                        .orange.opacity(0.9)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            } else {
                LinearGradient(
                    colors: [
                        Color("Color-1"),
                        Color("Color-2")
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
        }
    }
}
