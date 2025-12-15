import SwiftUI

struct SplashView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @State private var isActive = false
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0.0

    // ปรับชื่อสีให้ตรงกับ Asset ของคุณ
    private let topColor = Color("GradientTop")
    private let bottomColor = Color("GradientBottom")

    // ปรับชื่อรูปโลโก้ให้ตรงกับ Asset ของคุณ (Image Set)
    private let logoName = "AppLogo"

    var body: some View {
        ZStack {
            LinearGradient(colors: [topColor, bottomColor],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(logoName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 140)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    .shadow(color: .black.opacity(0.15), radius: 14, x: 0, y: 8)

                VStack(spacing: 6) {
                    Text("Math Every Day")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                        .opacity(logoOpacity)
                    Text("ฝึกคิดเลขเร็ว 1 นาทีต่อวัน")
                        .font(.callout)
                        .foregroundStyle(.white.opacity(0.85))
                        .opacity(logoOpacity)
                }
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            // เฟดและซูมโลโก้
            withAnimation(.easeOut(duration: 0.7)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            // หน่วงเพื่อโชว์ Splash แล้วเปลี่ยนไป ContentView
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isActive = true
                }
            }
        }
        .fullScreenCover(isPresented: $isActive) {
            ContentView()
                .environmentObject(authVM)
        }
    }
}
