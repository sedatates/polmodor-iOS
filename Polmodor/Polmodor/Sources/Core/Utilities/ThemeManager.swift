import Combine
import SwiftData
import SwiftUI

/// Uygulama temasını yöneten singleton sınıf
@Observable final class ThemeManager {
  /// Shared instance for app-wide access
  static let shared = ThemeManager()

  /// Uygulama teması için şu anki mod
  private(set) var isDarkMode: Bool = false

  /// Özel bir içerik görünümü kullanılıp kullanılmadığını belirten bayrak
  private var isOverridden: Bool = false

  /// Tema değişimlerini dinleyen cancellables
  private var cancellables = Set<AnyCancellable>()

  private init() {
    // Varsayılan olarak açık tema ile başla
    self.isDarkMode = false
  }

  /// Karanlık modu etkinleştirir veya devre dışı bırakır
  /// - Parameter isDarkMode: Karanlık modun durumu
  func setDarkMode(_ isDarkMode: Bool) {
    self.isDarkMode = isDarkMode
  }

  /// Tema ayarlarını günceller (modellerden)
  /// - Parameter isDarkModeOn: Karanlık mod açık mı?
  func updateTheme(isDarkModeOn: Bool) {
    self.isDarkMode = isDarkModeOn
  }

  /// Geçerli temayı temel alan ColorScheme döndürür
  var colorScheme: ColorScheme {
    isDarkMode ? .dark : .light
  }
}

/// Tema çevresi değerleri için ortam anahtarı
struct ThemeEnvironmentKey: EnvironmentKey {
  static var defaultValue: ThemeManager = .shared
}

extension EnvironmentValues {
  var themeManager: ThemeManager {
    get { self[ThemeEnvironmentKey.self] }
    set { self[ThemeEnvironmentKey.self] = newValue }
  }
}

/// View'lara tema eklemek için SwiftUI uzantısı
extension View {
  /// Geçerli uygulama temasını uygular
  func withAppTheme() -> some View {
    self.environment(\.colorScheme, ThemeManager.shared.colorScheme)
  }
}
