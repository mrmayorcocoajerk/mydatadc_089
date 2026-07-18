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

                HStack(spacing: MyDataDCSpacing.small) {
                    Picker("Scope", selection: $viewModel.selectedScope) {
                        Text("All scopes").tag(nil as NewsScope?)
                        ForEach(viewModel.availableScopes, id: \.self) { scope in
                            Text(scope.displayName).tag(scope as NewsScope?)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 190)

                    Toggle(isOn: $viewModel.showsSavedOnly) {
                        Label("Saved (\(viewModel.savedArticleCount))", systemImage: "bookmark.fill")
                    }
                    .toggleStyle(.button)

                    if viewModel.hasActiveFilters {
                        Button("Reset filters") { viewModel.resetFilters() }
                            .buttonStyle(.borderless)
                    }

                    Spacer()
                    Text("\(viewModel.displayedArticles.count) of \(viewModel.snapshot.articles.count) stories")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: MyDataDCSpacing.small) {
                    Button {
                        Task { await viewModel.refresh() }
                    } label: {
                        if viewModel.isRefreshing {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Label("Refresh Briefing", systemImage: "arrow.clockwise")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isRefreshing)

                    if let briefing = viewModel.briefing {
                        Text("Updated \(briefing.generatedAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if !viewModel.sourceStatuses.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: MyDataDCSpacing.small) {
                            ForEach(viewModel.sourceStatuses) { status in
                                HStack(spacing: MyDataDCSpacing.xSmall) {
                                    Circle()
                                        .fill(sourceColor(for: status.state))
                                        .frame(width: 7, height: 7)
                                    Text(status.name)
                                        .font(.caption.bold())
                                    Text(status.detail)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, MyDataDCSpacing.small)
                                .padding(.vertical, MyDataDCSpacing.xSmall)
                                .background(.thinMaterial, in: Capsule())
                            }
                        }
                    }
                }

                if let message = viewModel.statusMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let message = viewModel.errorMessage {
                    Label(message, systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    private var emptyState: some View {
        FrostedPanel {
            VStack(spacing: MyDataDCSpacing.medium) {
                Image(systemName: viewModel.showsSavedOnly ? "bookmark" : (viewModel.hasActiveFilters ? "line.3.horizontal.decrease.circle" : "newspaper"))
                    .font(.system(size: 42, weight: .semibold))
                Text(emptyStateTitle)
                    .font(.title2.bold())
                Text(emptyStateMessage)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                if viewModel.hasActiveFilters {
                    Button("Reset Filters") { viewModel.resetFilters() }
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
                    Text(article.scope.displayName.uppercased())
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
                if let url = article.canonicalURL {
                    Link("Read full story", destination: url)
                        .font(.caption.bold())
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var emptyStateTitle: String {
        if viewModel.showsSavedOnly { return "No saved stories" }
        if viewModel.hasActiveFilters { return "No matching stories" }
        return "No briefing yet"
    }

    private var emptyStateMessage: String {
        if viewModel.showsSavedOnly { return "Save a story with its bookmark button, or reset the filters." }
        if viewModel.hasActiveFilters { return "Try another scope or search, or reset the filters." }
        return "Refresh NewsDesk to load the latest stories."
    }

    private func sourceColor(for state: NewsDeskSourceStatus.State) -> Color {
        switch state {
        case .waiting: .gray
        case .cached: .blue
        case .updated: .green
        case .unavailable: .orange
        }
    }
}
#endif
