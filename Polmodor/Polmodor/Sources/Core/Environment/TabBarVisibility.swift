import SwiftUI

public class TabBarVisibility {
  public var setVisible: (Bool) -> Void = { _ in }

  public init() {}
}

public struct TabBarVisibilityKey: EnvironmentKey {
  public static let defaultValue = TabBarVisibility()
}

extension EnvironmentValues {
    public var tabBarVisibility: TabBarVisibility {
    get { self[TabBarVisibilityKey.self] }
    set { self[TabBarVisibilityKey.self] = newValue }
  }
}
