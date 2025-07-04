import Foundation
import RevenueCat
import RevenueCatUI
import SwiftUI
import UIKit

@MainActor
@Observable final class PaywallManager {
  static let shared = PaywallManager()

  // MARK: - Properties
  private let subscriptionManager = SubscriptionManager.shared

  // MARK: - Constants
  private let premiumEntitlementID = "premium"

  private init() {}

  // MARK: - Paywall Presentation Helpers

  /// Checks if paywall should be shown based on task limits
  func shouldShowPaywallForTasks(currentTaskCount: Int) -> Bool {
    return subscriptionManager.shouldShowSubscriptionPrompt(currentTaskCount: currentTaskCount)
  }

  /// Checks if paywall should be shown for premium features
  func shouldShowPaywallForPremiumFeature() -> Bool {
    return !subscriptionManager.isPremium
  }

  // MARK: - Paywall Event Handlers

  /// Handles successful purchase completion
  func handlePurchaseCompleted(customerInfo: CustomerInfo) {
    print("💳 PaywallManager: Purchase completed")
    subscriptionManager.onPaywallPurchaseCompleted(customerInfo: customerInfo)

    // Force refresh after a short delay to ensure UI updates
    Task {
      try? await Task.sleep(for: .seconds(0.5))
      subscriptionManager.forceRefreshSubscriptionStatus()
    }
  }

  /// Handles successful restore completion
  func handleRestoreCompleted(customerInfo: CustomerInfo) {
    print("🔄 PaywallManager: Restore completed")
    subscriptionManager.onPaywallRestoreCompleted(customerInfo: customerInfo)

    // Force refresh after a short delay to ensure UI updates
    Task {
      try? await Task.sleep(for: .seconds(0.5))
      subscriptionManager.forceRefreshSubscriptionStatus()
    }
  }
}

// MARK: - SwiftUI Integration

extension View {
  /// Presents RevenueCat paywall if user doesn't have premium entitlement
  func presentPolmodorPaywallIfNeeded() -> some View {
    self.presentPaywallIfNeeded(
      requiredEntitlementIdentifier: "Premium",
      purchaseCompleted: { customerInfo in
        PaywallManager.shared.handlePurchaseCompleted(customerInfo: customerInfo)
      },
      restoreCompleted: { customerInfo in
        PaywallManager.shared.handleRestoreCompleted(customerInfo: customerInfo)
      }
    )
  }

  /// Presents paywall when a condition is met (e.g., task limit reached)
  func presentPolmodorPaywallWhen(_ condition: Bool) -> some View {
    if condition {
      return AnyView(self.presentPolmodorPaywallIfNeeded())
    } else {
      return AnyView(self)
    }
  }
}
