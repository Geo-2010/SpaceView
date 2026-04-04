import SwiftUI

struct FavoritesView: View {
    @Environment(FavoritesStore.self) private var favorites

    var body: some View {
        NavigationStack {
            ZStack {
                SpaceTheme.background.ignoresSafeArea()

                if favorites.apodEntries.isEmpty && favorites.nasaImages.isEmpty {
                    EmptyFavoritesView()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 24) {
                            if !favorites.apodEntries.isEmpty {
                                APODFavoritesSection(entries: favorites.apodEntries) { entry in
                                    favorites.toggle(entry)
                                }
                            }
                            if !favorites.nasaImages.isEmpty {
                                NASAImageFavoritesSection(images: favorites.nasaImages) { image in
                                    favorites.toggle(image)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("Saved")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(SpaceTheme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

// MARK: - Empty state

private struct EmptyFavoritesView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.slash")
                .font(.system(size: 56))
                .foregroundStyle(SpaceTheme.textTertiary)
            VStack(spacing: 8) {
                Text("No Saved Items")
                    .font(.title3.bold())
                    .foregroundStyle(SpaceTheme.textPrimary)
                Text("Tap the heart icon on any image\nor article to save it here.")
                    .font(.subheadline)
                    .foregroundStyle(SpaceTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
    }
}

// MARK: - APOD favorites section

private struct APODFavoritesSection: View {
    let entries: [APODEntry]
    let onRemove: (APODEntry) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SpaceTheme.sectionLabel("Astronomy Pictures")

            ForEach(entries) { entry in
                NavigationLink(destination: APODView(viewModel: APODViewModel(preview: entry))) {
                    APODFavoriteCard(entry: entry)
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) { onRemove(entry) } label: {
                        Label("Remove", systemImage: "heart.slash")
                    }
                }
            }
        }
    }
}

private struct APODFavoriteCard: View {
    let entry: APODEntry

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            Color.clear
                .frame(width: 80, height: 80)
                .overlay {
                    if entry.isImage {
                        AsyncImage(url: URL(string: entry.hdurl ?? entry.url)) { phase in
                            switch phase {
                            case .success(let img): img.resizable().scaledToFill()
                            case .failure:
                                SpaceTheme.surface.overlay(Image(systemName: "sparkles").foregroundStyle(SpaceTheme.accentBlue))
                            default: ShimmerBox()
                            }
                        }
                    } else {
                        AsyncImage(url: entry.youtubeThumbnailURL) { phase in
                            switch phase {
                            case .success(let img): img.resizable().scaledToFill()
                            default:
                                SpaceTheme.surface.overlay(Image(systemName: "play.rectangle").foregroundStyle(SpaceTheme.accentBlue))
                            }
                        }
                    }
                }
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(SpaceTheme.textPrimary)
                    .lineLimit(2)
                HStack(spacing: 6) {
                    if !entry.isImage {
                        Label("Video", systemImage: "play.circle.fill")
                            .font(.caption2.bold())
                            .foregroundStyle(SpaceTheme.accentGold)
                    }
                    Text(entry.date)
                        .font(.caption)
                        .foregroundStyle(SpaceTheme.textTertiary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(SpaceTheme.textTertiary)
        }
        .padding(12)
        .background(SpaceTheme.surface, in: RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - NASA image favorites section

private struct NASAImageFavoritesSection: View {
    let images: [NASAImage]
    let onRemove: (NASAImage) -> Void

    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SpaceTheme.sectionLabel("NASA Images")

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(images) { image in
                    NavigationLink(destination: NASAImageDetailView(image: image)) {
                        NASAFavThumb(image: image)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) { onRemove(image) } label: {
                            Label("Remove from Saved", systemImage: "heart.slash")
                        }
                    }
                }
            }
        }
    }
}

private struct NASAFavThumb: View {
    let image: NASAImage

    var body: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                AsyncImage(url: image.thumbnailURL) { phase in
                    switch phase {
                    case .success(let img): img.resizable().scaledToFill()
                    case .failure:
                        SpaceTheme.surface.overlay(Image(systemName: "photo").foregroundStyle(SpaceTheme.textTertiary))
                    default: ShimmerBox()
                    }
                }
            }
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    FavoritesView()
        .environment(FavoritesStore())
        .preferredColorScheme(.dark)
}
