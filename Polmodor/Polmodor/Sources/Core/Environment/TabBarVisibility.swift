import SwiftUI

final class TabBarVisibility: ObservableObject {
  @Published var isVisible: Bool = true

  func setVisible(_ visible: Bool) {
    withAnimation(.easeInOut(duration: 0.3)) {
      isVisible = visible
    }
  }
}

private struct TabBarVisibilityKey: EnvironmentKey {
  static let defaultValue = TabBarVisibility()
}

extension EnvironmentValues {
  var tabBarVisibility: TabBarVisibility {
    get { self[TabBarVisibilityKey.self] }
    set { self[TabBarVisibilityKey.self] = newValue }
  }
}
