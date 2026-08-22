import SwiftUI

struct SplashView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false
    @State private var progress = 0.0

    private let duration: Double = 2.6

    var body: some View {
        ZStack {
            Color.backgroundPrimary
                .ignoresSafeArea()

            Circle()
                .fill(Color.accent.opacity(0.12))
                .frame(width: 380, height: 380)
                .blur(radius: 36)
                .offset(y: -180)

            VStack(spacing: 22) {
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 128, height: 128)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .shadow(color: Color.accent.opacity(0.35), radius: 24)
                    .scaleEffect(appeared || reduceMotion ? 1 : 0.8)
                    .opacity(appeared || reduceMotion ? 1 : 0)
                    .accessibilityHidden(true)

                VStack(spacing: 8) {
                    Text("Digitale Kloon")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.textPrimary)

                    Text("Je veilige tweede brein")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                }
                .opacity(appeared || reduceMotion ? 1 : 0)

                ProgressView(value: progress)
                    .tint(Color.accent)
                    .frame(width: 120)
                    .padding(.top, 14)
                    .accessibilityLabel("Digitale Kloon start op")
            }
        }
        .task {
            if reduceMotion {
                appeared = true
                progress = 1
            } else {
                withAnimation(.easeOut(duration: 0.7)) {
                    appeared = true
                }
                withAnimation(.linear(duration: duration)) {
                    progress = 1
                }
            }
        }
    }
}