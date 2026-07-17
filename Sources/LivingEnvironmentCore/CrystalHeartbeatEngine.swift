import Foundation

public enum CrystalHeartbeatEngine {
    public static func signal(for event: CrystalSignal.Event, progress: Double? = nil) -> CrystalSignal {
        switch event {
        case .idle:
            return CrystalSignal(event: event, pattern: .dormant, intensity: 0.16, durationSeconds: 0, suppressesOtherSignals: false)
        case .notification:
            return CrystalSignal(event: event, pattern: .ripple, intensity: 0.45, durationSeconds: 1.1, suppressesOtherSignals: false)
        case .packageArrival:
            return CrystalSignal(event: event, pattern: .doublePulse, intensity: 0.66, durationSeconds: 1.6, suppressesOtherSignals: false)
        case .interviewScheduled:
            return CrystalSignal(event: event, pattern: .radiantBloom, intensity: 0.82, durationSeconds: 2.2, suppressesOtherSignals: false)
        case .renderProgress:
            let normalized = min(max(progress ?? 0, 0), 1)
            return CrystalSignal(event: event, pattern: .progressOrbit, intensity: 0.3 + normalized * 0.55, durationSeconds: 0, suppressesOtherSignals: false)
        case .focusStarted:
            return CrystalSignal(event: event, pattern: .quietGlow, intensity: 0.3, durationSeconds: 1.8, suppressesOtherSignals: true)
        case .safetyAlert:
            return CrystalSignal(event: event, pattern: .urgentBeacon, intensity: 1, durationSeconds: 3, suppressesOtherSignals: true)
        case .success:
            return CrystalSignal(event: event, pattern: .radiantBloom, intensity: 0.94, durationSeconds: 2.8, suppressesOtherSignals: false)
        }
    }

    public static func prioritized(_ signals: [CrystalSignal]) -> CrystalSignal {
        signals.max { lhs, rhs in
            priority(lhs) < priority(rhs)
        } ?? signal(for: .idle)
    }

    private static func priority(_ signal: CrystalSignal) -> Int {
        if signal.suppressesOtherSignals { return signal.event == .safetyAlert ? 100 : 80 }
        switch signal.event {
        case .success: return 70
        case .interviewScheduled: return 60
        case .packageArrival: return 50
        case .renderProgress: return 40
        case .notification: return 30
        case .idle: return 0
        case .focusStarted, .safetyAlert: return 80
        }
    }
}
