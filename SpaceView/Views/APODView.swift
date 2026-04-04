import SwiftUI
import Photos

struct APODView: View {
    @State private var viewModel: APODViewModel
    @Environment(FavoritesStore.self) private var favorites
    @Environment(\.openURL) private var openURL

    @State private var showDatePicker = false
    @State private var showFullscreen = false
    @State private var pickerDate = Date()

    @MainActor
    init(viewModel: APODViewModel? = nil) {
        _viewModel = State(initialValue: viewModel ?? APODViewModel())
    }

    var body: some View {
        ZStack {
            SpaceTheme.background.ignoresSafeArea()

            if viewModel.isLoading {
                LoadingView()
            } else if let entry = viewModel.entry {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        HeroSection(entry: entry, openURL: openURL) {
                            showFullscreen = true
                        }
                        .overlay(alignment: .topTrailing) {
                            FavoriteButton(isFavorite: favorites.contains(entry)) {
                                favorites.toggle(entry)
                            }
                            .padding(16)
                        }

                        // Date navigation bar
                        DateNavBar(viewModel: viewModel) {
                            pickerDate = viewModel.selectedDate
                            showDatePicker = true
                        }

                        MetadataSection(entry: entry)
                        ExplanationSection(text: entry.explanation)
                        Spacer(minLength: 40)
                    }
                }
                .refreshable { await viewModel.loadToday() }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        HStack(spacing: 12) {
                            if entry.isImage, let url = URL(string: entry.hdurl ?? entry.url) {
                                ShareLink(item: url, subject: Text(entry.title)) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(SpaceTheme.textSecondary)
                                }
                            }
                        }
                    }
                }
                .fullScreenCover(isPresented: $showFullscreen) {
                    if let url = URL(string: entry.hdurl ?? entry.url), entry.isImage {
                        FullscreenImageView(url: url, title: entry.title)
                    }
                }
            } else if let error = viewModel.errorMessage {
                ErrorView(message: error) {
                    Task { await viewModel.loadToday() }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(SpaceTheme.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Text(viewModel.isToday ? "Today" : formattedNavDate(viewModel.selectedDate))
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(SpaceTheme.textPrimary)
            }
        }
        .sheet(isPresented: $showDatePicker) {
            DatePickerSheet(selected: $pickerDate) {
                viewModel.selectedDate = pickerDate
                Task { await viewModel.loadSelected() }
            }
            .presentationDetents([.medium])
        }
        .task { await viewModel.loadToday() }
    }

    private func formattedNavDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }
}

// MARK: - Date navigation bar

private struct DateNavBar: View {
    let viewModel: APODViewModel
    let onCalendarTap: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            // Previous
            Button {
                Task { await viewModel.loadPrevious() }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(viewModel.canGoPrev ? SpaceTheme.accentBlue : SpaceTheme.textTertiary)
                    .frame(width: 44, height: 36)
            }
            .disabled(!viewModel.canGoPrev)
            .buttonStyle(.plain)

            Spacer()

            // Calendar picker button
            Button(action: onCalendarTap) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 13))
                    Text(viewModel.isToday ? "Today" : formattedDate(viewModel.selectedDate))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(SpaceTheme.accentBlue)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(SpaceTheme.accentBlue.opacity(0.12), in: Capsule())
            }
            .buttonStyle(.plain)

            Spacer()

            // Next
            Button {
                Task { await viewModel.loadNext() }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(viewModel.canGoNext ? SpaceTheme.accentBlue : SpaceTheme.textTertiary)
                    .frame(width: 44, height: 36)
            }
            .disabled(!viewModel.canGoNext)
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }

    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }
}

// MARK: - Date picker sheet

private struct DatePickerSheet: View {
    @Binding var selected: Date
    let onConfirm: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Cancel") { dismiss() }
                    .foregroundStyle(SpaceTheme.textSecondary)
                Spacer()
                Text("Choose a Date")
                    .font(.headline)
                    .foregroundStyle(SpaceTheme.textPrimary)
                Spacer()
                Button("Go") {
                    onConfirm()
                    dismiss()
                }
                .font(.headline)
                .foregroundStyle(SpaceTheme.accentBlue)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 8)

            DatePicker(
                "",
                selection: $selected,
                in: APODViewModel.minDate...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .tint(SpaceTheme.accentBlue)
            .padding(.horizontal, 12)

            Spacer()
        }
        .background(SpaceTheme.background)
        .colorScheme(.dark)
    }
}

// MARK: - Fullscreen zoom viewer

struct FullscreenImageView: View {
    let url: URL
    let title: String

    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var savedImage: UIImage?
    @State private var saveStatus: SaveStatus = .idle

    enum SaveStatus { case idle, saving, saved, failed }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let img):
                    img.resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { v in scale = max(1, lastScale * v) }
                                .onEnded { _ in lastScale = scale }
                                .simultaneously(with:
                                    DragGesture()
                                        .onChanged { v in
                                            if scale > 1 {
                                                offset = CGSize(
                                                    width: lastOffset.width + v.translation.width,
                                                    height: lastOffset.height + v.translation.height)
                                            }
                                        }
                                        .onEnded { _ in lastOffset = offset }
                                )
                        )
                        .onTapGesture(count: 2) {
                            withAnimation(.spring(duration: 0.3)) {
                                if scale > 1 { scale = 1; lastScale = 1; offset = .zero; lastOffset = .zero }
                                else { scale = 2.5; lastScale = 2.5 }
                            }
                        }
                        .onAppear {
                            // Cache UIImage for save
                            Task {
                                if let (data, _) = try? await URLSession.shared.data(from: url) {
                                    savedImage = UIImage(data: data)
                                }
                            }
                        }
                case .failure:
                    Image(systemName: "photo")
                        .font(.system(size: 48))
                        .foregroundStyle(SpaceTheme.textTertiary)
                default:
                    ShimmerBox()
                }
            }
            .ignoresSafeArea()

            // Top controls
            VStack {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .black.opacity(0.4))
                            .padding(20)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    // Save to photos
                    Button {
                        saveToPhotos()
                    } label: {
                        Group {
                            switch saveStatus {
                            case .idle:
                                Image(systemName: "square.and.arrow.down")
                                    .font(.title3)
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, .black.opacity(0.4))
                            case .saving:
                                ProgressView().tint(.white)
                            case .saved:
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(.green)
                            case .failed:
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(.red)
                            }
                        }
                        .padding(20)
                    }
                    .buttonStyle(.plain)
                    .disabled(saveStatus == .saving || savedImage == nil)
                }

                Spacer()

                // Title
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                    .shadow(radius: 4)
            }
        }
    }

    private func saveToPhotos() {
        guard let img = savedImage else { return }
        saveStatus = .saving
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            DispatchQueue.main.async {
                guard status == .authorized || status == .limited else {
                    saveStatus = .failed
                    return
                }
                UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
                saveStatus = .saved
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    saveStatus = .idle
                }
            }
        }
    }
}

// MARK: - Hero (image or video)

private struct HeroSection: View {
    let entry: APODEntry
    let openURL: OpenURLAction
    let onTap: () -> Void

    var body: some View {
        if entry.isImage {
            ImageHero(entry: entry, onTap: onTap)
        } else {
            VideoHero(entry: entry, openURL: openURL)
        }
    }
}

private struct ImageHero: View {
    let entry: APODEntry
    let onTap: () -> Void

    var body: some View {
        Color.clear
            .frame(height: 420)
            .frame(maxWidth: .infinity)
            .overlay {
                AsyncImage(url: URL(string: entry.hdurl ?? entry.url)) { phase in
                    switch phase {
                    case .success(let image): image.resizable().scaledToFill()
                    case .failure:
                        SpaceTheme.surface.overlay(
                            Image(systemName: "sparkles")
                                .font(.system(size: 48))
                                .foregroundStyle(SpaceTheme.accentBlue)
                        )
                    default: ShimmerBox()
                    }
                }
            }
            .clipped()
            .overlay(alignment: .bottom) {
                SpaceTheme.heroGradient.frame(height: 230)
            }
            .overlay(alignment: .bottomTrailing) {
                Button(action: onTap) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(.black.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
                        .padding(12)
                }
                .buttonStyle(.plain)
            }
            .onTapGesture(perform: onTap)
    }
}

private struct VideoHero: View {
    let entry: APODEntry
    let openURL: OpenURLAction

    var body: some View {
        Button {
            if let url = entry.youtubeWatchURL { openURL(url) }
        } label: {
            Color.clear
                .frame(height: 420)
                .frame(maxWidth: .infinity)
                .overlay {
                    AsyncImage(url: entry.youtubeThumbnailURL) { phase in
                        switch phase {
                        case .success(let img): img.resizable().scaledToFill()
                        case .failure:
                            SpaceTheme.surface.overlay(
                                Image(systemName: "play.rectangle")
                                    .font(.system(size: 48))
                                    .foregroundStyle(SpaceTheme.accentBlue)
                            )
                        default: ShimmerBox()
                        }
                    }
                }
                .clipped()
                .overlay {
                    ZStack {
                        Circle()
                            .fill(.black.opacity(0.5))
                            .frame(width: 72, height: 72)
                        Image(systemName: "play.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white)
                            .offset(x: 3)
                    }
                }
                .overlay(alignment: .bottom) {
                    SpaceTheme.heroGradient.frame(height: 230)
                }
                .overlay(alignment: .topLeading) {
                    Label("Video", systemImage: "play.circle.fill")
                        .font(.caption.bold())
                        .foregroundStyle(SpaceTheme.accentGold)
                        .padding(8)
                        .background(.black.opacity(0.5), in: Capsule())
                        .padding(16)
                }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Favorite button

struct FavoriteButton: View {
    let isFavorite: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(isFavorite ? .red : .white)
                .padding(10)
                .background(.black.opacity(0.4), in: Circle())
                .symbolEffect(.bounce, value: isFavorite)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Title / date / copyright

private struct MetadataSection: View {
    let entry: APODEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SpaceTheme.sectionLabel("Astronomy Picture of the Day")
            SpaceTheme.heroTitle(entry.title)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 16) {
                Label(formattedDate(entry.date), systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(SpaceTheme.textSecondary)
                if let cr = entry.copyright {
                    Label(cr.trimmingCharacters(in: .whitespacesAndNewlines), systemImage: "camera")
                        .font(.caption)
                        .foregroundStyle(SpaceTheme.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func formattedDate(_ raw: String) -> String {
        let parser = DateFormatter(); parser.dateFormat = "yyyy-MM-dd"
        let display = DateFormatter(); display.dateStyle = .long
        if let d = parser.date(from: raw) { return display.string(from: d) }
        return raw
    }
}

// MARK: - Explanation card

private struct ExplanationSection: View {
    let text: String
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SpaceTheme.sectionLabel("Description")
            Text(text)
                .font(.system(size: 15))
                .foregroundStyle(SpaceTheme.textSecondary)
                .lineSpacing(5)
                .lineLimit(expanded ? nil : 5)
                .animation(.easeInOut(duration: 0.25), value: expanded)
            Button { expanded.toggle() } label: {
                Label(expanded ? "Show less" : "Read more",
                      systemImage: expanded ? "chevron.up" : "chevron.down")
                    .font(.caption.bold())
                    .foregroundStyle(SpaceTheme.accentBlue)
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
        .padding(.horizontal, 16)
    }
}

// MARK: - Loading / Error

private struct LoadingView: View {
    @State private var spinning = false
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle().stroke(SpaceTheme.accentBlue.opacity(0.2), lineWidth: 2).frame(width: 72, height: 72)
                Circle().trim(from: 0, to: 0.75)
                    .stroke(SpaceTheme.accentBlue, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 72, height: 72)
                    .rotationEffect(.degrees(spinning ? 360 : 0))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: spinning)
                Image(systemName: "sparkle").font(.title2).foregroundStyle(SpaceTheme.accentGold)
            }
            .onAppear { spinning = true }
            Text("Scanning the cosmos…")
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundStyle(SpaceTheme.textSecondary)
        }
    }
}

private struct ErrorView: View {
    let message: String
    let retry: () -> Void
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle").font(.system(size: 48)).foregroundStyle(SpaceTheme.accentGold)
            VStack(spacing: 8) {
                Text("Signal Lost").font(.title3.bold()).foregroundStyle(SpaceTheme.textPrimary)
                Text(message).font(.footnote).foregroundStyle(SpaceTheme.textSecondary).multilineTextAlignment(.center)
            }
            Button(action: retry) {
                Text("Retry").font(.subheadline.bold()).foregroundStyle(SpaceTheme.background)
                    .padding(.horizontal, 32).padding(.vertical, 12)
                    .background(SpaceTheme.accentBlue, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(40)
    }
}

#Preview {
    APODView(viewModel: APODViewModel(preview: .preview))
        .environment(FavoritesStore())
        .preferredColorScheme(.dark)
}
