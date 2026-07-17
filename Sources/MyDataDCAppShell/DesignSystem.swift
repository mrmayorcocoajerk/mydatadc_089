#if canImport(SwiftUI)
import SwiftUI

public enum MyDataDCSpacing {
    public static let xSmall: CGFloat = 6
    public static let small: CGFloat = 10
    public static let medium: CGFloat = 16
    public static let large: CGFloat = 24
    public static let xLarge: CGFloat = 36
}

public enum MyDataDCRadius {
    public static let card: CGFloat = 24
    public static let panel: CGFloat = 30
}

public struct LivingGradient: View {
    public init() {}

    public var body: some View {
        LinearGradient(
            colors: [.cyan.opacity(0.85), .blue.opacity(0.72), .purple.opacity(0.88)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

public struct FrostedPanel<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(MyDataDCSpacing.large)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: MyDataDCRadius.panel, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: MyDataDCRadius.panel, style: .continuous)
                    .stroke(.white.opacity(0.18), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.22), radius: 24, y: 16)
    }
}
#endif
