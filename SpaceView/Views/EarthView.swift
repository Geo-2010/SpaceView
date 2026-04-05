import SwiftUI

struct EarthView: View {
    @State private var viewModel = SolarSystemViewModel()
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            ZStack {
                SpaceTheme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    PlanetPicker(selected: viewModel.selectedPlanet) { planet in
                        Task { await viewModel.selectPlanet(planet) }
                    }

                    if viewModel.isLoading {
                        Spacer()
                        LoadingIndicator()
                        Spacer()
                    } else if let error = viewModel.errorMessage {
                        Spacer()
                        SpaceErrorView(message: error) { Task { await viewModel.load() } }
                        Spacer()
                    } else {
                        // 3D interactive globe — drag to rotate, pinch to zoom
                        PlanetView3D(planet: viewModel.selectedPlanet)
                            .frame(height: 260)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .padding(.bottom, 4)

                        if viewModel.selectedPlanet == .earth {
                            EarthEPICContent(viewModel: viewModel)
                        } else {
                            PlanetImageGrid(images: viewModel.planetImages, columns: columns, viewModel: viewModel)
                                .refreshable { await viewModel.load() }
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .task { await viewModel.load() }
    }
}

// MARK: - Planet picker

private struct PlanetPicker: View {
    let selected: Planet
    let onSelect: (Planet) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Planet.allCases) { planet in
                    let isSelected = selected == planet
                    Button { onSelect(planet) } label: {
                        VStack(spacing: 4) {
                            Text(planet.symbol)
                                .font(.system(size: 22))
                            Text(planet.displayName)
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundStyle(isSelected ? SpaceTheme.background : SpaceTheme.textSecondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(isSelected ? SpaceTheme.accentBlue : SpaceTheme.surface,
                                    in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .animation(.spring(duration: 0.2), value: isSelected)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}

// MARK: - Earth EPIC content

private struct EarthEPICContent: View {
    @Bindable var viewModel: SolarSystemViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                if let image = viewModel.currentEPIC {
                    // Hero
                    Color.clear
                        .frame(height: 320)
                        .frame(maxWidth: .infinity)
                        .overlay {
                            AsyncImage(url: image.imageURL) { phase in
                                switch phase {
                                case .success(let img): img.resizable().scaledToFill()
                                case .failure:
                                    SpaceTheme.surface.overlay(
                                        Image(systemName: "globe.americas.fill")
                                            .font(.system(size: 80))
                                            .foregroundStyle(SpaceTheme.accentBlue.opacity(0.4))
                                    )
                                default: ShimmerBox()
                                }
                            }
                        }
                        .clipped()
                        .overlay(alignment: .bottom) {
                            SpaceTheme.heroGradient.frame(height: 160)
                        }

                    // Info
                    VStack(alignment: .leading, spacing: 8) {
                        SpaceTheme.sectionLabel("DSCOVR / EPIC Camera — Live Earth")
                        SpaceTheme.heroTitle(image.formattedDate)
                        Text(image.caption)
                            .font(.footnote)
                            .foregroundStyle(SpaceTheme.textSecondary)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Thumbnail strip
                    if viewModel.epicImages.count > 1 {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(Array(viewModel.epicImages.enumerated()), id: \.element.id) { index, epic in
                                    Color.clear
                                        .frame(width: 58, height: 58)
                                        .overlay {
                                            AsyncImage(url: epic.imageURL) { phase in
                                                if case .success(let img) = phase {
                                                    img.resizable().scaledToFill()
                                                } else {
                                                    SpaceTheme.surface
                                                }
                                            }
                                        }
                                        .clipShape(Circle())
                                        .clipped()
                                        .overlay(Circle().strokeBorder(
                                            viewModel.epicIndex == index ? SpaceTheme.accentBlue : Color.clear,
                                            lineWidth: 2))
                                        .onTapGesture { viewModel.epicIndex = index }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.bottom, 16)
                    }
                }
            }
        }
        .refreshable { await viewModel.load() }
    }
}

// MARK: - Planet image grid

private struct PlanetImageGrid: View {
    let images: [NASAImage]
    let columns: [GridItem]
    @Bindable var viewModel: SolarSystemViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(images) { image in
                    NavigationLink(destination: NASAImageDetailView(image: image)) {
                        PlanetImageCard(image: image)
                    }
                    .buttonStyle(.plain)
                    .onAppear {
                        if image.id == images.last?.id {
                            Task { await viewModel.loadMore() }
                        }
                    }
                }
                if viewModel.isLoadingMore {
                    ProgressView()
                        .tint(SpaceTheme.accentBlue)
                        .gridCellColumns(2)
                        .padding()
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }
}

private struct PlanetImageCard: View {
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
                            SpaceTheme.surface.overlay(
                                Image(systemName: "photo").foregroundStyle(SpaceTheme.textTertiary)
                            )
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

#Preview {
    EarthView()
        .preferredColorScheme(.dark)
}
