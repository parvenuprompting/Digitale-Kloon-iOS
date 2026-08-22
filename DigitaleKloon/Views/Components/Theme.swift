import SwiftUI

extension Color {
    static let backgroundPrimary = Color("BackgroundPrimary")
    static let backgroundSecondary = Color("BackgroundSecondary")
    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")
    static let accent = Color("AccentColor")
}

struct CardBackground: ViewModifier {
    var cornerRadius: CGFloat = 18

    func body(content: Content) -> some View {
        content
            .background(Color.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

extension View {
    func kloonCard(cornerRadius: CGFloat = 18) -> some View {
        modifier(CardBackground(cornerRadius: cornerRadius))
    }
}

/// Compact uppercase eyebrow label used to title cards.
struct Eyebrow: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.caption2.weight(.bold))
            .tracking(1.2)
            .foregroundStyle(Color.textSecondary)
    }
}

/// Reusable in-navigation-bar header with the app mark + title.
struct BrandHeader: View {
    let title: String

    var body: some View {
        HStack(spacing: 7) {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .accessibilityHidden(true)

            Text(title)
                .font(.headline)
                .foregroundStyle(Color.textPrimary)
        }
    }
}