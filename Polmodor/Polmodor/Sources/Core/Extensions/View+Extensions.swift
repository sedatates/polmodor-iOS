import SwiftUI

// MARK: - Tab Bar Extensions
// Tab bar ile ilgili tüm extension'lar burada toplanmıştır
enum TabBarModifier {
  // Default height for the tab bar padding, can be adjusted globally here
  static var defaultPaddingHeight: CGFloat = 100

  // Tab bar renkleri ve stilleri için sabitler
  enum Style {
    static let backgroundColor: Color = .white
    static let selectedColor: Color = .blue
    static let unselectedColor: Color = .gray
    static let cornerRadius: CGFloat = 24
    static let shadowRadius: CGFloat = 15
    static let shadowOpacity: Double = 0.05
  }
}

// MARK: - Floating Tab Bar Bottom Padding
/// Floating tab bar için gerekli olan bottom padding modifier'ı
struct FloatingTabBarBottomPadding: ViewModifier {
  // Custom height parameter or use default
  var height: CGFloat?

  // Final padding height to apply
  private var paddingHeight: CGFloat {
    return height ?? TabBarModifier.defaultPaddingHeight
  }

  func body(content: Content) -> some View {
    content
      .safeAreaInset(edge: .bottom) {
        Color.clear.frame(height: paddingHeight)
      }
  }
}

// MARK: - List Item Padding for Bottom Tab Bar
/// Liste öğelerinin tab bar altında kaybolmasını engelleyen modifier
struct ListBottomPadding: ViewModifier {
  // Custom height parameter or use default
  var height: CGFloat?

  // Final padding height to apply, slightly more for lists to account for bounce
  private var paddingHeight: CGFloat {
    return height ?? (TabBarModifier.defaultPaddingHeight + 20)
  }

  func body(content: Content) -> some View {
    content
      .padding(.bottom, paddingHeight)
  }
}

// MARK: - Scroll View Bottom Padding
/// ScrollView için özel bottom padding modifier
struct ScrollViewBottomPadding: ViewModifier {
  // Custom height parameter or use default
  var height: CGFloat?

  // Final padding height to apply
  private var paddingHeight: CGFloat {
    return height ?? TabBarModifier.defaultPaddingHeight
  }

  func body(content: Content) -> some View {
    content
      .padding(.bottom, paddingHeight)
      .padding(.bottom)  // Extra padding for bounce effect
  }
}

// MARK: - View Extensions
extension View {
  /// Floating tab bar için bottom padding ekler
  /// - Parameter height: İsteğe bağlı özel yükseklik. Nil ise global ayarı kullanır
  func withFloatingTabBarPadding(height: CGFloat? = nil) -> some View {
    self.modifier(FloatingTabBarBottomPadding(height: height))
  }

  /// Liste öğelerinin tab bar altında kalmaması için özel padding
  /// - Parameter height: İsteğe bağlı özel yükseklik. Nil ise global ayarı kullanır
  func withListBottomPadding(height: CGFloat? = nil) -> some View {
    self.modifier(ListBottomPadding(height: height))
  }

  /// ScrollView içeriğinin tab bar altında kalmaması için özel padding
  /// - Parameter height: İsteğe bağlı özel yükseklik. Nil ise global ayarı kullanır
  func withScrollViewBottomPadding(height: CGFloat? = nil) -> some View {
    self.modifier(ScrollViewBottomPadding(height: height))
  }
}

//UISCreen.main.bounds.width
extension UIScreen {
    static var screenWidth: CGFloat {
        return UIScreen.main.bounds.width
    }
    static var screenHeight: CGFloat {
        return UIScreen.main.bounds.height
    }
}
