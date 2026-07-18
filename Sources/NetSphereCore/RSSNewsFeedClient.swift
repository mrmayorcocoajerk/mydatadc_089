import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
#if canImport(FoundationXML)
import FoundationXML
#endif

public struct NewsFeedEndpoint: Hashable, Sendable {
    public var name: String
    public var url: URL
    public var scope: NewsScope
    public var reliabilityScore: Double

    public init(
        name: String,
        url: URL,
        scope: NewsScope,
        reliabilityScore: Double = 0.8
    ) {
        self.name = name
        self.url = url
        self.scope = scope
        self.reliabilityScore = min(1, max(0, reliabilityScore))
    }

    public static let newsDeskDefaults: [NewsFeedEndpoint] = [
        NewsFeedEndpoint(
            name: "BBC World",
            url: URL(string: "https://feeds.bbci.co.uk/news/world/rss.xml")!,
            scope: .world
        ),
        NewsFeedEndpoint(
            name: "NPR World",
            url: URL(string: "https://feeds.npr.org/1004/rss.xml")!,
            scope: .world
        )
    ]
}

public protocol NewsFeedLoading: Sendable {
    func fetch(_ endpoint: NewsFeedEndpoint) async throws -> [NewsArticle]
}

public enum NewsFeedError: Error, Equatable, LocalizedError {
    case invalidResponse
    case httpStatus(Int)
    case malformedFeed

    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "The news source returned an invalid response."
        case .httpStatus(let status):
            "The news source returned HTTP status \(status)."
        case .malformedFeed:
            "The news source returned an unreadable RSS feed."
        }
    }
}

public struct RSSNewsFeedClient: NewsFeedLoading {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func fetch(_ endpoint: NewsFeedEndpoint) async throws -> [NewsArticle] {
        var request = URLRequest(url: endpoint.url)
        request.timeoutInterval = 20
        request.setValue("MyDataDC NewsDesk/1.0", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse else {
            throw NewsFeedError.invalidResponse
        }
        guard (200..<300).contains(response.statusCode) else {
            throw NewsFeedError.httpStatus(response.statusCode)
        }
        return try RSSFeedParser.parse(data, endpoint: endpoint)
    }
}

public enum RSSFeedParser {
    public static func parse(_ data: Data, endpoint: NewsFeedEndpoint) throws -> [NewsArticle] {
        let delegate = RSSParserDelegate(endpoint: endpoint)
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        guard parser.parse() else { throw NewsFeedError.malformedFeed }
        return delegate.articles
    }
}

private final class RSSParserDelegate: NSObject, XMLParserDelegate {
    private struct Item {
        var title = ""
        var summary = ""
        var link = ""
        var published = ""
        var categories: Set<String> = []
    }

    private let endpoint: NewsFeedEndpoint
    private var item: Item?
    private var currentElement = ""
    private var content = ""
    private(set) var articles: [NewsArticle] = []

    init(endpoint: NewsFeedEndpoint) {
        self.endpoint = endpoint
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        currentElement = elementName.lowercased()
        content = ""
        if currentElement == "item" { item = Item() }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard item != nil else { return }
        content += string
    }

    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        guard item != nil, let value = String(data: CDATABlock, encoding: .utf8) else { return }
        content += value
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        let element = elementName.lowercased()
        let value = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if element == "item" {
            appendCurrentItem()
            item = nil
        } else if item != nil {
            switch element {
            case "title": item?.title += value
            case "description", "summary": item?.summary += value
            case "link": item?.link += value
            case "pubdate", "dc:date", "published", "updated": item?.published += value
            case "category":
                let topic = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                if !topic.isEmpty { item?.categories.insert(topic) }
            default: break
            }
        }
        currentElement = ""
        content = ""
    }

    private func appendCurrentItem() {
        guard let item else { return }
        let headline = Self.plainText(item.title)
        guard !headline.isEmpty else { return }
        let source = NewsSource(
            name: endpoint.name,
            domain: endpoint.url.host ?? endpoint.url.absoluteString,
            reliabilityScore: endpoint.reliabilityScore
        )
        articles.append(NewsArticle(
            headline: headline,
            summary: Self.plainText(item.summary).nonEmpty ?? headline,
            scope: endpoint.scope,
            source: source,
            publishedAt: Self.date(from: item.published) ?? Date(),
            canonicalURL: URL(string: item.link),
            topics: item.categories
        ))
    }

    private static func plainText(_ value: String) -> String {
        value
            .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func date(from value: String) -> Date? {
        guard !value.isEmpty else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        for format in [
            "E, d MMM yyyy HH:mm:ss Z",
            "E, dd MMM yyyy HH:mm:ss Z",
            "E, d MMM yyyy HH:mm Z",
            "E, dd MMM yyyy HH:mm Z"
        ] {
            formatter.dateFormat = format
            if let date = formatter.date(from: value) { return date }
        }
        return ISO8601DateFormatter().date(from: value)
    }
}

private extension String {
    var nonEmpty: String? { isEmpty ? nil : self }
}
