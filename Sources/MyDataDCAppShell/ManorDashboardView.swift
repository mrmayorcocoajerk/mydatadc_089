#if canImport(SwiftUI)
import SwiftUI
import MyDataDCCore

public struct ManorDashboardView: View {
    @ObservedObject private var state: MyDataDCAppState

    public init(state: MyDataDCAppState) {
        self.state = state
    }

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 220, maximum: 360), spacing: MyDataDCSpacing.medium)]
    }

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            LivingGradient()
                .opacity(0.28)
                .blur(radius: 40)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: MyDataDCSpacing.xLarge) {
                    header
                    LazyVGrid(columns: columns, spacing: MyDataDCSpacing.medium) {
                        ForEach(state.visibleModules.filter { $0.id != .manor }) { module in
                            ModuleCardView(
                                module: module,
                                isSelected: state.selectedModuleID == module.id
                            ) {
                                state.select(module.id)
                            }
                        }
                    }
                }
                .padding(MyDataDCSpacing.xLarge)
            }
        }
        .searchable(text: $state.searchText, prompt: "Search The Manor")
        .task { await state.load() }
    }

    private var header: some View {
        FrostedPanel {
            VStack(alignment: .leading, spacing: MyDataDCSpacing.small) {
                Text("Welcome home, Mr. Mayor.")
                    .font(.largeTitle.bold())
                Text("The Manor")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text("the operating system networked for your digital life")
                    .font(.headline)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.cyan.opacity(0.85), .blue.opacity(0.72), .purple.opacity(0.88)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
#endif
