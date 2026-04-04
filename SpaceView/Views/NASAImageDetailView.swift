import SwiftUI

struct NASAImageDetailView: View {
    let image: NASAImage
    @Environment(FavoritesStore.self) private var favorites

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                Color.clear
                    .frame(height: 320)
                    .frame(maxWidth: .infinity)
                    .overlay {
                        AsyncImage(url: image.largeURL ?? image.thumbnailURL) { phase in
                            switch phase {
                            case .success(let img): img.resizable().scaledToFill()
                            case .failure:
                                SpaceTheme.surface.overlay(
                                    Image(systemName: "photo")
                                        .font(.system(size: 48))
                                        .foregroundStyle(SpaceTheme.textTertiary)
                                )
                            default: ShimmerBox()
                            }
                        }
                    }
                    .clipped()
                    .overlay(alignment: .bottom) {
                        SpaceTheme.heroGradient.frame(height: 160)
                    }

                VStack(alignment: .leading, spacing: 12) {
                    SpaceTheme.sectionLabel("NASA Image Library")
                    Text(image.title)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(SpaceTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    if !image.formattedDate.isEmpty {
                        Label(image.formattedDate, systemImage: "calendar")
                            .font(.caption)
                            .foregroundStyle(SpaceTheme.textSecondary)
                    }

                    if !image.description.isEmpty {
                        Divider().background(SpaceTheme.textTertiary)
                        Text(image.description)
                            .font(.system(size: 15))
                            .foregroundStyle(SpaceTheme.textSecondary)
                            .lineSpacing(5)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 40)
            }
        }
        .background(SpaceTheme.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(SpaceTheme.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                FavoriteButton(isFavorite: favorites.contains(image)) {
                    favorites.toggle(image)
                }
            }
        }
    }
}
