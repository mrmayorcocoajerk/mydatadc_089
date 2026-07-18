#if canImport(SwiftUI)
import SwiftUI
import MyDataDCCore
import CareerHQUI

public struct MyDataDCRootView: View {
    @StateObject private var state: MyDataDCAppState

    public init(state: MyDataDCAppState = MyDataDCAppState()) {
        _state = StateObject(wrappedValue: state)
    }

    public var body: some View {
        NavigationSplitView {
            List(selection: Binding(
                get: { state.selectedModuleID },
                set: { state.select($0) }
            )) {
                ForEach(state.modules.filter(\.isEnabled)) { module in
                    Label(module.displayName, systemImage: module.systemImage)
                        .tag(module.id)
                }
            }
            .navigationTitle("MyDataDC")
            .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 320)
        } detail: {
            if state.selectedModuleID == .manor {
                ManorDashboardView(state: state)
            } else if state.selectedModuleID == .careerHQ {
                CareerHQView()
            } else if state.selectedModuleID == .newsDesk {
                NewsDeskView {
                    state.returnToManor()
                }
            } else if let module = state.selectedModule {
                ModuleWorkspaceView(module: module) {
                    state.returnToManor()
                }
            } else {
                ContentUnavailableView("Module unavailable", systemImage: "exclamationmark.triangle")
            }
        }
    }
}
#endif
