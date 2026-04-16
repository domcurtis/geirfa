import SwiftUI

struct ConfettiView: View {
    @Binding var isShowing: Bool
    @State private var particles: [ConfettiParticle] = []
    @State private var animating = false

    var body: some View {
        if isShowing {
            ZStack {
                // Semi-transparent overlay
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture { isShowing = false }

                // Confetti particles
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .offset(
                            x: animating ? particle.endX : particle.startX,
                            y: animating ? particle.endY : particle.startY
                        )
                        .opacity(animating ? 0 : 1)
                }

                // Mastery message
                VStack(spacing: 16) {
                    Text("Da iawn!")
                        .font(.custom("Georgia", size: 32))
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("Unit mastered!")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))

                    Button {
                        isShowing = false
                    } label: {
                        Text("Continue")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AppColors.hgreen)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(.white)
                            .clipShape(Capsule())
                    }
                    .padding(.top, 8)
                }
            }
            .onAppear {
                generateParticles()
                withAnimation(.easeOut(duration: 2.5)) {
                    animating = true
                }
            }
            .onDisappear {
                animating = false
                particles = []
            }
        }
    }

    private func generateParticles() {
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink, AppColors.gold]
        particles = (0..<40).map { _ in
            ConfettiParticle(
                color: colors.randomElement() ?? .yellow,
                size: CGFloat.random(in: 5...12),
                startX: CGFloat.random(in: -20...20),
                startY: -50,
                endX: CGFloat.random(in: -180...180),
                endY: CGFloat.random(in: 200...500)
            )
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    let color: Color
    let size: CGFloat
    let startX: CGFloat
    let startY: CGFloat
    let endX: CGFloat
    let endY: CGFloat
}
