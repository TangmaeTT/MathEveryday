import SwiftUI

struct PlayView: View {
    @ObservedObject var vm: GameViewModel

    @State private var goToGame: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section("โหมดการเล่น") {
                    Picker("Operator", selection: $vm.selectedOperator) {
                        ForEach(MathOperator.allCases, id: \.self) { op in
                            Text(op.rawValue).tag(op)
                        }
                    }
                }

                Section {
                    Button {
                        vm.startGame()
                        // ผูกการนำทางกับสถานะการเริ่มเกม
                        goToGame = true
                    } label: {
                        Text("เริ่มเกม 1 นาที")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(vm.isRunning)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color("AccentColor").ignoresSafeArea())
            .navigationTitle("Play")
            // นำทางไปหน้าเล่นเกมเมื่อ goToGame == true
            .navigationDestination(isPresented: $goToGame) {
                GameView(vm: vm)
                    .onDisappear {
                        // เมื่อออกจากหน้าเกม ให้หยุดเกมถ้ายังรันอยู่ และรีเซ็ตแฟลกนำทาง
                        if vm.isRunning { vm.stopGame() }
                        goToGame = false
                    }
            }
        }
        .tint(Color("AccentColor"))
    }
}
