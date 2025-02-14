import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    
    private let pages = [
        OnboardingPage(
            title: "Welcome to Polmodor",
            description: "Boost your productivity with the Pomodoro Technique™",
            imageName: "timer.circle.fill",
            accentColor: .blue
        ),
        OnboardingPage(
            title: "Stay Focused",
            description: "Work in focused 25-minute intervals, followed by short breaks",
            imageName: "brain.head.profile",
            accentColor: .purple
        ),
        OnboardingPage(
            title: "Track Tasks",
            description: "Organize and track your tasks with built-in task management",
            imageName: "checklist",
            accentColor: .green
        ),
        OnboardingPage(
            title: "Monitor Progress",
            description: "View your productivity stats and improve over time",
            imageName: "chart.bar.fill",
            accentColor: .orange
        )
    ]
    
    var body: some View {
        TabView(selection: $currentPage) {
            ForEach(pages.indices, id: \.self) { index in
                OnboardingPageView(page: pages[index])
                    .tag(index)
            }
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .overlay(alignment: .bottom) {
            if currentPage == pages.count - 1 {
                Button {
                    withAnimation {
                        hasCompletedOnboarding = true
                    }
                } label: {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .background(Color.accentColor)
                        .cornerRadius(12)
                }
                .padding()
            }
        }
    }
}

struct OnboardingPage {
    let title: String
    let description: String
    let imageName: String
    let accentColor: Color
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: page.imageName)
                .font(.system(size: 100))
                .foregroundColor(page.accentColor)
            
            VStack(spacing: 12) {
                Text(page.title)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 32)
            
            Spacer()
            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
} 