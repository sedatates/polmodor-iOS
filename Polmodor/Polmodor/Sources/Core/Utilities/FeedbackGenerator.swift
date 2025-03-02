import SwiftUI

struct FeedbackGenerator {
  private let generator = UIImpactFeedbackGenerator(style: .medium)

  func impact(intensity: CGFloat = 1.0) {
    generator.impactOccurred(intensity: intensity)
  }

  func prepare() {
    generator.prepare()
  }
}
