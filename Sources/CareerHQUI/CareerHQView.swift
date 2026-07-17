#if canImport(SwiftUI)
import SwiftUI
import CareerHQCore

@MainActor
public final class CareerHQViewModel: ObservableObject {
    @Published public private(set) var applications: [CareerApplication] = []
    @Published public var filter = CareerHQFilter()
    @Published public var selectedApplicationID: UUID?
    @Published public var isPresentingEditor = false
    @Published public var errorMessage: String?

    private let store: CareerHQStore

    public init(store: CareerHQStore = CareerHQStore()) {
        self.store = store
    }

    public var visibleApplications: [CareerApplication] { filter.apply(to: applications) }
    public var summary: CareerHQSummary { CareerHQSummary(applications: applications) }
    public var selectedApplication: CareerApplication? { applications.first { $0.id == selectedApplicationID } }

    public func load() async {
        do {
            try await store.load()
            applications = await store.allApplications()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func save(_ application: CareerApplication) async {
        do {
            if applications.contains(where: { $0.id == application.id }) {
                _ = try await store.update(application)
            } else {
                _ = try await store.add(application)
            }
            applications = await store.allApplications()
            selectedApplicationID = application.id
            isPresentingEditor = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func setStatus(_ status: ApplicationStatus, for id: UUID) async {
        do {
            try await store.setStatus(status, for: id)
            applications = await store.allApplications()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

public struct CareerHQView: View {
    @StateObject private var model: CareerHQViewModel

    public init(model: CareerHQViewModel = CareerHQViewModel()) {
        _model = StateObject(wrappedValue: model)
    }

    public var body: some View {
        NavigationSplitView {
            VStack(spacing: 12) {
                summaryStrip
                applicationList
            }
            .padding()
            .navigationTitle("Career HQ")
            .searchable(text: $model.filter.searchText, prompt: "Employer, role, location, notes")
            .toolbar {
                Button {
                    model.isPresentingEditor = true
                } label: {
                    Label("Add Application", systemImage: "plus")
                }
            }
        } detail: {
            if let application = model.selectedApplication {
                CareerApplicationDetailView(application: application) { status in
                    Task { await model.setStatus(status, for: application.id) }
                }
            } else {
                ContentUnavailableView("Select an application", systemImage: "briefcase")
            }
        }
        .task { await model.load() }
        .sheet(isPresented: $model.isPresentingEditor) {
            CareerApplicationEditorView { application in
                Task { await model.save(application) }
            }
        }
        .alert("Career HQ", isPresented: Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { model.errorMessage = nil }
        } message: {
            Text(model.errorMessage ?? "Unknown error")
        }
    }

    private var summaryStrip: some View {
        HStack {
            SummaryMetric(title: "Total", value: model.summary.total)
            SummaryMetric(title: "Active", value: model.summary.active)
            SummaryMetric(title: "Interviews", value: model.summary.interviews)
            SummaryMetric(title: "Offers", value: model.summary.offers)
        }
    }

    private var applicationList: some View {
        List(model.visibleApplications, selection: $model.selectedApplicationID) { application in
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(application.role).font(.headline)
                    Spacer()
                    Text(application.status.rawValue).font(.caption)
                }
                Text(application.employer).font(.subheadline)
                Text([application.location, application.workArrangement.rawValue].filter { !$0.isEmpty }.joined(separator: " • "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .tag(application.id)
        }
    }
}

private struct SummaryMetric: View {
    let title: String
    let value: Int
    var body: some View {
        VStack(alignment: .leading) {
            Text("\(value)").font(.title2.bold())
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
    }
}

public struct CareerApplicationDetailView: View {
    let application: CareerApplication
    let onStatusChange: (ApplicationStatus) -> Void

    public var body: some View {
        Form {
            Section("General Summary") {
                LabeledContent("Employer", value: application.employer)
                LabeledContent("Role", value: application.role)
                LabeledContent("Location", value: application.location.isEmpty ? "Not specified" : application.location)
                LabeledContent("Arrangement", value: application.workArrangement.rawValue)
                Picker("Status", selection: Binding(get: { application.status }, set: { status in onStatusChange(status) })) {
                    ForEach(ApplicationStatus.allCases) { status in Text(status.rawValue).tag(status) }
                }
            }
            Section("Notes") { Text(application.notes.isEmpty ? "No notes yet." : application.notes) }
            Section("Documents") {
                if application.documentReferences.isEmpty {
                    Text("No document references.").foregroundStyle(.secondary)
                } else {
                    ForEach(application.documentReferences, id: \.self) { reference in Text(reference) }
                }
            }
        }
        .navigationTitle(application.role)
    }
}

public struct CareerApplicationEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var employer = ""
    @State private var role = ""
    @State private var location = ""
    @State private var arrangement: WorkArrangement = .hybrid
    @State private var status: ApplicationStatus = .saved
    @State private var notes = ""
    let onSave: (CareerApplication) -> Void

    public var body: some View {
        NavigationStack {
            Form {
                TextField("Employer", text: $employer)
                TextField("Role", text: $role)
                TextField("Location", text: $location)
                Picker("Work arrangement", selection: $arrangement) {
                    ForEach(WorkArrangement.allCases) { Text($0.rawValue).tag($0) }
                }
                Picker("Status", selection: $status) {
                    ForEach(ApplicationStatus.allCases) { Text($0.rawValue).tag($0) }
                }
                TextField("Notes", text: $notes, axis: .vertical)
            }
            .navigationTitle("New Application")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(.init(employer: employer, role: role, location: location, workArrangement: arrangement, status: status, notes: notes))
                    }
                    .disabled(employer.trimmingCharacters(in: .whitespaces).isEmpty || role.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .frame(minWidth: 480, minHeight: 420)
    }
}
#endif
