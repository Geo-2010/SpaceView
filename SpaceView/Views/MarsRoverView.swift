import SwiftUI

struct MarsRoverView: View {
    @State private var viewModel = MarsViewModel()
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            ZStack {
                SpaceTheme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar
                    SearchBar(text: $viewModel.searchText) {
                        Task { await viewModel.search() }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                    // Preset picker
                    HStack(spacing: 0) {
                        ForEach(NASAService.SpaceQuery.allCases, id: \.self) { query in
                            let selected = viewModel.activePreset == query
                            Button {
                                Task { await viewModel.selectPreset(query) }
                            } label: {
                                Text(query.displayName)
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(selected ? SpaceTheme.background : SpaceTheme.textSecondary)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .background(selected ? SpaceTheme.accentBlue : Color.clear, in: Capsule())
                            }
                            .buttonStyle(.plain)
                            .animation(.spring(duration: 0.2), value: selected)
                        }
                    }
                    .padding(4)
                    .glassCard()
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)

                    if viewModel.isLoading {
                        Spacer(); LoadingIndicator(); Spacer()
                    } else if let error = viewModel.errorMessage {
                        Spacer()
                        SpaceErrorView(message: error) { Task { await viewModel.load() } }
                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(viewModel.images) { image in
                                    NavigationLink(destination: NASAImageDetailView(image: image)) {
                                        NASAImageCard(image: image)
                                    }
                                    .buttonStyle(.plain)
                                    .onAppear {
                                        if image.id == viewModel.images.last?.id {
                                            Task { await viewModel.loadMore() }
                                        }
                                    }
                                }
                                if viewModel.isLoadingMore {
                                    ProgressView().tint(SpaceTheme.accentBlue)
                                        .gridCellColumns(2).padding()
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                        }
                        .refreshable { await viewModel.load() }
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .task { await viewModel.load() }
    }
}

// MARK: - Search bar

struct SearchBar: View {
    @Binding var text: String
    let onSubmit: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(SpaceTheme.textSecondary)
            TextField("Search NASA images…", text: $text)
                .foregroundStyle(SpaceTheme.textPrimary)
                .tint(SpaceTheme.accentBlue)
                .onSubmit(onSubmit)
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(SpaceTheme.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(SpaceTheme.surface, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Image card

private struct NASAImageCard: View {
    let image: NASAImage

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Color.clear
                .frame(height: 130)
                .frame(maxWidth: .infinity)
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

            Text(image.title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(SpaceTheme.textPrimary)
                .lineLimit(2)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(SpaceTheme.surface)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Shared components (used by EarthView, NewsView)

struct LoadingIndicator: View {
    @State private var spinning = false
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle().stroke(SpaceTheme.accentBlue.opacity(0.2), lineWidth: 2).frame(width: 64, height: 64)
                Circle().trim(from: 0, to: 0.75)
                    .stroke(SpaceTheme.accentBlue, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 64, height: 64)
                    .rotationEffect(.degrees(spinning ? 360 : 0))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: spinning)
                Image(systemName: "sparkle").foregroundStyle(SpaceTheme.accentGold)
            }
            .onAppear { spinning = true }
            Text("Scanning the cosmos…")
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(SpaceTheme.textSecondary)
        }
    }
}

struct SpaceErrorView: View {
    let message: String
    let retry: () -> Void
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle").font(.system(size: 44)).foregroundStyle(SpaceTheme.accentGold)
            VStack(spacing: 6) {
                Text("Signal Lost").font(.title3.bold()).foregroundStyle(SpaceTheme.textPrimary)
                Text(message).font(.footnote).foregroundStyle(SpaceTheme.textSecondary).multilineTextAlignment(.center)
            }
            Button(action: retry) {
                Text("Retry").font(.subheadline.bold()).foregroundStyle(SpaceTheme.background)
                    .padding(.horizontal, 28).padding(.vertical, 10)
                    .background(SpaceTheme.accentBlue, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(32)
    }
}

#Preview {
    MarsRoverView()
        .environment(FavoritesStore())
        .preferredColorScheme(.dark)
}
