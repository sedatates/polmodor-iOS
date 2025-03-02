import SwiftUI

struct TimerCircleViewLEgacy: View {
    let progress: Double
    let timeRemaining: String
    let state: PomodoroState
    let isRunning: Bool
    let onStart: () -> Void
    let onPause: () -> Void
    let onReset: () -> Void
    let onAddTask: () -> Void

    @State private var isAnimating = false
    @State private var rotationAngle: Double = 0

    private var progressColor: Color {
        switch state {
        case .work:
            return Color.timerColors.workStart
        case .shortBreak:
            return Color.timerColors.shortBreakStart
        case .longBreak:
            return Color.timerColors.longBreakStart
        }
    }

    private var gradientColors: [Color] {
        switch state {
        case .work:
            return [Color.timerColors.workStart, Color.timerColors.workEnd]
        case .shortBreak:
            return [Color.timerColors.shortBreakStart, Color.timerColors.shortBreakEnd]
        case .longBreak:
            return [Color.timerColors.longBreakStart, Color.timerColors.longBreakEnd]
        }
    }

    private func markerText(for minute: Int, totalDuration: Int) -> String {
        if minute == 0 {
            return "START"
        } else if minute == totalDuration {
            return "END"
        } else {
            return "\(minute)"
        }
    }

    private func TimerMarkers(radius: CGFloat, totalDuration: Int) -> some View {
        let markerCount = totalDuration + 1
        return ZStack {
            ForEach(Array(0..<markerCount), id: \.self) { index in
                let angle = Double(index) / Double(markerCount - 1) * 2 * .pi - .pi / 2
                let markerRadius = radius - 30
                let x = cos(angle) * markerRadius
                let y = sin(angle) * markerRadius

                Text(markerText(for: index, totalDuration: totalDuration))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .position(x: x + radius, y: y + radius)
                    .rotationEffect(.degrees(-rotationAngle))
            }
        }
    }

    private func TimerRing(radius: CGFloat) -> some View {
        Circle()
            .trim(from: 0, to: progress)
            .stroke(
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                style: StrokeStyle(lineWidth: 12, lineCap: .round)
            )
            .frame(width: radius * 2, height: radius * 2)
            .rotationEffect(.degrees(-90))
            .rotation3DEffect(.degrees(isAnimating ? 360 : 0), axis: (x: 0, y: 1, z: 0))
            .animation(
                .spring(response: 0.8, dampingFraction: 0.7, blendDuration: 0.3),
                value: isAnimating
            )
    }

    private func TimerDisplay() -> some View {
        VStack(spacing: 8) {
            Text(timeRemaining)
                .font(Font.custom("Bungee-Regular", size: 72))
                .monospacedDigit()
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 2)

            Text(state.rawValue.uppercased())
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
        }
    }

    private func ControlButtons() -> some View {
        HStack(spacing: 24) {

        }
    }

    var body: some View {
        GeometryReader { geometry in
            let circleRadius = min(geometry.size.width, geometry.size.height)

            ScrollView {
                VStack(spacing: 0) {
                    ZStack {
                        Circle()
                            .fill(progressColor)
                            .frame(width: circleRadius * 2, height: circleRadius * 2)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 2)
                            )
                            .offset(x: -circleRadius / 2, y: -circleRadius)
                            .shadow(color: progressColor.opacity(0.3), radius: 15, x: 0, y: 10)

                        // Timer
                        TimerDisplay().offset(x: -circleRadius / 2, y: -circleRadius / 2)

                    }
                    .frame(height: circleRadius * 2)
                    .padding(.top, 40)

                    VStack(spacing: 32) {
                        ControlButtons()

                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .ignoresSafeArea()
    }
}
