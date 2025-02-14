import SwiftUI

struct TimerCircleView: View {
    let progress: Double
    let timeRemaining: String
    let state: PomodoroState
    let isRunning: Bool
    let onStart: () -> Void
    let onPause: () -> Void
    let onReset: () -> Void
    let onAddTask: () -> Void

    private let minuteNumbers = Array(1...25)

    private var startEndText: String {
        if progress > 0.9 {
            return "END"
        }
        return "START"
    }

    private var progressColor: Color {
        let colors = [
            Color(hex: "#FF9F9F"),
            Color(hex: "#FFB5B5"),
            Color(hex: "#FF8A8A"),
            Color(hex: "#FF7675"),
        ]

        let index = Int(progress * Double(colors.count - 1))
        let nextIndex = min(index + 1, colors.count - 1)

        return colors[index]
    }

    private func calculatePosition(for index: Int, in size: CGSize, radius: CGFloat) -> CGPoint {
        let angle = (2 * .pi * Double(index) / 25.0) - .pi / 2
        return CGPoint(
            x: size.width / 2 + radius * cos(angle),
            y: radius * sin(angle)
        )
    }
	
	
	// ControlButton
	struct ControlButton: View {
		let icon: String
		let color: Color
		let action: () -> Void
		
		var body: some View {
			GeometryReader{ metrics in
				Button(
					action: action
				) {
					Image(
						systemName: icon
					)
				}.frame(
					maxWidth: 400,
					maxHeight: 400
				)
				.frame(
					maxWidth: .infinity,
					maxHeight: .infinity,
					
					alignment: Alignment.center
				)
				.padding(
					20
				)
				.background( color )
			}
		}
	}
	
		
	
    var body: some View {
        ScrollView {
            GeometryReader { geometry in
							let circleRadius = geometry.size.height * 0.6

                VStack(spacing: 0) {
                    // Timer Section
                    ZStack {
                        // Main Circle Background
                        Circle()
                            .fill(progressColor)
                            .frame(width: circleRadius * 2, height: circleRadius * 2)
                            .position(x: geometry.size.width / 2, y: 0)

                        // Numbers around the circle
                        ForEach(0..<26) { index in
                            let position = calculatePosition(
                                for: index, in: geometry.size, radius: circleRadius - 20)

                            Group {
                                if index == 0 {
                                    Text(startEndText)
                                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                                } else {
                                    Text("\(index)")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                }
                            }
                            .foregroundColor(.white)
                            .position(x: position.x, y: position.y)
                        }

                        // Time Display
                        Text(timeRemaining)
                            .font(.system(size: 80, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .position(x: geometry.size.width / 2, y: circleRadius / 2)
                    }
                    .frame(height: circleRadius * 1)

                    // Controls Section
                    VStack(spacing: 0) {
                        // Control buttons
                        HStack {
                            Spacer()
                            ControlButton(
                                icon: isRunning ? "pause.fill" : "play.fill",
                                color: progressColor,
                                action: isRunning ? onPause : onStart
                            )

                            Spacer()

                            ControlButton(
                                icon: "arrow.clockwise",
                                color: progressColor,
                                action: onReset
                            )
                            Spacer()
                        }
                        .padding(.vertical, 40)

                        // Focus Timer Card
                        HStack {
                            Image(systemName: "timer")
                                .foregroundColor(progressColor)
                                .font(.title2)

                            VStack(alignment: .leading) {
                                Text("Focus Timer Active")
                                    .font(.headline)
                                Text("Want to track your progress?")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Button(action: onAddTask) {
                                Image(systemName: "plus")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(progressColor)
                                    .clipShape(Circle())
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(radius: 5)
                        .padding(.horizontal)

                        Spacer(minLength: 100)
                    }
                }
            }
            .frame(minHeight: 800)
        }
    }
}

#if DEBUG
    struct TimerCircleView_Previews: PreviewProvider {
        static var previews: some View {
            TimerCircleView(
                progress: 0.7,
                timeRemaining: "15:00",
                state: PomodoroState.shortBreak,
                isRunning: false,
                onStart: {},
                onPause: {},
                onReset: {},
                onAddTask: {}
            )
        }
    }
#endif
