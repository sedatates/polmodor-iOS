import Combine
import Foundation
import SwiftUI

final class ZenModeController: ObservableObject {
  private var timer: AnyCancellable?
  private var lastInteraction = Date()
  private var onStateChange: ((Bool) -> Void)?

  func setup(
    zenModeEnabled: Bool,
    zenModeDelay: TimeInterval,
    onStateChange: @escaping (Bool) -> Void
  ) {
    self.onStateChange = onStateChange

    timer = Timer.publish(every: 0.5, on: .main, in: .common)
      .autoconnect()
      .sink { [weak self] _ in
        guard let self = self,
          zenModeEnabled
        else {
          onStateChange(true)
          return
        }

        let timeSinceLastInteraction = Date().timeIntervalSince(self.lastInteraction)
        if timeSinceLastInteraction >= zenModeDelay {
            withAnimation(.easeInOut(duration: 0.5)) {
            onStateChange(false)
          }
        }
      }
  }

  func resetTimer() {
    lastInteraction = Date()
  }
}
