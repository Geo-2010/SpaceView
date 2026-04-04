import SwiftUI

struct NewsView: View {
    @State private var viewModel = NewsViewModel()
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            ZStack {
                SpaceTheme.background.ignoresSafeArea()

                if viewModel.isLoading {
                    LoadingIndicator()
                } else if let error = viewModel.errorMessage {
                    SpaceErrorView(message: error) { Task { await viewModel.load() } }
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.articles) { article in
                                NewsCard(article: article)
                                    .onTapGesture {
                                        if let url = article.articleURL { openURL(url) }
                                    }
                                    .onAppear {
                                        if article.id == viewModel.articles.last?.id {
                                            Task { await viewModel.loadMore() }
                                        }
                                    }
                            }

                            if viewModel.isLoadingMore {
                                ProgressView()
                                    .tint(SpaceTheme.accentBlue)
                                    .padding()
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .refreshable { await viewModel.load() }
                }
            }
            .navigationBarHidden(true)
        }
        .task { await viewModel.load() }
    }
}

// MARK: - News card

private struct NewsCard: View {
    let article: NewsArticle

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Thumbnail
            Color.clear
                .frame(width: 90, height: 90)
                .overlay {
                    AsyncImage(url: article.thumbnailURL) { phase in
                        switch phase {
                        case .success(let img): img.resizable().scaledToFill()
                        case .failure:
                            SpaceTheme.surface.overlay(
                                Image(systemName: "newspaper")
                                    .foregroundStyle(SpaceTheme.textTertiary)
                            )
                        default: ShimmerBox()
                        }
                    }
                }
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 10))

            // Text
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(article.newsSite.uppercased())
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(SpaceTheme.accentBlue)
                        .tracking(1)
                    Spacer()
                    Text(article.formattedDate)
                        .font(.system(size: 9))
                        .foregroundStyle(SpaceTheme.textTertiary)
                }

                Text(article.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(SpaceTheme.textPrimary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                Text(article.summary)
                    .font(.system(size: 11))
                    .foregroundStyle(SpaceTheme.textSecondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .glassCard()
    }
}

#Preview {
    NewsView()
        .preferredColorScheme(.dark)
}
