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
	
	private var progressColor: Color {
		let stateColors = state.colors
		let colors: [(Color, Double)] = [
			(Color(hex: stateColors.start), 0.0),
			(Color(hex: stateColors.middle), 0.5),
			(Color(hex: stateColors.end), 1.0),
		]
		
		for i in 0..<(colors.count - 1) {
			if progress >= colors[i].1 && progress <= colors[i + 1].1 {
				return colors[i + 1].0
			}
		}
		return colors[0].0
	}
	
	// MARK: - Subviews
	private func TimerDisplay() -> some View {
		VStack(spacing: 8) {
			Text(timeRemaining)
				.font(.system(size: 72, weight: .bold, design: .rounded))
				.foregroundColor(.white)
			
			Text(state.rawValue.uppercased())
				.font(.system(size: 18, weight: .semibold, design: .rounded))
				.foregroundColor(.white.opacity(0.8))
		}
	}
	
	private func TimerNumbers(radius: CGFloat) -> some View {
		ForEach(0..<60) { index in
			if index % 5 == 0 {
				let minutes = index / 5 * 5
				let angle = Double(index) / 60.0 * 2 * .pi - .pi / 2
				let radius = (radius / 2) - 20
				let x = cos(angle) * radius + radius
				let y = sin(angle) * radius + radius
				
				Text("\(minutes)")
					.font(.system(size: 16, weight: .bold, design: .rounded))
					.foregroundColor(.white)
					.position(x: x, y: y)
			}
		}
	}
	
	private func QuadrantLines(radius: CGFloat) -> some View {
		Path { path in
			path.move(to: CGPoint(x: radius, y: 0))
			path.addLine(to: CGPoint(x: radius, y: radius * 2))
			path.move(to: CGPoint(x: 0, y: radius))
			path.addLine(to: CGPoint(x: radius * 2, y: radius))
		}
		.stroke(Color.white.opacity(0.2), lineWidth: 1)
	}
	
	private func ControlButtons() -> some View {
		HStack(spacing: 24) {
			ControlButton(
				icon: isRunning ? "pause.fill" : "play.fill",
				color: progressColor,
				action: isRunning ? onPause : onStart
			)
			ControlButton(
				icon: "arrow.counterclockwise",
				color: progressColor,
				action: onReset
			)
		}
		.padding(.top, 40)
	}
	
	private func FocusCard() -> some View {
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
		}
		.padding()
		.background()
		.cornerRadius(16)
		.shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
		.padding(.horizontal)
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
							.offset(x: -circleRadius/2, y: -circleRadius )
							.shadow(color: progressColor.opacity(0.3), radius: 15, x: 0, y: 10)
						
					
						TimerNumbers(radius: circleRadius * 1.1)
						TimerDisplay().offset(x: -circleRadius/2, y: -circleRadius/2)
					}
					.frame(height: circleRadius * 2)
					.padding(.top, 40)
					
					VStack(spacing: 32) {
						ControlButtons()
						FocusCard()
					}
					.padding(.bottom, 40)
				}
			}
		}
		.background()
	}
}

// MARK: - Control Button
struct ControlButton: View {
	let icon: String
	let color: Color
	let action: () -> Void
	
	@State private var isHovered = false
	
	var body: some View {
		Button(action: action) {
			Circle()
				.fill(
					LinearGradient(
						colors: [color, color.opacity(0.8)],
						startPoint: .topLeading,
						endPoint: .bottomTrailing
					)
				)
				.frame(width: 64, height: 64)
				.overlay(
					Image(systemName: icon)
						.font(.system(size: 24, weight: .semibold))
						.foregroundColor(.white)
				)
				.overlay(
					Circle()
						.stroke(Color.white.opacity(0.2), lineWidth: 1)
				)
				.shadow(color: color.opacity(0.3), radius: 10, x: 0, y: 5)
				.scaleEffect(isHovered ? 1.05 : 1.0)
		}
		.buttonStyle(ScaleButtonStyle())
		.onHover { hovering in
			withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
				isHovered = hovering
			}
		}
	}
}

struct ScaleButtonStyle: ButtonStyle {
	func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.scaleEffect(configuration.isPressed ? 0.97 : 1)
			.animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
	}
}

#if DEBUG
struct TimerCircleView_Previews: PreviewProvider {
	static var previews: some View {
		TimerCircleView(
			progress: 0.7,
			timeRemaining: "15:00",
			state: .shortBreak,
			isRunning: false,
			onStart: {},
			onPause: {},
			onReset: {},
			onAddTask: {}
		)
	}
}
#endif
