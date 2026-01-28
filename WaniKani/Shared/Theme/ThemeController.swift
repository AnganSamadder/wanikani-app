import SwiftUI
import WaniKaniCore

// MARK: - Theme Mode

public enum ThemeMode: Int, CaseIterable {
    case system = 0
    case light = 1
    case dark = 2
    
    public var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
    
    public var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
    
    public var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - Theme Controller

/// Manages app-wide theme preferences.
/// This is a view-only controller that reads/writes to PreferencesManager.
@MainActor
public final class ThemeController: ObservableObject {
    public static let shared = ThemeController()
    
    private let preferences: PreferencesManager
    
    @Published public var themeMode: ThemeMode {
        didSet {
            saveThemeMode()
        }
    }
    
    /// Convenience property for backward compatibility with `darkModeEnabled`
    public var preferredColorScheme: ColorScheme? {
        themeMode.colorScheme
    }
    
    private init(preferences: PreferencesManager = PreferencesManager()) {
        self.preferences = preferences
        
        // Load saved theme mode
        // Legacy: if darkModeEnabled was true, treat as dark mode
        if preferences.darkModeEnabled {
            self.themeMode = .dark
        } else {
            // Default to system
            self.themeMode = .system
        }
    }
    
    private func saveThemeMode() {
        // Update legacy preference for CSSInjector compatibility
        preferences.darkModeEnabled = (themeMode == .dark)
    }
    
    /// Toggle between light and dark (useful for quick toggle)
    public func toggleDarkMode() {
        switch themeMode {
        case .system:
            themeMode = .dark
        case .light:
            themeMode = .dark
        case .dark:
            themeMode = .light
        }
    }
}

// MARK: - Theme Environment Modifier

/// A view modifier that applies the theme controller's color scheme
public struct ThemedViewModifier: ViewModifier {
    @ObservedObject private var themeController = ThemeController.shared
    
    public func body(content: Content) -> some View {
        content
            .preferredColorScheme(themeController.preferredColorScheme)
    }
}

extension View {
    /// Apply app-wide theme from ThemeController
    public func applyTheme() -> some View {
        modifier(ThemedViewModifier())
    }
}
