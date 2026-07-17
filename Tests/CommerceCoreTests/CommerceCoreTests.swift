import Foundation
import Testing
@testable import CommerceCore

@Test func supportedRetailersIncludeLocalHaunts() {
    #expect(Retailer.allCases.contains(.amazon))
    #expect(Retailer.allCases.contains(.ebay))
    #expect(Retailer.allCases.contains(.etsy))
    #expect(Retailer.allCases.contains(.target))
    #expect(Retailer.allCases.contains(.walmart))
    #expect(Retailer.allCases.contains(.kroger))
    #expect(Retailer.allCases.contains(.petsmart))
}

@Test func orderTotalsAreCalculated() {
    let order = CommerceOrder(
        retailer: .target,
        orderNumber: "T-1",
        items: [
            CommerceItem(name: "Coffee", quantity: 2, unitPrice: Decimal(string: "7.50")!),
            CommerceItem(name: "Mug", unitPrice: Decimal(string: "12.00")!)
        ],
        tax: Decimal(string: "2.16")!,
        shipping: 0
    )
    #expect(order.subtotal == Decimal(string: "27.00")!)
    #expect(order.total == Decimal(string: "29.16")!)
}

@Test func duplicateOrdersAreRejectedPerRetailer() async throws {
    let first = CommerceOrder(retailer: .amazon, orderNumber: "ABC", items: [])
    let second = CommerceOrder(retailer: .amazon, orderNumber: "abc", items: [])
    let coordinator = CommerceCoordinator()
    try await coordinator.addOrder(first)
    await #expect(throws: CommerceError.duplicateOrderNumber("abc")) {
        try await coordinator.addOrder(second)
    }
}

@Test func sameOrderNumberAtDifferentRetailersIsAllowed() async throws {
    let coordinator = CommerceCoordinator()
    try await coordinator.addOrder(.init(retailer: .amazon, orderNumber: "123", items: []))
    try await coordinator.addOrder(.init(retailer: .ebay, orderNumber: "123", items: []))
    #expect(await coordinator.orderList().count == 2)
}

@Test func deliveriesAreFilteredByDay() async throws {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    let target = Date(timeIntervalSince1970: 1_700_000_000)
    let shipment = Shipment(
        carrier: .veho,
        trackingNumber: "V1",
        status: .outForDelivery,
        estimatedDelivery: target.addingTimeInterval(3_600)
    )
    let order = CommerceOrder(retailer: .walmart, orderNumber: "W1", items: [], shipments: [shipment])
    let coordinator = CommerceCoordinator()
    try await coordinator.addOrder(order)
    #expect(await coordinator.deliveriesDue(on: target, calendar: calendar).map(\.id) == [shipment.id])
}

@Test func targetPriceTriggersPriceDrop() async {
    let item = WishlistItem(
        name: "OLED TV",
        retailer: .bestBuy,
        currentPrice: 1_399,
        targetPrice: 1_500
    )
    let coordinator = CommerceCoordinator()
    await coordinator.addWishlistItem(item)
    #expect(await coordinator.priceDrops().map(\.id) == [item.id])
}

@Test func petsmartSupplyReorderIsSurfaced() async throws {
    let pet = PetProfile(name: "Luna", species: "Dog")
    let supply = PetSupply(
        petID: pet.id,
        name: "Purina Pro Plan",
        retailer: .petsmart,
        daysRemaining: 5,
        reorderThresholdDays: 7
    )
    let coordinator = CommerceCoordinator()
    await coordinator.addPet(pet)
    try await coordinator.addPetSupply(supply)
    #expect(await coordinator.petReorders().map(\.id) == [supply.id])
}

@Test func receiptRequiresKnownOrder() async {
    let receipt = Receipt(orderID: UUID(), retailer: .etsy, total: 20)
    let coordinator = CommerceCoordinator()
    await #expect(throws: CommerceError.unknownOrder(receipt.orderID)) {
        try await coordinator.addReceipt(receipt)
    }
}

@Test func dashboardSummaryReflectsCommerceState() async throws {
    let pet = PetProfile(name: "Luna", species: "Dog")
    let coordinator = CommerceCoordinator()
    await coordinator.addPet(pet)
    try await coordinator.addPetSupply(.init(petID: pet.id, name: "Treats", daysRemaining: 2))
    try await coordinator.addOrder(.init(retailer: .kroger, orderNumber: "K1", status: .processing, items: []))
    try await coordinator.addOrder(.init(retailer: .target, orderNumber: "T1", status: .delivered, items: []))
    await coordinator.addWishlistItem(.init(name: "Lamp", retailer: .etsy, currentPrice: 80, targetPrice: 100))
    let summary = await coordinator.dashboardSummary()
    #expect(summary.activeOrders == 1)
    #expect(summary.deliveredOrders == 1)
    #expect(summary.trackedWishItems == 1)
    #expect(summary.priceDrops == 1)
    #expect(summary.petReorders == 1)
}

@Test func persistenceRoundTrip() async throws {
    let date = Date(timeIntervalSince1970: 1_234.567)
    let order = CommerceOrder(
        retailer: .petsmart,
        orderNumber: "PS-1",
        placedAt: date,
        items: [CommerceItem(name: "Toy", unitPrice: 9.99)]
    )
    let snapshot = CommerceSnapshot(orders: [order])
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathComponent("commerce.json")
    let store = CommerceStore(url: url)
    try await store.save(snapshot)
    #expect(try await store.load() == snapshot)
}
