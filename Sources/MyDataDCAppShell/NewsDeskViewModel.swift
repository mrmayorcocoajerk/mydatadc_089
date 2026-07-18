#if canImport(SwiftUI)
import Foundation
import SwiftUI
import NetSphereCore

@MainActor
public final class NewsDeskViewModel: ObservableObject {
    @Published public var query: String
    @Published public private(set) var snapshot: NetSphereSnapshot

    private let store: NetSphereStore

    public init(
        store: NetSphereStore = NetSphereStore(),
        query: String = ""
    ) {
        self.store = store
        self.query = query
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
        snapshot = await store.currentSnapshot()
    }

    public func clearSearch() {
        query = ""
    }

    public func isSaved(_ article: NewsArticle) -> Bool {
        snapshot.savedArticleIDs.contains(article.id)
    }

    public func toggleSaved(_ article: NewsArticle) async {
        await store.toggleSaved(articleID: article.id)
        await load()
    }
}
#endif
