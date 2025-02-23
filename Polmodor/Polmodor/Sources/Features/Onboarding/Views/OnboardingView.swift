import SwiftUI

#if os(iOS)
    import UIKit
#endif

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0

    private let pages = [
        OnboardingPage(
            title: "Welcome to Polmodor",
            description: "Boost your productivity with the Pomodoro Technique™",
            imageName: "timer.circle.fill",
            accentColor: .blue,
            gradientColors: [Color(hex: "4DABF7"), Color(hex: "228BE6")]
        ),
        OnboardingPage(
            title: "Stay Focused",
            description: "Work in focused 25-minute intervals, followed by short breaks",
            imageName: "brain.head.profile",
            accentColor: .purple,
            gradientColors: [Color(hex: "845EF7"), Color(hex: "5F3DC4")]
        ),
        OnboardingPage(
            title: "Track Tasks",
            description: "Organize and track your tasks with built-in task management",
            imageName: "checklist",
            accentColor: .green,
            gradientColors: [Color(hex: "51CF66"), Color(hex: "2F9E44")]
        ),
        OnboardingPage(
            title: "Monitor Progress",
            description: "View your productivity stats and improve over time",
            imageName: "chart.bar.fill",
            accentColor: .orange,
            gradientColors: [Color(hex: "FF922B"), Color(hex: "D9480F")]
        ),
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                AnimatedGradientBackground(
                    colors: pages.map { $0.gradientColors },
                    currentPage: currentPage,
                    pageCount: pages.count
                )

                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                #if os(iOS)
                    .tabViewStyle(.page(indexDisplayMode: .never))
                #endif

                if currentPage != pages.count - 1 {
                    PaginationDotsView(
                        currentPage: currentPage,
                        pageCount: pages.count,
                        safeAreaBottom: geometry.safeAreaInsets.bottom
                    )
                }

                if currentPage == pages.count - 1 {
                    VStack(spacing: 0) {
                        Spacer()

                        VStack(spacing: 24) {
                            Text("Ready to boost your productivity?")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)

                            Button {
                                withAnimation {
                                    hasCompletedOnboarding = true
                                }
                            } label: {
                                Text("Get Started")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 64)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .fill(.white)
                                            .shadow(
                                                color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                                    )
                                    .overlay {
                                        LinearGradient(
                                            colors: pages[currentPage].gradientColors,
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                        .mask(
                                            Text("Get Started")
                                                .font(.title3)
                                                .fontWeight(.bold)
                                        )
                                    }
                            }
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 32, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .blur(radius: 0)
                        )
                        .padding(.horizontal, 24)
                        .padding(.bottom, geometry.safeAreaInsets.bottom + 16)
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}

struct OnboardingPage {
    let title: String
    let description: String
    let imageName: String
    let accentColor: Color
    let gradientColors: [Color]
}

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: page.imageName)
                .font(.system(size: 100))
                .foregroundColor(.white)

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)

                Text(page.description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
    }
}

struct AnimatedGradientBackground: View {
    let colors: [[Color]]
    let currentPage: Int
    let pageCount: Int

    var body: some View {
        GeometryReader { geometry in
            let progress = CGFloat(currentPage)
            let nextPage = min(currentPage + 1, pageCount - 1)

            LinearGradient(
                colors: blendGradients(
                    colors[currentPage],
                    colors[nextPage],
                    progress: progress.truncatingRemainder(dividingBy: 1)
                ),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .animation(.easeInOut, value: currentPage)
    }

    private func blendGradients(_ gradient1: [Color], _ gradient2: [Color], progress: CGFloat)
        -> [Color]
    {
        guard progress > 0 else { return gradient1 }
        return zip(gradient1, gradient2).map { color1, color2 in
            blend(from: color1, to: color2, progress: progress)
        }
    }

    private func blend(from: Color, to: Color, progress: Double) -> Color {
        let p = max(0, min(1, progress))

        #if os(iOS)
            let fromComponents = UIColor(from).cgColor.components ?? [0, 0, 0, 1]
            let toComponents = UIColor(to).cgColor.components ?? [0, 0, 0, 1]

            let r = fromComponents[0] + (toComponents[0] - fromComponents[0]) * p
            let g = fromComponents[1] + (toComponents[1] - fromComponents[1]) * p
            let b = fromComponents[2] + (toComponents[2] - fromComponents[2]) * p
            let a = fromComponents[3] + (toComponents[3] - fromComponents[3]) * p

            return Color(uiColor: UIColor(red: r, green: g, blue: b, alpha: a))
        #else
            return from
        #endif
    }
}

struct PaginationDotsView: View {
    let currentPage: Int
    let pageCount: Int
    let safeAreaBottom: CGFloat

    var body: some View {
        VStack {
            Spacer()

            Capsule()
                .fill(.ultraThinMaterial)
                .frame(width: CGFloat(pageCount * 16 + 24), height: 40)
                .overlay {
                    HStack(spacing: 12) {
                        ForEach(0..<pageCount, id: \.self) { index in
                            Circle()
                                .fill(currentPage == index ? .white : .white.opacity(0.5))
                                .frame(width: 10, height: 10)
                                .scaleEffect(currentPage == index ? 1.2 : 1)
                                .animation(.spring(response: 0.3), value: currentPage)
                        }
                    }
                    .padding(.horizontal, 12)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, safeAreaBottom + 16)
        }
    }
}

#Preview {
    OnboardingView()
}
