import SwiftUI

struct TimerCircleView: View {
    let progress: Double
    let timeRemaining: TimeInterval
    let totalTime: TimeInterval
    let isRunning: Bool
    let pomodoroState: PomodoroState
    
    @State private var rotationAngle: Double = 0
    @State private var previousProgress: Double = 0
    
    private let circleRadius: CGFloat = 140
    private let numberRadius: CGFloat = 160
    
    private var stateColor: Color {
        switch pomodoroState {
        case .work:
            return .red
        case .shortBreak:
            return .green
        case .longBreak:
            return .blue
        }
    }
    
    private var timeNumbers: [Int] {
        let totalMinutes = Int(totalTime / 60)
        var numbers: [Int] = []
        
        for i in 1...totalMinutes {
            numbers.append(i)
        }
        numbers.append(0) // START position
        
        return numbers
    }
    
    private var currentRotation: Double {
        let progressAngle = progress * 360
        return -progressAngle
    }
    
    var body: some View {
        ZStack {
            backgroundCircle
            
            progressCircle
            
            timeNumbersCircle
            
            centerTimeDisplay
        }
        .frame(width: numberRadius * 2 + 40, height: numberRadius * 2 + 40)
        .onChange(of: progress) { oldValue, newValue in
            withAnimation(.easeInOut(duration: 0.5)) {
                rotationAngle = currentRotation
            }
        }
        .onChange(of: isRunning) { oldValue, newValue in
            if newValue && progress > 0 {
                withAnimation(.easeInOut(duration: 0.3)) {
                    rotationAngle = currentRotation
                }
            }
        }
        .onAppear {
            rotationAngle = currentRotation
        }
    }
    
    private var backgroundCircle: some View {
        Circle()
            .stroke(
                stateColor.opacity(0.2),
                style: StrokeStyle(lineWidth: 8, lineCap: .round)
            )
            .frame(width: circleRadius * 2, height: circleRadius * 2)
    }
    
    private var progressCircle: some View {
        Circle()
            .trim(from: 0, to: progress)
            .stroke(
                LinearGradient(
                    colors: [stateColor.opacity(0.8), stateColor],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                style: StrokeStyle(lineWidth: 8, lineCap: .round)
            )
            .frame(width: circleRadius * 2, height: circleRadius * 2)
            .rotationEffect(.degrees(-90))
            .animation(.easeInOut(duration: 0.3), value: progress)
    }
    
    private var timeNumbersCircle: some View {
        ZStack {
            ForEach(Array(timeNumbers.enumerated()), id: \.offset) { index, number in
                let angle = Double(index) * (360.0 / Double(timeNumbers.count))
                let isStart = number == 0
                
                timeNumberView(
                    number: isStart ? "START" : "\(number)",
                    angle: angle,
                    isStart: isStart,
                    isActive: isActiveNumber(for: index)
                )
            }
        }
        .rotationEffect(.degrees(rotationAngle))
        .animation(.easeInOut(duration: 1.0), value: rotationAngle)
    }
    
    private func timeNumberView(number: String, angle: Double, isStart: Bool, isActive: Bool) -> some View {
        let x = cos((angle - 90) * .pi / 180) * numberRadius
        let y = sin((angle - 90) * .pi / 180) * numberRadius
        
        return Text(number)
            .font(isStart ? .caption.weight(.bold) : .system(size: 16, weight: .medium))
            .foregroundColor(isActive ? stateColor : (isStart ? stateColor.opacity(0.9) : .primary.opacity(0.6)))
            .background(
                Circle()
                    .fill(isActive ? stateColor.opacity(0.2) : Color.clear)
                    .frame(width: isStart ? 50 : 30, height: isStart ? 20 : 30)
            )
            .scaleEffect(isActive ? 1.2 : 1.0)
            .rotationEffect(.degrees(-rotationAngle))
            .animation(.easeInOut(duration: 0.3), value: isActive)
            .animation(.easeInOut(duration: 1.0), value: rotationAngle)
            .position(
                x: numberRadius + x,
                y: numberRadius + y
            )
    }
    
    private func isActiveNumber(for index: Int) -> Bool {
        let totalCount = timeNumbers.count
        let progressIndex = Int(progress * Double(totalCount))
        
        return index == min(progressIndex, totalCount - 1)
    }
    
    private var centerTimeDisplay: some View {
        VStack(spacing: 8) {
            Text(timeString)
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundColor(.primary)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.3), value: timeRemaining)
            
            Text(pomodoroState.title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundColor(stateColor)
                .tracking(1.5)
            
            if isRunning {
                HStack(spacing: 4) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(stateColor.opacity(0.7))
                            .frame(width: 6, height: 6)
                            .scaleEffect(isRunning ? 1.0 : 0.5)
                            .animation(
                                .easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                                value: isRunning
                            )
                    }
                }
                .padding(.top, 4)
            }
        }
    }
    
    private var timeString: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    TimerCircleView(
        progress: 0.3,
        timeRemaining: 1050, // 17:30
        totalTime: 1500, // 25:00
        isRunning: true,
        pomodoroState: .work
    )
    .padding()
    .background(Color(.systemBackground))
}