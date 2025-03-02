import Combine
import SwiftData
import SwiftUI

/// Uygulama temasını yöneten singleton sınıf
final class ThemeManager: ObservableObject {
  /// Shared instance for app-wide access
  static let shared = ThemeManager()

  /// UserDefaults anahtarları
  private enum Keys {
    static let isDarkMode = "ThemeManager.isDarkMode"
    static let useSystemTheme = "ThemeManager.useSystemTheme"
  }

  /// Uygulama teması için şu anki mod
  @Published var isDarkMode: Bool {
    didSet {
      // Tema değiştiğinde UserDefaults'a kaydet
      if !isUpdatingFromSystem {
        UserDefaults.standard.set(isDarkMode, forKey: Keys.isDarkMode)
      }
    }
  }

  /// Sistem temasını takip etme durumu
  @Published var useSystemTheme: Bool {
    didSet {
      UserDefaults.standard.set(useSystemTheme, forKey: Keys.useSystemTheme)
      if useSystemTheme {
        updateToMatchSystemTheme()
      }
    }
  }

  /// Sistem güncellemesinden kaynaklı değişim olduğunu belirten bayrak
  private var isUpdatingFromSystem: Bool = false

  /// Tema değişimlerini dinleyen cancellables
  private var cancellables = Set<AnyCancellable>()

  /// Mevcut sistem renk şeması
  @Published private var systemColorScheme: ColorScheme = .light

  private init() {
    // UserDefaults'tan kayıtlı temaları yükle
    self.isDarkMode = UserDefaults.standard.bool(forKey: Keys.isDarkMode)
    self.useSystemTheme = UserDefaults.standard.bool(forKey: Keys.useSystemTheme)

    // Başlangıçta sistem teması kullanılacaksa sisteme uyumlu hale getir
    if useSystemTheme {
      updateToMatchSystemTheme()
    }
  }

  /// Mevcut sistem temasını algılar ve ThemeManager'ı günceller
  /// Bu fonksiyon bir SwiftUI view'dan çağrılmalıdır
  func detectSystemTheme(colorScheme: ColorScheme) {
    // Sistem renk şemasını güncelle
    self.systemColorScheme = colorScheme

    // Eğer sistem temasını takip ediyorsak, temanın renk şemasını güncelle
    if useSystemTheme {
      updateToMatchSystemTheme()
    }
  }

  /// Sistemi temasına eşleştirme
  private func updateToMatchSystemTheme() {
    // Sistem tema değişimlerine yanıt ver
    self.isUpdatingFromSystem = true
    self.isDarkMode = (systemColorScheme == .dark)
    self.isUpdatingFromSystem = false
  }

  /// Karanlık modu etkinleştirir veya devre dışı bırakır
  /// - Parameter isDarkMode: Karanlık modun durumu
  func setDarkMode(_ isDarkMode: Bool) {
    self.useSystemTheme = false  // Kullanıcı manuel ayar yaptığında sistem teması takibini kapat
    self.isDarkMode = isDarkMode
  }

  /// Sistem teması takip modunu ayarlar
  /// - Parameter useSystem: Sistem temasını takip etme durumu
  func setUseSystemTheme(_ useSystem: Bool) {
    self.useSystemTheme = useSystem
    if useSystem {
      updateToMatchSystemTheme()
    }
  }

  /// Tema ayarlarını günceller (modellerden)
  /// - Parameter isDarkModeOn: Karanlık mod açık mı?
  func updateTheme(isDarkModeOn: Bool) {
    self.useSystemTheme = false
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
  /// Geçerli uygulama temasını uygular ve sistem tema değişimlerini izler
  func withAppTheme() -> some View {
    self
      .environment(\.colorScheme, ThemeManager.shared.colorScheme)
      .onAppear {
        // View ilk yüklendiğinde mevcut sistem temasını algıla
        ThemeManager.shared.detectSystemTheme(colorScheme: self.colorScheme)
      }
      .onChange(of: self.colorScheme) { oldValue, newValue in
        // Sistem teması değiştiğinde ThemeManager'ı bilgilendir
        ThemeManager.shared.detectSystemTheme(colorScheme: newValue)
      }
  }

  /// Tema değişimlerini izleyen bir değişken
  private var colorScheme: ColorScheme {
    @Environment(\.colorScheme) var colorScheme
    return colorScheme
  }
}
