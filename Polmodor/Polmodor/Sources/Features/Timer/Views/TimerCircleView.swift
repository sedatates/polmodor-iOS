import SwiftUI

struct TimerCircleView: View {
  let timeRemaining: TimeInterval
  let isRunning: Bool
  let pomodoroState: PomodoroState
  let completedPomodoros: Int

  @State private var rotationAngle: Double = 0
  @State private var timer: Timer?

  private let circleRadius: CGFloat = UIScreen.screenWidth / 2  // Half of the screen width
  private let circleWidth: CGFloat = UIScreen.screenWidth  // Width of the circle minus padding
  private let segments: Int = 60

  var body: some View {
    ZStack {
      QuadrantView
      centerTimeDisplay
    }
    .frame(
      width: UIScreen.screenWidth,
      height: UIScreen.screenWidth
    )
    .onChange(of: isRunning) { _, newValue in
      if newValue {
        startRotation()
      } else {
        stopRotation()
      }
    }
    .onAppear {
      if isRunning {
        startRotation()
      }
    }
    .onDisappear {
      stopRotation()
    }
  }

  private var QuadrantView: some View {
    ZStack {
      ForEach(0..<segments, id: \.self) { index in
        let angle = Double(index) * (360.0 / Double(segments))
        Quartz(angle: angle)
      }
    }
    .rotationEffect(.degrees(rotationAngle))
    .animation(.easeInOut(duration: 1.0), value: rotationAngle)
    .position(x: UIScreen.screenWidth / 2, y: -UIScreen.screenWidth / 8)
  }

  private func Quartz(angle: Double) -> some View {
    let x = circleWidth * cos(Angle.degrees(angle).radians)
    let y = circleWidth * sin(Angle.degrees(angle).radians)

    return Capsule()
      .fill(.gray.opacity(0.5))
      .frame(width: 4, height: 20)
      .rotationEffect(.degrees(-rotationAngle))
      .animation(.easeInOut(duration: 1.0), value: rotationAngle)
      .position(
        x: circleRadius + x,
        y: circleRadius + y
      )
  }

  private var centerTimeDisplay: some View {
    VStack(spacing: 8) {
      Text(timeString)
        .font(.system(size: circleRadius * 0.5, weight: .bold, design: .monospaced))
        .foregroundColor(.primary)
        .contentTransition(.numericText())
        .animation(.easeInOut(duration: 0.3), value: timeRemaining)
    }
  }

  private var timeString: String {
    let minutes = Int(timeRemaining) / 60
    let seconds = Int(timeRemaining) % 60
    return String(format: "%02d:%02d", minutes, seconds)
  }

  private func startRotation() {
    stopRotation()
    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
      withAnimation(.bouncy(duration: 2.0)) {
        rotationAngle += 6  // 360 degrees / 60 segments = 6 degrees per second
      }
    }
  }

  private func stopRotation() {
    timer?.invalidate()
    timer = nil
  }

}

#Preview {
  TimerCircleView(
    timeRemaining: 1500,  // Example: 25 minutes in seconds
    isRunning: true,
    pomodoroState: .work,
    completedPomodoros: 2
  )
}
