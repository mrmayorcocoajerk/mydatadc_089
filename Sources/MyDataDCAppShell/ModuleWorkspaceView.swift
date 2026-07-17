#if canImport(SwiftUI)
import SwiftUI
import MyDataDCCore

public struct ModuleWorkspaceView: View {
    private let module: MyDataDCModule
    private let onReturnToManor: () -> Void

    public init(module: MyDataDCModule, onReturnToManor: @escaping () -> Void) {
        self.module = module
        self.onReturnToManor = onReturnToManor
    }

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            LivingGradient().opacity(0.18).blur(radius: 50).ignoresSafeArea()

            FrostedPanel {
                VStack(spacing: MyDataDCSpacing.large) {
                    Image(systemName: module.systemImage)
                        .font(.system(size: 52, weight: .semibold))
                    Text(module.displayName)
                        .font(.largeTitle.bold())
                    Text(module.subtitle)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Text("Workspace foundation connected. Functional tools arrive in the next module sprint.")
                        .font(.body)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                    Button(action: onReturnToManor) {
                        Label("Back to The Manor", systemImage: "building.columns")
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.cancelAction)
                }
                .frame(maxWidth: 640)
            }
            .padding(MyDataDCSpacing.xLarge)
        }
        .navigationTitle(module.displayName)
    }
}
#endif
