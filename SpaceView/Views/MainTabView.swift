import SwiftUI

struct MainTabView: View {
    @State private var selected: Tab = .apod

    enum Tab: CaseIterable {
        case apod, news, explore, planets, saved

        var icon: String {
            switch self {
            case .apod:    return "sparkles"
            case .news:    return "newspaper"
            case .explore: return "photo.stack"
            case .planets: return "globe"
            case .saved:   return "heart"
            }
        }

        var label: String {
            switch self {
            case .apod:    return "Today"
            case .news:    return "News"
            case .explore: return "Explore"
            case .planets: return "Planets"
            case .saved:   return "Saved"
            }
        }
    }

    private let tabBarHeight: CGFloat = 80

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selected {
                case .apod:    APODView()
                case .news:    NewsView()
                case .explore: MarsRoverView()
                case .planets: EarthView()
                case .saved:   FavoritesView()
                }
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: tabBarHeight)
            }

            // Floating glass tab bar
            HStack(spacing: 0) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    TabBarButton(tab: tab, selected: $selected)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .glassCard()
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .background(SpaceTheme.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }
}

private struct TabBarButton: View {
    let tab: MainTabView.Tab
    @Binding var selected: MainTabView.Tab

    private var isSelected: Bool { selected == tab }

    var body: some View {
        Button {
            withAnimation(.spring(duration: 0.25)) { selected = tab }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? "\(tab.icon).fill" : tab.icon)
                    .font(.system(size: 20))
                    .symbolEffect(.bounce, value: isSelected)
                Text(tab.label)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(isSelected ? SpaceTheme.accentBlue : SpaceTheme.textTertiary)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MainTabView()
}
