import Foundation
import Testing
@testable import MyDataDCCore

@Test func defaultRegistryContainsEveryOfficialModule() async {
    let modules = await ModuleRegistry().allModules()
    #expect(modules.count == MyDataDCModuleID.allCases.count)
    #expect(modules.first?.displayName == "The Manor")
    #expect(modules.contains { $0.displayName == "chō(sen)mei(ga)" })
    #expect(modules.contains { $0.displayName == "Electronic Mail Digital Doormat" })
    #expect(modules.contains { $0.displayName == "Chrysanthemum" })
}

@Test func registryCanDisableAndReenableModule() async throws {
    let registry = ModuleRegistry()
    try await registry.setEnabled(false, for: .newsDesk)
    #expect(await registry.module(for: .newsDesk)?.isEnabled == false)
    try await registry.setEnabled(true, for: .newsDesk)
    #expect(await registry.module(for: .newsDesk)?.isEnabled == true)
}

@Test func macAndIPadAreEqualFlagshipPlatforms() {
    let policy = PlatformCapabilityPolicy()
    #expect(policy.hasFullFeatureParity(.macOS))
    #expect(policy.hasFullFeatureParity(.iPadOS))
    #expect(!policy.hasFullFeatureParity(.iOS))
    #expect(!policy.hasFullFeatureParity(.watchOS))
}


@Test func aetherObjectStoreMaintainsWorkspaceAndKindIndexes() async {
    let firstWorkspace = AETHERWorkspaceID()
    let secondWorkspace = AETHERWorkspaceID()
    let objectID = AETHERObjectID()
    let store = AETHERObjectStore()

    await store.upsert(.init(id: objectID, workspaceID: firstWorkspace, kind: "career.application"))
    #expect(await store.objects(in: firstWorkspace).map(\.id) == [objectID])
    #expect(await store.objects(ofKind: "career.application").map(\.id) == [objectID])

    await store.upsert(.init(id: objectID, workspaceID: secondWorkspace, kind: "career.interview"))
    #expect(await store.objects(in: firstWorkspace).isEmpty)
    #expect(await store.objects(ofKind: "career.application").isEmpty)
    #expect(await store.objects(in: secondWorkspace).map(\.id) == [objectID])
    #expect(await store.objects(ofKind: "career.interview").map(\.id) == [objectID])
}

@Test func aetherObjectStoreRemovalCleansEveryIndex() async {
    let workspace = AETHERWorkspaceID()
    let object = AETHERObject(workspaceID: workspace, kind: "core.note")
    let store = AETHERObjectStore(objects: [object])

    #expect(await store.remove(id: object.id) == object)
    #expect(await store.object(id: object.id) == nil)
    #expect(await store.objects(in: workspace).isEmpty)
    #expect(await store.objects(ofKind: "core.note").isEmpty)
    #expect(await store.count() == 0)
}

@Test func workspaceRegistryTracksOpenAndActiveWorkspaces() async throws {
    let career = AETHERWorkspace(name: "Career Studio", moduleID: .careerHQ)
    let manor = AETHERWorkspace(name: "The Manor", moduleID: .manor)
    let registry = AETHERWorkspaceRegistry(workspaces: [career, manor])

    try await registry.open(manor.id, at: Date(timeIntervalSince1970: 10))
    try await registry.open(career.id, at: Date(timeIntervalSince1970: 20))

    #expect(await registry.activeWorkspace()?.id == career.id)
    #expect(await registry.openWorkspaces().map(\.id) == [career.id, manor.id])

    try await registry.close(career.id)
    #expect(await registry.activeWorkspace()?.id == manor.id)
}

@Test func workspaceRegistryRejectsUnknownWorkspace() async {
    let registry = AETHERWorkspaceRegistry()
    let missingID = AETHERWorkspaceID()

    await #expect(throws: AETHERWorkspaceRegistry.RegistryError.workspaceNotFound(missingID)) {
        try await registry.open(missingID)
    }
}

@Test func buildInfoUsesOfficialBrandingHierarchy() {
    #expect(MyDataDCBuildInfo.publicProductName == "MyDataDC")
    #expect(MyDataDCBuildInfo.tagline == "the operating system for your DIGITAL LIFE")
    #expect(MyDataDCBuildInfo.runtimeName == "dcoreOS")
    #expect(MyDataDCBuildInfo.engineeringCodename == "DARTH COREYPHAEUS")
    #expect(MyDataDCBuildInfo.version == "0.8.9-alpha")
}
