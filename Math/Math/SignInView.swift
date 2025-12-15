import SwiftUI

struct SignInView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @State private var isSigningInGoogle = false

    // ค่ามาตรฐานสำหรับระยะห่าง
    private let verticalGroupSpacing: CGFloat = 10
    private let titleLineSpacing: CGFloat = 4
    private let buttonContentSpacing: CGFloat = 0
    private let buttonStackSpacing: CGFloat = 12

    // ค่ามาตรฐานสำหรับไอคอน
    private let iconPadding: CGFloat = 4
    private let iconSize: CGFloat = 18 // ใช้กับ .font(.system(size:))

    // State สำหรับแอนิเมชัน
    @State private var appearTitle = false
    @State private var appearCard = false
    @State private var gradientPhase: CGFloat = 0
    @State private var googleIconRotation: Double = 0
    @State private var pressingGoogle = false
    @State private var pressingGuest = false

    // Gradient สำหรับไล่สีตัวอักษรหัวเรื่อง
    @State private var titleGradientPhase: CGFloat = 0

    // สีไล่โทนชมพูสำหรับหัวเรื่อง
    private let pinkGradientColors: [Color] = [
        Color.pink.opacity(0.95),
        Color("Color-2"), // หาก Color-2 เป็นชมพูโทนแบรนด์ ใช้ร่วมได้
        .white,
        Color("Color-2"),
        Color.pink.opacity(0.95)
    ]

    var body: some View {
        ZStack {
            // Animated gradient background ซ้อนบน AccentColor เบาๆ
            Color("AccentColor")
                .ignoresSafeArea()

            LinearGradient(
                gradient: Gradient(colors: [
                    Color("AccentColor").opacity(0.0),
                    Color("AccentColor").opacity(0.15),
                    Color("AccentColor").opacity(0.0)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .hueRotation(.degrees(Double(gradientPhase) * 20))
            .scaleEffect(1.05 + 0.02 * sin(gradientPhase))
            .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: gradientPhase)
            .ignoresSafeArea()

            VStack(spacing: verticalGroupSpacing) {

                // เดิมเป็น Spacer() บนสุด -> เปลี่ยนเป็น padding ด้านบนแทน
                // กลุ่มหัวเรื่อง: เฟด + เลื่อนขึ้น + spring
                VStack(spacing: titleLineSpacing) {
                    // รวมสองบรรทัดเป็นข้อความเดียว แล้วทำไล่สีชมพูแบบเคลื่อนไหว
                    AnimatedGradientText(
                        attributedText: combinedTitle,
                        colors: pinkGradientColors,
                        phase: titleGradientPhase
                    )
                }
                .multilineTextAlignment(.center)
                .opacity(appearTitle ? 1 : 0)
                .offset(y: appearTitle ? 0 : 12)
                .scaleEffect(appearTitle ? 1.0 : 0.98)
                .animation(.spring(response: 0.6, dampingFraction: 0.85), value: appearTitle)
                .padding(.top, 24)     // เว้นหัวด้านบนเล็กน้อย
                .padding(.bottom, 0)   // ชิดกับการ์ดมากขึ้น

                // กลุ่มปุ่มภในการ์ด: เฟด + scale in
                VStack(spacing: buttonStackSpacing) {
                    Button {
                        Task {
                            withAnimation(.easeInOut(duration: 0.15)) { pressingGoogle = false }
                            isSigningInGoogle = true
                            // หมุนไอคอนอย่างต่อเนื่องขณะโหลด
                            withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                                googleIconRotation = 360
                            }
                            await authVM.signIn(with: .google)
                            isSigningInGoogle = false
                            googleIconRotation = 0
                        }
                    } label: {
                        HStack(spacing: buttonContentSpacing) {
                            Image(systemName: "g.circle.fill")
                                .font(.system(size: iconSize, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(iconPadding)
                                .rotationEffect(.degrees(googleIconRotation))
                                .animation(isSigningInGoogle ? .linear(duration: 1.0).repeatForever(autoreverses: false) : .default, value: googleIconRotation)

                            Group {
                                if isSigningInGoogle {
                                    HStack(spacing: 6) {
                                        ProgressView()
                                            .tint(.white)
                                        Text("กำลังลงชื่อเข้าใช้ด้วย Google...")
                                            .fontWeight(.semibold)
                                    }
                                } else {
                                    Text("Sign in with Google")
                                        .fontWeight(.semibold)
                                }
                            }
                            .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                    .simultaneousGesture(DragGesture(minimumDistance: 0).onChanged { _ in
                        withAnimation(.easeInOut(duration: 0.08)) { pressingGoogle = true }
                    }.onEnded { _ in
                        withAnimation(.easeInOut(duration: 0.12)) { pressingGoogle = false }
                    })
                    .buttonStyle(.borderedProminent)
                    .tint(Color("Color-1"))
                    .scaleEffect(pressingGoogle ? 0.98 : 1.0)
                    .shadow(color: Color.black.opacity(pressingGoogle ? 0.10 : 0.18), radius: pressingGoogle ? 8 : 12, x: 0, y: pressingGoogle ? 4 : 8)
                    .animation(.easeInOut(duration: 0.15), value: pressingGoogle)
                    .disabled(isSigningInGoogle)

                    Button {
                        Task {
                            withAnimation(.easeInOut(duration: 0.15)) { pressingGuest = false }
                            await authVM.signIn(with: .guest)
                        }
                    } label: {
                        HStack(spacing: buttonContentSpacing) {
                            Image(systemName: "person.crop.circle.badge.questionmark")
                                .font(.system(size: iconSize, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(iconPadding)
                            Text("ลองเข้าใช้งานแบบ Guest")
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                    .simultaneousGesture(DragGesture(minimumDistance: 0).onChanged { _ in
                        withAnimation(.easeInOut(duration: 0.08)) { pressingGuest = true }
                    }.onEnded { _ in
                        withAnimation(.easeInOut(duration: 0.12)) { pressingGuest = false }
                    })
                    .buttonStyle(.bordered)
                    .tint(Color("Color-2"))
                    .scaleEffect(pressingGuest ? 0.98 : 1.0)
                    .shadow(color: Color.black.opacity(pressingGuest ? 0.06 : 0.12), radius: pressingGuest ? 6 : 10, x: 0, y: pressingGuest ? 3 : 6)
                    .animation(.easeInOut(duration: 0.15), value: pressingGuest)
                }
                .padding(.top, 4)  // ดันการ์ดขึ้นมาใกล้หัวเรื่องอีกนิด
                .padding(20)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
                .padding(.horizontal, 24)
                .opacity(appearCard ? 1 : 0)
                .scaleEffect(appearCard ? 1.0 : 0.96)
                .animation(.spring(response: 0.6, dampingFraction: 0.9), value: appearCard)

                Spacer()
            }
            .padding()
        }
        .onAppear {
            // trigger animated background
            gradientPhase = 1
            // trigger animated title gradient
            withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                titleGradientPhase = 1
            }
            // staged appearance
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                appearTitle = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                appearCard = true
            }
        }
        .onDisappear {
            // reset states (เผื่อกลับมาหน้านี้อีกครั้ง)
            appearTitle = false
            appearCard = false
            gradientPhase = 0
            googleIconRotation = 0
            pressingGoogle = false
            pressingGuest = false
            titleGradientPhase = 0
        }
    }

    // รวมข้อความสองบรรทัด พร้อมกำหนดสไตล์ต่างกันในแต่ละบรรทัด
    private var combinedTitle: AttributedString {
        var first = AttributedString("Math Every Day\n")
        first.font = .system(.largeTitle, design: .default).bold()

        var second = AttributedString("ฝึกคิดเลขเร็ว 1 นาทีต่อวัน")
        second.font = .system(.callout, design: .default)

        var result = first
        result.append(second)
        return result
    }
}

// MARK: - Animated Gradient Text รองรับ AttributedString

private struct AnimatedGradientText: View {
    let attributedText: AttributedString
    let colors: [Color]
    var phase: CGFloat // 0 -> 1

    var body: some View {
        let animatedGradient = LinearGradient(
            gradient: Gradient(colors: colors),
            startPoint: UnitPoint(x: -1 + phase * 2, y: 0.5),
            endPoint: UnitPoint(x: phase * 2, y: 0.5)
        )

        animatedGradient
            .mask(
                Text(attributedText)
                    .multilineTextAlignment(.center)
            )
            .accessibilityLabel(Text(String(attributedText.characters)))
    }
}

#Preview {
    SignInView()
        .environmentObject(AuthViewModel())
}
