#if canImport(SwiftUI)
import SwiftUI
import NetSphereCore

public struct NewsDeskView: View {
    @StateObject private var viewModel: NewsDeskViewModel
    private let onReturnToManor: () -> Void

    public init(
        viewModel: NewsDeskViewModel = NewsDeskViewModel(),
        onReturnToManor: @escaping () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onReturnToManor = onReturnToManor
    }

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            LivingGradient()
                .opacity(0.2)
                .blur(radius: 48)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: MyDataDCSpacing.large) {
                    header
                    if viewModel.displayedArticles.isEmpty {
                        emptyState
                    } else {
                        LazyVStack(spacing: MyDataDCSpacing.medium) {
                            ForEach(viewModel.displayedArticles) { article in
                                articleCard(article)
                            }
                        }
                    }
                }
                .padding(MyDataDCSpacing.xLarge)
            }
        }
        .navigationTitle("NewsDesk")
        .task { await viewModel.load() }
    }

    private var header: some View {
        FrostedPanel {
            VStack(alignment: .leading, spacing: MyDataDCSpacing.small) {
                HStack {
                    VStack(alignment: .leading, spacing: MyDataDCSpacing.xSmall) {
                        Text("NewsDesk")
                            .font(.largeTitle.bold())
                        Text("Every headline. Different perspectives. One desk.")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(action: onReturnToManor) {
                        Label("The Manor", systemImage: "building.columns")
                    }
                    .buttonStyle(.bordered)
                }

                HStack(spacing: MyDataDCSpacing.small) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search headlines, sources, and topics", text: $viewModel.query)
                        .textFieldStyle(.roundedBorder)
                    if !viewModel.query.isEmpty {
                        Button("Clear") { viewModel.clearSearch() }
                            .buttonStyle(.borderless)
                    }
                }
                .frame(maxWidth: 620)
            }
        }
    }

    private var emptyState: some View {
        FrostedPanel {
            VStack(spacing: MyDataDCSpacing.medium) {
                Image(systemName: viewModel.query.isEmpty ? "newspaper" : "magnifyingglass")
                    .font(.system(size: 42, weight: .semibold))
                Text(viewModel.query.isEmpty ? "No briefing yet" : "No matching stories")
                    .font(.title2.bold())
                Text(viewModel.query.isEmpty
                    ? "NewsDesk will display verified stories after a source is connected."
                    : "Try another search or clear the current query.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                if !viewModel.query.isEmpty {
                    Button("Clear Search") { viewModel.clearSearch() }
                        .buttonStyle(.borderedProminent)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 260)
        }
    }

    private func articleCard(_ article: NewsArticle) -> some View {
        FrostedPanel {
            VStack(alignment: .leading, spacing: MyDataDCSpacing.small) {
                HStack {
                    Text(article.urgency.rawValue.uppercased())
                        .font(.caption.bold())
                        .foregroundStyle(article.urgency >= .breaking ? .red : .secondary)
                    Text(article.scope.rawValue.uppercased())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        Task { await viewModel.toggleSaved(article) }
                    } label: {
                        Image(systemName: viewModel.isSaved(article) ? "bookmark.fill" : "bookmark")
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel(viewModel.isSaved(article) ? "Remove bookmark" : "Save article")
                }

                Text(article.headline)
                    .font(.title3.bold())
                Text(article.summary)
                    .foregroundStyle(.secondary)
                Text("\(article.source.name) · \(article.publishedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
#endif
