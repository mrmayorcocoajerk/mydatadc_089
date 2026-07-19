public actor ModuleRegistry {
    private var modules: [MyDataDCModuleID: MyDataDCModule]

    public init(modules: [MyDataDCModule] = ModuleRegistry.defaults) {
        self.modules = Dictionary(uniqueKeysWithValues: modules.map { ($0.id, $0) })
    }

    public func allModules() -> [MyDataDCModule] {
        MyDataDCModuleID.allCases.compactMap { modules[$0] }
    }

    public func module(for id: MyDataDCModuleID) -> MyDataDCModule? {
        modules[id]
    }

    public func setEnabled(_ enabled: Bool, for id: MyDataDCModuleID) throws {
        guard var module = modules[id] else {
            throw RegistryError.moduleNotFound(id)
        }
        module.isEnabled = enabled
        modules[id] = module
    }

    public enum RegistryError: Error, Equatable {
        case moduleNotFound(MyDataDCModuleID)
    }

    public static let defaults: [MyDataDCModule] = [
        .init(id: .manor, displayName: "The Manor", subtitle: "Your central command space", systemImage: "building.columns.fill"),
        .init(id: .ongakuStudio, displayName: "ongaku(studio)", subtitle: "Music creation and mastering", systemImage: "waveform.badge.mic"),
        .init(id: .chosenMeiga, displayName: "chō(sen)mei(ga)", subtitle: "Video editing and production", systemImage: "film.stack.fill"),
        .init(id: .shashinTeki, displayName: "shashin(teki)", subtitle: "AI photo editing studio", systemImage: "camera.filters"),
        .init(id: .careerHQ, displayName: "Career HQ", subtitle: "Applications, opportunities, and growth", systemImage: "briefcase.fill"),
        .init(id: .moneyHQ, displayName: "Money HQ", subtitle: "Financial command center", systemImage: "chart.pie.fill"),
        .init(id: .vitalsStudio, displayName: "Vitals Studio", subtitle: "Health, activity, and wellbeing", systemImage: "heart.text.square.fill"),
        .init(id: .timeStudio, displayName: "Time Studio", subtitle: "Timers, stopwatch, and focused sessions", systemImage: "timer"),
        .init(id: .newsDesk, displayName: "NewsDesk", subtitle: "Every headline. Different perspectives. One desk.", systemImage: "newspaper.fill"),
        .init(id: .parcelDeliveryDropZone, displayName: "Parcel Delivery Drop Zone", subtitle: "Track deliveries and logistics", systemImage: "shippingbox.fill"),
        .init(id: .electronicMailDigitalDoormat, displayName: "Electronic Mail Digital Doormat", subtitle: "Unified mail and message entry", systemImage: "envelope.badge.fill"),
        .init(id: .chrysanthemum, displayName: "Chrysanthemum", subtitle: "System convergence and orchestration", systemImage: "sparkles.rectangle.stack.fill")
    ]
}
