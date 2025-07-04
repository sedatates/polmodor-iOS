import SwiftUI
import RevenueCat

struct SubscriptionView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var subscriptionManager = SubscriptionManager.shared
  @State private var isLoading = false
  @State private var errorMessage: String?
  @State private var selectedPackage: Package?
  
  var body: some View {
    NavigationView {
      ZStack {
        // Modern gradient background
        LinearGradient(
          colors: [
            Color(red: 0.1, green: 0.1, blue: 0.3),
            Color(red: 0.2, green: 0.0, blue: 0.4),
            Color(red: 0.1, green: 0.0, blue: 0.2)
          ],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        ScrollView {
          VStack(spacing: 32) {
            // Modern header with premium badge
            VStack(spacing: 20) {
              ZStack {
                Circle()
                  .fill(
                    LinearGradient(
                      colors: [.yellow, .orange, .pink],
                      startPoint: .topLeading,
                      endPoint: .bottomTrailing
                    )
                  )
                  .frame(width: 100, height: 100)
                  .shadow(color: .yellow.opacity(0.3), radius: 20, x: 0, y: 10)
                
                Image(systemName: "crown.fill")
                  .font(.system(size: 40, weight: .bold))
                  .foregroundStyle(.white)
              }
              
              VStack(spacing: 12) {
                Text("Polmodor")
                  .font(.system(size: 28, weight: .bold, design: .rounded))
                  .foregroundStyle(.white)
                
                Text("Premium")
                  .font(.system(size: 32, weight: .black, design: .rounded))
                  .foregroundStyle(
                    LinearGradient(
                      colors: [.yellow, .orange],
                      startPoint: .leading,
                      endPoint: .trailing
                    )
                  )
                
                Text("Unlock the full potential of your productivity")
                  .font(.system(size: 16, weight: .medium, design: .rounded))
                  .foregroundStyle(.white.opacity(0.8))
                  .multilineTextAlignment(.center)
                  .padding(.horizontal)
              }
            }
            .padding(.top, 20)
            
            // Modern features grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
              ModernFeatureCard(
                icon: "infinity",
                title: "Unlimited Tasks",
                description: "Create as many tasks as you need",
                color: .blue
              )
              
              ModernFeatureCard(
                icon: "chart.line.uptrend.xyaxis",
                title: "Advanced Stats",
                description: "Track your productivity",
                color: .green
              )
              
              ModernFeatureCard(
                icon: "icloud.and.arrow.up",
                title: "Cloud Sync",
                description: "Sync across devices",
                color: .purple
              )
              
              ModernFeatureCard(
                icon: "paintbrush.fill",
                title: "Custom Themes",
                description: "Personalize experience",
                color: .orange
              )
            }
            .padding(.horizontal, 24)
            
            // Modern subscription options
            if let offerings = subscriptionManager.offerings,
               let currentOffering = offerings.current {
              VStack(spacing: 16) {
                Text("Choose Your Plan")
                  .font(.system(size: 22, weight: .bold, design: .rounded))
                  .foregroundStyle(.white)
                  .padding(.top, 8)
                
                ForEach(currentOffering.availablePackages, id: \.identifier) { package in
                  ModernSubscriptionCard(
                    package: package,
                    isSelected: selectedPackage?.identifier == package.identifier,
                    isLoading: isLoading,
                    onSelect: { selectedPackage = package },
                    onPurchase: { await purchase(package: package) }
                  )
                }
                
                // Modern CTA button
                if selectedPackage != nil {
                  Button {
                    if let package = selectedPackage {
                      Task { await purchase(package: package) }
                    }
                  } label: {
                    HStack {
                      if isLoading {
                        ProgressView()
                          .scaleEffect(0.8)
                          .tint(.white)
                      } else {
                        Image(systemName: "crown.fill")
                          .font(.system(size: 16, weight: .bold))
                      }
                      
                      Text(isLoading ? "Processing..." : "Start Premium")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                      LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .leading,
                        endPoint: .trailing
                      ),
                      in: RoundedRectangle(cornerRadius: 27)
                    )
                    .shadow(color: .yellow.opacity(0.3), radius: 10, x: 0, y: 5)
                  }
                  .disabled(isLoading)
                  .scaleEffect(isLoading ? 0.95 : 1.0)
                  .animation(.easeInOut(duration: 0.1), value: isLoading)
                }
              }
              .padding(.horizontal, 24)
            }
            
            // Modern restore button
            Button {
              Task { await restorePurchases() }
            } label: {
              Text("Restore Purchases")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
            }
            .disabled(isLoading)
            
            if let errorMessage = errorMessage {
              Text(errorMessage)
                .foregroundStyle(.red)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                  RoundedRectangle(cornerRadius: 12)
                    .stroke(.red.opacity(0.3), lineWidth: 1)
                )
            }
          }
          .padding(.bottom, 40)
        }
      }
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button {
            dismiss()
          } label: {
            Image(systemName: "xmark")
              .font(.system(size: 16, weight: .bold))
              .foregroundStyle(.white.opacity(0.8))
              .frame(width: 32, height: 32)
              .background(.white.opacity(0.1), in: Circle())
          }
        }
      }
    }
    .task {
      await subscriptionManager.fetchOfferings()
    }
  }
  
  @MainActor
  private func purchase(package: Package) async {
    isLoading = true
    errorMessage = nil
    
    do {
      _ = try await subscriptionManager.purchase(package: package)
      dismiss()
    } catch {
      errorMessage = "Purchase failed: \(error.localizedDescription)"
    }
    
    isLoading = false
  }
  
  @MainActor
  private func restorePurchases() async {
    isLoading = true
    errorMessage = nil
    
    do {
      _ = try await subscriptionManager.restorePurchases()
      if subscriptionManager.isPremium {
        dismiss()
      } else {
        errorMessage = "No previous purchases found"
      }
    } catch {
      errorMessage = "Restore failed: \(error.localizedDescription)"
    }
    
    isLoading = false
  }
}

struct ModernFeatureCard: View {
  let icon: String
  let title: String
  let description: String
  let color: Color
  
  var body: some View {
    VStack(spacing: 16) {
      ZStack {
        Circle()
          .fill(color.opacity(0.2))
          .frame(width: 60, height: 60)
        
        Image(systemName: icon)
          .font(.system(size: 24, weight: .bold))
          .foregroundStyle(color)
      }
      
      VStack(spacing: 8) {
        Text(title)
          .font(.system(size: 16, weight: .bold, design: .rounded))
          .foregroundStyle(.white)
          .multilineTextAlignment(.center)
        
        Text(description)
          .font(.system(size: 12, weight: .medium, design: .rounded))
          .foregroundStyle(.white.opacity(0.7))
          .multilineTextAlignment(.center)
      }
    }
    .padding(.vertical, 24)
    .padding(.horizontal, 12)
    .background(
      RoundedRectangle(cornerRadius: 20)
        .fill(.white.opacity(0.1))
        .overlay(
          RoundedRectangle(cornerRadius: 20)
            .stroke(.white.opacity(0.2), lineWidth: 1)
        )
    )
  }
}

struct ModernSubscriptionCard: View {
  let package: Package
  let isSelected: Bool
  let isLoading: Bool
  let onSelect: () -> Void
  let onPurchase: () async -> Void
  
  private var isRecommended: Bool {
    package.packageType == .annual
  }
  
  private var savingsText: String? {
    if package.packageType == .annual {
      return "Save 50%"
    }
    return nil
  }
  
  var body: some View {
    Button {
      onSelect()
    } label: {
      VStack(spacing: 0) {
        if isRecommended {
          HStack {
            Text("MOST POPULAR")
              .font(.system(size: 12, weight: .bold, design: .rounded))
              .foregroundStyle(.white)
            
            Spacer()
            
            if let savings = savingsText {
              Text(savings)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            }
          }
          .padding(.horizontal, 20)
          .padding(.vertical, 8)
          .background(
            LinearGradient(
              colors: [.green, .blue],
              startPoint: .leading,
              endPoint: .trailing
            ),
            in: UnevenRoundedRectangle(
              topLeadingRadius: 16,
              topTrailingRadius: 16
            )
          )
        }
        
        VStack(spacing: 16) {
          HStack {
            VStack(alignment: .leading, spacing: 8) {
              Text(package.storeProduct.localizedTitle)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
              
              Text(package.storeProduct.localizedDescription)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
              Text(package.storeProduct.localizedPriceString)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
              
              if package.packageType == .annual {
                Text("per year")
                  .font(.system(size: 12, weight: .medium, design: .rounded))
                  .foregroundStyle(.white.opacity(0.6))
              } else {
                Text("per month")
                  .font(.system(size: 12, weight: .medium, design: .rounded))
                  .foregroundStyle(.white.opacity(0.6))
              }
            }
          }
          
          if isSelected {
            HStack {
              Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.green)
              
              Text("Selected")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.green)
              
              Spacer()
            }
          }
        }
        .padding(20)
        .background(
          RoundedRectangle(cornerRadius: isRecommended ? 0 : 16)
            .fill(.white.opacity(0.1))
            .overlay(
              RoundedRectangle(cornerRadius: isRecommended ? 0 : 16)
                .stroke(
                  isSelected ? .white.opacity(0.6) : .white.opacity(0.2),
                  lineWidth: isSelected ? 2 : 1
                )
            )
        )
      }
      .clipShape(RoundedRectangle(cornerRadius: 16))
      .scaleEffect(isSelected ? 1.02 : 1.0)
      .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    .disabled(isLoading)
    .buttonStyle(.plain)
  }
}

#Preview {
  SubscriptionView()
}