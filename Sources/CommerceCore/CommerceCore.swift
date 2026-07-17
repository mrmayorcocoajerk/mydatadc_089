import Foundation

public enum Retailer: String, Codable, CaseIterable, Sendable {
    case amazon, ebay, etsy, target, walmart, kroger, petsmart, costco, bestBuy
}

public enum OrderStatus: String, Codable, CaseIterable, Sendable {
    case placed, processing, shipped, outForDelivery, delivered, returned, cancelled
}

public enum ShipmentCarrier: String, Codable, CaseIterable, Sendable {
    case ups, usps, fedEx, dhl, amazonLogistics, veho, royalMail, postNord, unknown
}

public struct CommerceItem: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var name: String
    public var quantity: Int
    public var unitPrice: Decimal
    public var category: String

    public init(
        id: UUID = UUID(),
        name: String,
        quantity: Int = 1,
        unitPrice: Decimal,
        category: String = "Uncategorized"
    ) {
        self.id = id
        self.name = name
        self.quantity = max(1, quantity)
        self.unitPrice = unitPrice
        self.category = category
    }

    public var lineTotal: Decimal { unitPrice * Decimal(quantity) }
}

public struct Shipment: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var carrier: ShipmentCarrier
    public var trackingNumber: String
    public var status: OrderStatus
    public var estimatedDelivery: Date?
    public var lastUpdated: Date

    public init(
        id: UUID = UUID(),
        carrier: ShipmentCarrier,
        trackingNumber: String,
        status: OrderStatus,
        estimatedDelivery: Date? = nil,
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.carrier = carrier
        self.trackingNumber = trackingNumber
        self.status = status
        self.estimatedDelivery = estimatedDelivery
        self.lastUpdated = lastUpdated
    }
}

public struct CommerceOrder: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var retailer: Retailer
    public var orderNumber: String
    public var placedAt: Date
    public var status: OrderStatus
    public var items: [CommerceItem]
    public var shipments: [Shipment]
    public var tax: Decimal
    public var shipping: Decimal

    public init(
        id: UUID = UUID(),
        retailer: Retailer,
        orderNumber: String,
        placedAt: Date = Date(),
        status: OrderStatus = .placed,
        items: [CommerceItem],
        shipments: [Shipment] = [],
        tax: Decimal = 0,
        shipping: Decimal = 0
    ) {
        self.id = id
        self.retailer = retailer
        self.orderNumber = orderNumber
        self.placedAt = placedAt
        self.status = status
        self.items = items
        self.shipments = shipments
        self.tax = tax
        self.shipping = shipping
    }

    public var subtotal: Decimal { items.reduce(0) { $0 + $1.lineTotal } }
    public var total: Decimal { subtotal + tax + shipping }
}

public struct Receipt: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var orderID: UUID
    public var retailer: Retailer
    public var issuedAt: Date
    public var total: Decimal
    public var documentReference: String?

    public init(
        id: UUID = UUID(),
        orderID: UUID,
        retailer: Retailer,
        issuedAt: Date = Date(),
        total: Decimal,
        documentReference: String? = nil
    ) {
        self.id = id
        self.orderID = orderID
        self.retailer = retailer
        self.issuedAt = issuedAt
        self.total = total
        self.documentReference = documentReference
    }
}

public struct WishlistItem: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var name: String
    public var retailer: Retailer
    public var currentPrice: Decimal
    public var targetPrice: Decimal?
    public var productURL: String?
    public var lastChecked: Date

    public init(
        id: UUID = UUID(),
        name: String,
        retailer: Retailer,
        currentPrice: Decimal,
        targetPrice: Decimal? = nil,
        productURL: String? = nil,
        lastChecked: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.retailer = retailer
        self.currentPrice = currentPrice
        self.targetPrice = targetPrice
        self.productURL = productURL
        self.lastChecked = lastChecked
    }

    public var reachedTarget: Bool {
        guard let targetPrice else { return false }
        return currentPrice <= targetPrice
    }
}

public struct PetProfile: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var name: String
    public var species: String
    public var birthday: Date?
    public var veterinarian: String?
    public var medicationNotes: String

    public init(
        id: UUID = UUID(),
        name: String,
        species: String,
        birthday: Date? = nil,
        veterinarian: String? = nil,
        medicationNotes: String = ""
    ) {
        self.id = id
        self.name = name
        self.species = species
        self.birthday = birthday
        self.veterinarian = veterinarian
        self.medicationNotes = medicationNotes
    }
}

public struct PetSupply: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var petID: UUID
    public var name: String
    public var retailer: Retailer
    public var daysRemaining: Int
    public var reorderThresholdDays: Int

    public init(
        id: UUID = UUID(),
        petID: UUID,
        name: String,
        retailer: Retailer = .petsmart,
        daysRemaining: Int,
        reorderThresholdDays: Int = 7
    ) {
        self.id = id
        self.petID = petID
        self.name = name
        self.retailer = retailer
        self.daysRemaining = max(0, daysRemaining)
        self.reorderThresholdDays = max(0, reorderThresholdDays)
    }

    public var needsReorder: Bool { daysRemaining <= reorderThresholdDays }
}

public struct CommerceSnapshot: Codable, Equatable, Sendable {
    public var orders: [CommerceOrder]
    public var receipts: [Receipt]
    public var wishlist: [WishlistItem]
    public var pets: [PetProfile]
    public var petSupplies: [PetSupply]

    public init(
        orders: [CommerceOrder] = [],
        receipts: [Receipt] = [],
        wishlist: [WishlistItem] = [],
        pets: [PetProfile] = [],
        petSupplies: [PetSupply] = []
    ) {
        self.orders = orders
        self.receipts = receipts
        self.wishlist = wishlist
        self.pets = pets
        self.petSupplies = petSupplies
    }
}

public enum CommerceError: Error, Equatable, Sendable {
    case duplicateOrderNumber(String)
    case unknownOrder(UUID)
    case unknownPet(UUID)
    case unknownWishlistItem(UUID)
}

public actor CommerceCoordinator {
    private var orders: [UUID: CommerceOrder]
    private var receipts: [UUID: Receipt]
    private var wishlist: [UUID: WishlistItem]
    private var pets: [UUID: PetProfile]
    private var petSupplies: [UUID: PetSupply]

    public init(snapshot: CommerceSnapshot = .init()) {
        self.orders = .init(uniqueKeysWithValues: snapshot.orders.map { ($0.id, $0) })
        self.receipts = .init(uniqueKeysWithValues: snapshot.receipts.map { ($0.id, $0) })
        self.wishlist = .init(uniqueKeysWithValues: snapshot.wishlist.map { ($0.id, $0) })
        self.pets = .init(uniqueKeysWithValues: snapshot.pets.map { ($0.id, $0) })
        self.petSupplies = .init(uniqueKeysWithValues: snapshot.petSupplies.map { ($0.id, $0) })
    }

    public func addOrder(_ order: CommerceOrder) throws {
        if orders.values.contains(where: {
            $0.retailer == order.retailer &&
            $0.orderNumber.caseInsensitiveCompare(order.orderNumber) == .orderedSame
        }) {
            throw CommerceError.duplicateOrderNumber(order.orderNumber)
        }
        orders[order.id] = order
    }

    public func updateOrderStatus(_ status: OrderStatus, orderID: UUID) throws {
        guard var order = orders[orderID] else { throw CommerceError.unknownOrder(orderID) }
        order.status = status
        orders[orderID] = order
    }

    public func orderList(status: OrderStatus? = nil, retailer: Retailer? = nil) -> [CommerceOrder] {
        orders.values
            .filter { status == nil || $0.status == status }
            .filter { retailer == nil || $0.retailer == retailer }
            .sorted { lhs, rhs in
                if lhs.placedAt == rhs.placedAt { return lhs.orderNumber < rhs.orderNumber }
                return lhs.placedAt > rhs.placedAt
            }
    }

    public func deliveriesDue(on date: Date, calendar: Calendar = .current) -> [Shipment] {
        orders.values
            .flatMap(\.shipments)
            .filter { shipment in
                guard let estimate = shipment.estimatedDelivery else { return false }
                return calendar.isDate(estimate, inSameDayAs: date)
            }
            .sorted { ($0.estimatedDelivery ?? .distantFuture) < ($1.estimatedDelivery ?? .distantFuture) }
    }

    public func addReceipt(_ receipt: Receipt) throws {
        guard orders[receipt.orderID] != nil else { throw CommerceError.unknownOrder(receipt.orderID) }
        receipts[receipt.id] = receipt
    }

    public func addWishlistItem(_ item: WishlistItem) {
        wishlist[item.id] = item
    }

    public func updateWishlistPrice(itemID: UUID, price: Decimal, checkedAt: Date = Date()) throws {
        guard var item = wishlist[itemID] else { throw CommerceError.unknownWishlistItem(itemID) }
        item.currentPrice = price
        item.lastChecked = checkedAt
        wishlist[itemID] = item
    }

    public func priceDrops() -> [WishlistItem] {
        wishlist.values
            .filter(\.reachedTarget)
            .sorted { lhs, rhs in
                let lhsTarget = lhs.targetPrice ?? lhs.currentPrice
                let rhsTarget = rhs.targetPrice ?? rhs.currentPrice
                let lhsSavings = lhsTarget - lhs.currentPrice
                let rhsSavings = rhsTarget - rhs.currentPrice
                if lhsSavings == rhsSavings { return lhs.name < rhs.name }
                return lhsSavings > rhsSavings
            }
    }

    public func addPet(_ pet: PetProfile) {
        pets[pet.id] = pet
    }

    public func addPetSupply(_ supply: PetSupply) throws {
        guard pets[supply.petID] != nil else { throw CommerceError.unknownPet(supply.petID) }
        petSupplies[supply.id] = supply
    }

    public func petReorders() -> [PetSupply] {
        petSupplies.values
            .filter(\.needsReorder)
            .sorted {
                if $0.daysRemaining == $1.daysRemaining { return $0.name < $1.name }
                return $0.daysRemaining < $1.daysRemaining
            }
    }

    public func dashboardSummary() -> CommerceDashboardSummary {
        let activeOrders = orders.values.filter { ![.delivered, .returned, .cancelled].contains($0.status) }.count
        let delivered = orders.values.filter { $0.status == .delivered }.count
        return CommerceDashboardSummary(
            activeOrders: activeOrders,
            deliveredOrders: delivered,
            trackedWishItems: wishlist.count,
            priceDrops: priceDrops().count,
            petReorders: petReorders().count
        )
    }

    public func snapshot() -> CommerceSnapshot {
        .init(
            orders: Array(orders.values),
            receipts: Array(receipts.values),
            wishlist: Array(wishlist.values),
            pets: Array(pets.values),
            petSupplies: Array(petSupplies.values)
        )
    }
}

public struct CommerceDashboardSummary: Equatable, Sendable {
    public var activeOrders: Int
    public var deliveredOrders: Int
    public var trackedWishItems: Int
    public var priceDrops: Int
    public var petReorders: Int

    public init(
        activeOrders: Int,
        deliveredOrders: Int,
        trackedWishItems: Int,
        priceDrops: Int,
        petReorders: Int
    ) {
        self.activeOrders = activeOrders
        self.deliveredOrders = deliveredOrders
        self.trackedWishItems = trackedWishItems
        self.priceDrops = priceDrops
        self.petReorders = petReorders
    }
}

public actor CommerceStore {
    private let url: URL

    public init(url: URL) {
        self.url = url
    }

    public func save(_ snapshot: CommerceSnapshot) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        encoder.outputFormatting = [.sortedKeys]
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try encoder.encode(snapshot).write(to: url, options: .atomic)
    }

    public func load() throws -> CommerceSnapshot {
        guard FileManager.default.fileExists(atPath: url.path) else { return .init() }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        return try decoder.decode(CommerceSnapshot.self, from: Data(contentsOf: url))
    }
}
