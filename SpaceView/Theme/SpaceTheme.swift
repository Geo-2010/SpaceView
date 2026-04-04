import SwiftUI

enum SpaceTheme {
    // MARK: - Colors
    static let background    = Color(red: 0.04, green: 0.04, blue: 0.12)   // deep space black
    static let surface       = Color(red: 0.08, green: 0.08, blue: 0.20)   // slightly lighter panel
    static let accentBlue    = Color(red: 0.22, green: 0.58, blue: 1.00)   // nebula blue
    static let accentGold    = Color(red: 1.00, green: 0.80, blue: 0.30)   // star gold
    static let textPrimary   = Color.white
    static let textSecondary = Color(white: 0.65)
    static let textTertiary  = Color(white: 0.40)

    // MARK: - Gradients
    static let heroGradient = LinearGradient(
        colors: [.clear, background.opacity(0.6), background],
        startPoint: .top,
        endPoint: .bottom
    )

    static let cardGradient = LinearGradient(
        colors: [surface.opacity(0.85), surface.opacity(0.6)],
        startPoint: .top,
        endPoint: .bottom
    )

    static let shimmerGradient = LinearGradient(
        colors: [surface, surface.opacity(0.4), surface],
        startPoint: .leading,
        endPoint: .trailing
    )

    // MARK: - Typography
    static func heroTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 26, weight: .bold, design: .rounded))
            .foregroundStyle(textPrimary)
    }

    static func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .foregroundStyle(accentBlue)
            .tracking(2)
    }
}

// MARK: - Glass card modifier
struct GlassCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(Color.white.opacity(0.10), lineWidth: 0.8)
                    )
            )
    }
}

extension View {
    func glassCard() -> some View { modifier(GlassCard()) }
}

// MARK: - Shimmer placeholder
struct ShimmerBox: View {
    @State private var phase: CGFloat = -1

    var body: some View {
        Rectangle()
            .fill(SpaceTheme.shimmerGradient)
            .mask(Rectangle())
            .onAppear {
                withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}
