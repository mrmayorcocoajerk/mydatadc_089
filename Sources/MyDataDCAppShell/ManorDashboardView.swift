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

    private var dashboardModules: [MyDataDCModule] {
        state.visibleModules.filter { $0.id != .manor }
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
                    if dashboardModules.isEmpty {
                        emptySearchState
                    } else {
                        LazyVGrid(columns: columns, spacing: MyDataDCSpacing.medium) {
                            ForEach(dashboardModules) { module in
                                ModuleCardView(
                                    module: module,
                                    isSelected: state.selectedModuleID == module.id
                                ) {
                                    state.select(module.id)
                                }
                            }
                        }
                    }
                }
                .padding(MyDataDCSpacing.xLarge)
            }
        }
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
                HStack(spacing: MyDataDCSpacing.small) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search The Manor", text: $state.searchText)
                        .textFieldStyle(.roundedBorder)
                    if !state.searchText.isEmpty {
                        Button("Clear") {
                            state.clearSearch()
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .frame(maxWidth: 520)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var emptySearchState: some View {
        FrostedPanel {
            VStack(spacing: MyDataDCSpacing.medium) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 36, weight: .semibold))
                Text("No modules found")
                    .font(.title2.bold())
                Text("Try another search or clear the current query.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("Clear Search") {
                    state.clearSearch()
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, minHeight: 220)
        }
    }
}
#endif
