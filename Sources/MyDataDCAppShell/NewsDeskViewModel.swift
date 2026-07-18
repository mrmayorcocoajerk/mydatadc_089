#if canImport(SwiftUI)
import Foundation
import SwiftUI
import NetSphereCore

@MainActor
public final class NewsDeskViewModel: ObservableObject {
    @Published public var query: String
    @Published public private(set) var snapshot: NetSphereSnapshot
    @Published public private(set) var isRefreshing = false
    @Published public private(set) var statusMessage: String?
    @Published public private(set) var errorMessage: String?

    private let store: NetSphereStore
    private let feedLoader: any NewsFeedLoading
    private let endpoints: [NewsFeedEndpoint]
    private let persistenceURL: URL?

    public init(
        store: NetSphereStore = NetSphereStore(),
        query: String = "",
        feedLoader: any NewsFeedLoading = RSSNewsFeedClient(),
        endpoints: [NewsFeedEndpoint] = NewsFeedEndpoint.newsDeskDefaults,
        persistenceURL: URL? = NewsDeskViewModel.defaultPersistenceURL
    ) {
        self.store = store
        self.query = query
        self.feedLoader = feedLoader
        self.endpoints = endpoints
        self.persistenceURL = persistenceURL
        self.snapshot = NetSphereSnapshot()
    }

    public var displayedArticles: [NewsArticle] {
        NetSphereEngine.ranked(
            snapshot.articles,
            subscriptions: snapshot.subscriptions
        )
        .filter { NetSphereEngine.matches($0, query: query) }
    }

    public var briefing: DailyBriefing? {
        snapshot.lastBriefing
    }

    public func load() async {
        if let persistenceURL, FileManager.default.fileExists(atPath: persistenceURL.path) {
            do {
                try await store.load(from: persistenceURL)
            } catch {
                errorMessage = "Saved briefing could not be loaded: \(error.localizedDescription)"
            }
        }
        snapshot = await store.currentSnapshot()
    }

    public func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        statusMessage = nil
        errorMessage = nil
        defer { isRefreshing = false }

        var fetched: [NewsArticle] = []
        var failures: [String] = []
        for endpoint in endpoints {
            do {
                fetched += try await feedLoader.fetch(endpoint)
            } catch {
                failures.append(endpoint.name)
            }
        }

        guard !fetched.isEmpty else {
            errorMessage = failures.isEmpty
                ? "No headlines were returned."
                : "Could not refresh: \(failures.joined(separator: ", "))."
            return
        }

        await store.ingest(fetched)
        await store.generateBriefing()
        await persist()
        snapshot = await store.currentSnapshot()
        statusMessage = failures.isEmpty
            ? "Updated \(fetched.count) headlines."
            : "Updated \(fetched.count) headlines; unavailable: \(failures.joined(separator: ", "))."
    }

    public func clearSearch() {
        query = ""
    }

    public func isSaved(_ article: NewsArticle) -> Bool {
        snapshot.savedArticleIDs.contains(article.id)
    }

    public func toggleSaved(_ article: NewsArticle) async {
        await store.toggleSaved(articleID: article.id)
        await persist()
        snapshot = await store.currentSnapshot()
    }

    private func persist() async {
        guard let persistenceURL else { return }
        do {
            try await store.save(to: persistenceURL)
        } catch {
            errorMessage = "Briefing could not be saved: \(error.localizedDescription)"
        }
    }

    public static var defaultPersistenceURL: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("MyDataDC", isDirectory: true)
            .appendingPathComponent("NewsDesk.json")
    }
}
#endif
