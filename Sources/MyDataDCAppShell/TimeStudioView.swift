#if canImport(SwiftUI)
import SwiftUI
import TimeCore

public struct TimeStudioView: View {
    private let onReturnToManor: () -> Void
    @State private var mode: TimeStudioMode = .stopwatch
    @State private var stopwatch = StopwatchState()
    @State private var countdown = CountdownState()

    public init(onReturnToManor: @escaping () -> Void = {}) {
        self.onReturnToManor = onReturnToManor
    }

    public var body: some View {
        ZStack {
            LivingGradient()
            ScrollView {
                VStack(alignment: .leading, spacing: MyDataDCSpacing.large) {
                    header
                    Picker("Clock mode", selection: $mode) {
                        ForEach(TimeStudioMode.allCases) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)

                    TimelineView(.periodic(from: .now, by: 0.1)) { context in
                        if mode == .stopwatch {
                            stopwatchPanel(at: context.date)
                        } else {
                            timerPanel(at: context.date)
                        }
                    }
                }
                .padding(MyDataDCSpacing.xLarge)
            }
        }
        .navigationTitle("Time Studio")
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: MyDataDCSpacing.xSmall) {
                Text("Time Studio")
                    .font(.largeTitle.bold())
                Text("Stay on pace with a focused timer and precision stopwatch.")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("The Manor", systemImage: "building.columns", action: onReturnToManor)
        }
    }

    private func stopwatchPanel(at date: Date) -> some View {
        FrostedPanel {
            VStack(spacing: MyDataDCSpacing.large) {
                Label("Stopwatch", systemImage: "stopwatch.fill")
                    .font(.title2.bold())
                Text(TimeDisplayFormatter.clock(stopwatch.elapsed(at: date)))
                    .font(.system(size: 72, weight: .semibold, design: .rounded))
                    .monospacedDigit()

                HStack {
                    Button(stopwatch.isRunning ? "Pause" : "Start", systemImage: stopwatch.isRunning ? "pause.fill" : "play.fill") {
                        if stopwatch.isRunning { stopwatch.pause(at: date) } else { stopwatch.start(at: date) }
                    }
                    .buttonStyle(.borderedProminent)
                    Button("Lap", systemImage: "flag.fill") { _ = stopwatch.recordLap(at: date) }
                        .disabled(stopwatch.elapsed(at: date) <= 0)
                    Button("Reset", systemImage: "arrow.counterclockwise") { stopwatch.reset() }
                }

                if !stopwatch.laps.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: MyDataDCSpacing.small) {
                        ForEach(Array(stopwatch.laps.enumerated().reversed()), id: \.offset) { index, lap in
                            HStack {
                                Text("Lap \(index + 1)")
                                Spacer()
                                Text(TimeDisplayFormatter.clock(lap)).monospacedDigit()
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func timerPanel(at date: Date) -> some View {
        FrostedPanel {
            VStack(spacing: MyDataDCSpacing.large) {
                Label("Focus Timer", systemImage: "timer")
                    .font(.title2.bold())
                Text(TimeDisplayFormatter.clock(countdown.remaining(at: date)))
                    .font(.system(size: 72, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(countdown.isFinished(at: date) ? Color.red : Color.primary)

                HStack {
                    ForEach([1, 5, 10, 25], id: \.self) { minutes in
                        Button("\(minutes) min") { countdown.setDuration(TimeInterval(minutes * 60)) }
                            .disabled(countdown.isRunning)
                    }
                }
                HStack {
                    Button(countdown.isRunning ? "Pause" : "Start", systemImage: countdown.isRunning ? "pause.fill" : "play.fill") {
                        if countdown.isRunning { countdown.pause(at: date) } else { countdown.start(at: date) }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(countdown.isFinished(at: date))
                    Button("Reset", systemImage: "arrow.counterclockwise") { countdown.reset() }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}
#endif
