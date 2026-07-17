#if canImport(SwiftUI)
import SwiftUI
import MyDataDCCore

public struct ModuleCardView: View {
    private let module: MyDataDCModule
    private let isSelected: Bool
    private let action: () -> Void

    public init(module: MyDataDCModule, isSelected: Bool, action: @escaping () -> Void) {
        self.module = module
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: MyDataDCSpacing.medium) {
                HStack {
                    Image(systemName: module.systemImage)
                        .font(.title2.weight(.semibold))
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                    }
                }

                Spacer(minLength: MyDataDCSpacing.small)

                Text(module.displayName)
                    .font(.headline)
                    .multilineTextAlignment(.leading)

                Text(module.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
            }
            .frame(maxWidth: .infinity, minHeight: 150, alignment: .leading)
            .padding(MyDataDCSpacing.large)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: MyDataDCRadius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: MyDataDCRadius.card, style: .continuous)
                    .stroke(isSelected ? .cyan.opacity(0.9) : .white.opacity(0.12), lineWidth: isSelected ? 2 : 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(module.displayName)
        .accessibilityHint("Open \(module.displayName)")
    }
}
#endif
