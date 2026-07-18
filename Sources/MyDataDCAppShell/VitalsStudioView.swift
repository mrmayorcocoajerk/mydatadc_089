#if canImport(SwiftUI)
import SwiftUI
import VitalsCore

public struct VitalsStudioView: View {
    @StateObject private var viewModel: VitalsStudioViewModel
    @State private var editor: VitalsEditorDestination?
    @State private var entryToDelete: VitalsEntry?
    private let onReturnToManor: () -> Void

    public init(
        viewModel: VitalsStudioViewModel = VitalsStudioViewModel(),
        onReturnToManor: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onReturnToManor = onReturnToManor
    }

    public var body: some View {
        ZStack {
            LivingGradient().ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: MyDataDCSpacing.large) {
                    header
                    summaryGrid
                    journalPanel
                }
                .padding(MyDataDCSpacing.xLarge)
            }
        }
        .navigationTitle("Vitals Studio")
        .task { await viewModel.load() }
        .sheet(item: $editor) { destination in
            VitalsEntryEditor(viewModel: viewModel, entry: destination.entry)
        }
        .alert(
            "Delete vital entry?",
            isPresented: Binding(
                get: { entryToDelete != nil },
                set: { if !$0 { entryToDelete = nil } }
            ),
            presenting: entryToDelete
        ) { entry in
            Button("Cancel", role: .cancel) { entryToDelete = nil }
            Button("Delete", role: .destructive) {
                entryToDelete = nil
                Task { try? await viewModel.deleteEntry(id: entry.id) }
            }
        } message: { _ in
            Text("This removes the entry from your private on-device journal.")
        }
    }

    private var header: some View {
        FrostedPanel {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: MyDataDCSpacing.small) {
                    Text("Vitals Studio").font(.largeTitle.bold())
                    Text("A calm, private place to track everyday wellbeing.")
                        .font(.headline).foregroundStyle(.secondary)
                }
                Spacer()
                Button("Back to The Manor", systemImage: "house", action: onReturnToManor)
            }
        }
    }

    private var summaryGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 16)], spacing: 16) {
            metric("Average Sleep", value: viewModel.summary.averageSleepHours.formatted(.number.precision(.fractionLength(1))) + " hr", icon: "moon.stars")
            metric("Water", value: "\(viewModel.summary.totalWaterGlasses) glasses", icon: "drop")
            metric("Active Time", value: "\(viewModel.summary.totalActiveMinutes) min", icon: "figure.walk")
            metric("Days Logged", value: "\(viewModel.summary.daysLogged) of 7", icon: "calendar")
        }
    }

    private func metric(_ title: String, value: String, icon: String) -> some View {
        FrostedPanel {
            VStack(alignment: .leading, spacing: 8) {
                Label(title, systemImage: icon).foregroundStyle(.secondary)
                Text(value).font(.title2.bold()).monospacedDigit()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var journalPanel: some View {
        FrostedPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Wellbeing Journal").font(.title2.bold())
                        Text("Stored only on this device.").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Add Entry", systemImage: "plus") { editor = VitalsEditorDestination(entry: nil) }
                }

                if viewModel.recentEntries.isEmpty {
                    ContentUnavailableView(
                        "No entries yet",
                        systemImage: "heart.text.square",
                        description: Text("Add a quick check-in to begin your seven-day view.")
                    )
                } else {
                    ForEach(viewModel.recentEntries) { entry in
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.date.formatted(date: .abbreviated, time: .omitted)).font(.headline)
                                Text("\(entry.sleepHours.formatted(.number.precision(.fractionLength(1)))) hr sleep · \(entry.waterGlasses) water · \(entry.activeMinutes) active min")
                                    .font(.subheadline).foregroundStyle(.secondary)
                                if !entry.note.isEmpty {
                                    Text(entry.note).font(.caption).lineLimit(2)
                                }
                            }
                            Spacer()
                            Menu {
                                Button("Edit", systemImage: "pencil") { editor = VitalsEditorDestination(entry: entry) }
                                Button("Delete", systemImage: "trash", role: .destructive) { entryToDelete = entry }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                            }
                        }
                        Divider()
                    }
                }
            }
        }
    }
}

private struct VitalsEditorDestination: Identifiable {
    let id = UUID()
    let entry: VitalsEntry?
}

private struct VitalsEntryEditor: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: VitalsStudioViewModel
    let entry: VitalsEntry?
    @State private var date: Date
    @State private var sleepHours: Double
    @State private var waterGlasses: Int
    @State private var activeMinutes: Int
    @State private var note: String
    @State private var errorMessage: String?

    init(viewModel: VitalsStudioViewModel, entry: VitalsEntry?) {
        self.viewModel = viewModel
        self.entry = entry
        _date = State(initialValue: entry?.date ?? Date())
        _sleepHours = State(initialValue: entry?.sleepHours ?? 8)
        _waterGlasses = State(initialValue: entry?.waterGlasses ?? 8)
        _activeMinutes = State(initialValue: entry?.activeMinutes ?? 30)
        _note = State(initialValue: entry?.note ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Date", selection: $date, displayedComponents: .date)
                Stepper("Sleep: \(sleepHours.formatted(.number.precision(.fractionLength(1)))) hours", value: $sleepHours, in: 0...24, step: 0.5)
                Stepper("Water: \(waterGlasses) glasses", value: $waterGlasses, in: 0...30)
                Stepper("Active time: \(activeMinutes) minutes", value: $activeMinutes, in: 0...1_440, step: 5)
                TextField("Optional note", text: $note, axis: .vertical)
                if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
            }
            .formStyle(.grouped)
            .navigationTitle(entry == nil ? "Add Vitals" : "Edit Vitals")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            do {
                                try await viewModel.saveEntry(
                                    id: entry?.id,
                                    date: date,
                                    sleepHours: sleepHours,
                                    waterGlasses: waterGlasses,
                                    activeMinutes: activeMinutes,
                                    note: note
                                )
                                dismiss()
                            } catch {
                                errorMessage = "The entry could not be saved."
                            }
                        }
                    }
                }
            }
        }
        .frame(minWidth: 480, minHeight: 430)
    }
}
#endif
