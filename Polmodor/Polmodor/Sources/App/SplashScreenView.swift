import SwiftUI

struct SplashScreenView: View {
  @State private var iconScale: CGFloat = 0.5
  @State private var iconRotation: Double = 0
  @State private var textOpacity: Double = 0
  @State private var backgroundGradientOffset: CGFloat = -1
  @State private var pulseScale: CGFloat = 1
  @State private var isLoading = true

  let onSplashComplete: () -> Void

  var body: some View {
    ZStack {
      // Animated background gradient
      LinearGradient(
        colors: [
          Color.timerColors.workStart.opacity(0.8),
          Color.timerColors.shortBreakStart.opacity(0.6),
          Color.timerColors.longBreakStart.opacity(0.8),
        ],
        startPoint: UnitPoint(x: 0, y: backgroundGradientOffset),
        endPoint: UnitPoint(x: 1, y: backgroundGradientOffset + 1)
      )
      .ignoresSafeArea()
      .animation(
        .easeInOut(duration: 3.0).repeatForever(autoreverses: true),
        value: backgroundGradientOffset
      )

      // Floating particles background effect
      GeometryReader { geometry in
        ForEach(0..<15, id: \.self) { index in
          Circle()
            .fill(Color.white.opacity(0.1))
            .frame(width: CGFloat.random(in: 4...12))
            .position(
              x: CGFloat.random(in: 0...geometry.size.width),
              y: CGFloat.random(in: 0...geometry.size.height)
            )
            .animation(
              .easeInOut(duration: Double.random(in: 2...4))
                .repeatForever(autoreverses: true)
                .delay(Double(index) * 0.1),
              value: backgroundGradientOffset
            )
        }
      }

      VStack(spacing: 40) {
        Spacer()

        // Main icon
        Image("icon")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: 320, height: 320)
          .scaleEffect(iconScale)
          .rotationEffect(.degrees(iconRotation))
          .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)

        Spacer()

        Spacer()
      }
    }
    .onAppear {
      startAnimations()
    }
    .preferredColorScheme(.dark)
  }

  private func startAnimations() {
    // Start background gradient animation
    backgroundGradientOffset = 1

    // Icon entrance animation
    withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
      iconScale = 1.0
    }

    // Text fade in
    withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
      textOpacity = 1.0
    }

    // Pulse effect
    withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
      pulseScale = 1.1
    }

    // Complete splash after animations
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
      withAnimation(.easeInOut(duration: 0.6)) {
        isLoading = false
        iconScale = 1.2
        textOpacity = 0
      }

      DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
        onSplashComplete()
      }
    }
  }
}

#Preview {
  SplashScreenView {
    print("Splash completed")
  }
}
