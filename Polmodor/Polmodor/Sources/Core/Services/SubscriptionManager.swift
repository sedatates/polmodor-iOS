import Foundation
import RevenueCat
import RevenueCatUI
import SwiftUI

@Observable final class SubscriptionManager {
  static let shared = SubscriptionManager()

  // MARK: - Properties
  var isPremium: Bool = false
  var customerInfo: CustomerInfo?
  var offerings: Offerings?

  // MARK: - Constants
  private let premiumEntitlementID = "premium"

  private init() {
    setupRevenueCat()
    checkSubscriptionStatus()
  }

  // MARK: - RevenueCat Setup
  private func setupRevenueCat() {
    Purchases.logLevel = .debug

    // TODO: Replace with your actual RevenueCat API key
    // You can get this from https://app.revenuecat.com/
    // Navigate to your project -> App settings -> API keys -> Public app-specific API key
    #if DEBUG
      Purchases.configure(withAPIKey: "appl_djjhPSkAwTfdGJDegynRAuzLury")  // Replace with your actual API key
    #else
      Purchases.configure(withAPIKey: "appl_djjhPSkAwTfdGJDegynRAuzLury")  // Replace with your actual API key
    #endif
  }

  // MARK: - Subscription Status
  func checkSubscriptionStatus() {
    Task {
      do {
        let customerInfo = try await Purchases.shared.customerInfo()
        await MainActor.run {
          self.customerInfo = customerInfo
          self.isPremium = customerInfo.entitlements[premiumEntitlementID]?.isActive == true
        }
      } catch {
        print("❌ Error checking subscription status: \(error)")
      }
    }
  }

  // MARK: - Offerings
  func fetchOfferings() async {
    do {
      let offerings = try await Purchases.shared.offerings()
      await MainActor.run {
        self.offerings = offerings
      }
    } catch {
      print("❌ Error fetching offerings: \(error)")
    }
  }

  // MARK: - Purchase (Legacy support)
  func purchase(package: Package) async throws -> CustomerInfo {
    let result = try await Purchases.shared.purchase(package: package)
    let customerInfo = result.customerInfo

    await MainActor.run {
      self.customerInfo = customerInfo
      self.isPremium = customerInfo.entitlements[premiumEntitlementID]?.isActive == true
    }

    return customerInfo
  }

  // MARK: - Restore (Legacy support)
  func restorePurchases() async throws -> CustomerInfo {
    let customerInfo = try await Purchases.shared.restorePurchases()

    await MainActor.run {
      self.customerInfo = customerInfo
      self.isPremium = customerInfo.entitlements[premiumEntitlementID]?.isActive == true
    }

    return customerInfo
  }

  // MARK: - Modern Paywall Integration

  /// Called when modern paywall purchase is completed
  func onPaywallPurchaseCompleted(customerInfo: CustomerInfo) {
    Task { @MainActor in
      self.customerInfo = customerInfo
      self.isPremium = customerInfo.entitlements[premiumEntitlementID]?.isActive == true

      // Provide haptic feedback
      let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
      impactFeedback.impactOccurred()

      print("✅ Premium subscription activated!")
    }
  }

  /// Called when modern paywall restore is completed
  func onPaywallRestoreCompleted(customerInfo: CustomerInfo) {
    Task { @MainActor in
      self.customerInfo = customerInfo
      self.isPremium = customerInfo.entitlements[premiumEntitlementID]?.isActive == true

      if isPremium {
        print("✅ Premium subscription restored!")
      }
    }
  }

  // MARK: - Task Limit Check
  func canAddMoreTasks(currentTaskCount: Int) -> Bool {
    if isPremium {
      return true  // Premium users can add unlimited tasks
    } else {
      return currentTaskCount < 1  // Free users can only have 1 task
    }
  }

  func shouldShowSubscriptionPrompt(currentTaskCount: Int) -> Bool {
    return !isPremium && currentTaskCount >= 1
  }

  // MARK: - Premium Features
  func canAccessAdvancedStatistics() -> Bool {
    return isPremium
  }

  func canAccessCustomThemes() -> Bool {
    return isPremium
  }

  func canAccessCloudSync() -> Bool {
    return isPremium
  }

  func maxTasksForFreeUser() -> Int {
    return 1
  }

  func getRemainingFreeTasks(currentTaskCount: Int) -> Int {
    if isPremium {
      return Int.max
    } else {
      return max(0, maxTasksForFreeUser() - currentTaskCount)
    }
  }

  // MARK: - Subscription Info
  func getPremiumStatusText() -> String {
    if isPremium {
      return "Premium Active"
    } else {
      return "Free Plan"
    }
  }

  func getSubscriptionExpirationDate() -> Date? {
    return customerInfo?.entitlements[premiumEntitlementID]?.expirationDate
  }

  // MARK: - Premium Benefits
  func getPremiumBenefits() -> [PremiumBenefit] {
    return [
      PremiumBenefit(
        icon: "infinity",
        title: "Unlimited Tasks",
        description: "Create as many tasks as you need",
        color: .blue
      ),
      PremiumBenefit(
        icon: "chart.line.uptrend.xyaxis",
        title: "Advanced Statistics",
        description: "Track your productivity over time",
        color: .green
      ),
      PremiumBenefit(
        icon: "icloud.and.arrow.up",
        title: "Cloud Sync",
        description: "Sync your data across all devices",
        color: .purple
      ),
      PremiumBenefit(
        icon: "paintbrush.fill",
        title: "Custom Themes",
        description: "Personalize your timer experience",
        color: .orange
      ),
    ]
  }

  // MARK: - Subscription Status
  func getSubscriptionStatus() -> SubscriptionStatus {
    if isPremium {
      if let expirationDate = getSubscriptionExpirationDate() {
        return .premium(expiresAt: expirationDate)
      } else {
        return .premium(expiresAt: nil)
      }
    } else {
      return .free
    }
  }
}

// MARK: - Supporting Types
struct PremiumBenefit: Identifiable {
  let id = UUID()
  let icon: String
  let title: String
  let description: String
  let color: Color
}

enum SubscriptionStatus {
  case free
  case premium(expiresAt: Date?)

  var displayText: String {
    switch self {
    case .free:
      return "Free Plan"
    case .premium(let expiresAt):
      if let date = expiresAt {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "Premium until \(formatter.string(from: date))"
      } else {
        return "Premium Active"
      }
    }
  }

  var isPremium: Bool {
    switch self {
    case .free:
      return false
    case .premium:
      return true
    }
  }
}
