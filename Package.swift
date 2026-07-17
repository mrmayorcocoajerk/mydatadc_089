// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MyDataDC",
    platforms: [.macOS(.v15), .iOS(.v18)],
    products: [
        .executable(name: "MyDataDC", targets: ["MyDataDC"]),
        .library(name: "MyDataDCCore", targets: ["MyDataDCCore"]),
        .library(name: "CareerHQCore", targets: ["CareerHQCore"]),
        .library(name: "CareerHQUI", targets: ["CareerHQUI"]),
        .library(name: "MyDataDCAppShell", targets: ["MyDataDCAppShell"]),
        .library(name: "LivingEnvironmentCore", targets: ["LivingEnvironmentCore"]),
        .library(name: "GalleryCore", targets: ["GalleryCore"]),
        .library(name: "LivingPanelsCore", targets: ["LivingPanelsCore"]),
        .library(name: "SceneCore", targets: ["SceneCore"]),
        .library(name: "ChrysanthemumCore", targets: ["ChrysanthemumCore"]),
        .library(name: "ConnectionsCore", targets: ["ConnectionsCore"]),
        .library(name: "CommerceCore", targets: ["CommerceCore"]),
        .library(name: "ReadingCore", targets: ["ReadingCore"]),
        .library(name: "DigiSphereCore", targets: ["DigiSphereCore"]),
        .library(name: "NetSphereCore", targets: ["NetSphereCore"])
    ],
    targets: [
        .executableTarget(name: "MyDataDC", dependencies: ["MyDataDCAppShell"]),
        .target(name: "MyDataDCCore"),
        .target(name: "CareerHQCore"),
        .target(name: "CareerHQUI", dependencies: ["CareerHQCore"]),
        .target(name: "MyDataDCAppShell", dependencies: ["MyDataDCCore", "CareerHQCore", "CareerHQUI"]),
        .target(name: "LivingEnvironmentCore"),
        .target(name: "GalleryCore"),
        .target(name: "LivingPanelsCore", dependencies: ["GalleryCore", "LivingEnvironmentCore"]),
        .target(name: "SceneCore", dependencies: ["GalleryCore"]),
        .target(name: "ChrysanthemumCore"),
        .target(name: "ConnectionsCore"),
        .target(name: "CommerceCore"),
        .target(name: "ReadingCore"),
        .target(name: "DigiSphereCore"),
        .target(name: "NetSphereCore"),
        .testTarget(name: "MyDataDCCoreTests", dependencies: ["MyDataDCCore"]),
        .testTarget(name: "CareerHQCoreTests", dependencies: ["CareerHQCore"]),
        .testTarget(name: "MyDataDCAppShellTests", dependencies: ["MyDataDCAppShell", "MyDataDCCore"]),
        .testTarget(name: "LivingEnvironmentCoreTests", dependencies: ["LivingEnvironmentCore"]),
        .testTarget(name: "GalleryCoreTests", dependencies: ["GalleryCore"]),
        .testTarget(name: "LivingPanelsCoreTests", dependencies: ["LivingPanelsCore", "GalleryCore", "LivingEnvironmentCore"]),
        .testTarget(name: "SceneCoreTests", dependencies: ["SceneCore"]),
        .testTarget(name: "ChrysanthemumCoreTests", dependencies: ["ChrysanthemumCore"]),
        .testTarget(name: "ConnectionsCoreTests", dependencies: ["ConnectionsCore"]),
        .testTarget(name: "CommerceCoreTests", dependencies: ["CommerceCore"]),
        .testTarget(name: "ReadingCoreTests", dependencies: ["ReadingCore"]),
        .testTarget(name: "DigiSphereCoreTests", dependencies: ["DigiSphereCore"]),
        .testTarget(name: "NetSphereCoreTests", dependencies: ["NetSphereCore"])
    ]
)
