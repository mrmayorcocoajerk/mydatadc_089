import Foundation

public enum PresenceEngine {
    public static func adjustment(for state: PresenceState) -> PresenceAdjustment {
        let base: PresenceAdjustment
        switch state.occupancy {
        case .away:
            base = PresenceAdjustment(lightMultiplier: 0.34, motionMultiplier: 0.22, audioEnabled: false, welcomesResident: false, concealsPersonalContent: true)
        case .arriving:
            base = PresenceAdjustment(lightMultiplier: 1.08, motionMultiplier: 0.72, audioEnabled: true, welcomesResident: true, concealsPersonalContent: false)
        case .present:
            base = PresenceAdjustment(lightMultiplier: 1, motionMultiplier: 1, audioEnabled: true, welcomesResident: false, concealsPersonalContent: false)
        case .idle:
            base = PresenceAdjustment(lightMultiplier: 0.7, motionMultiplier: 0.48, audioEnabled: true, welcomesResident: false, concealsPersonalContent: false)
        case .sleeping:
            base = PresenceAdjustment(lightMultiplier: 0.18, motionMultiplier: 0.08, audioEnabled: false, welcomesResident: false, concealsPersonalContent: true)
        }

        guard state.privacyModeEnabled else { return base }
        return PresenceAdjustment(
            lightMultiplier: base.lightMultiplier,
            motionMultiplier: min(base.motionMultiplier, 0.25),
            audioEnabled: false,
            welcomesResident: base.welcomesResident,
            concealsPersonalContent: true
        )
    }

    public static func apply(_ adjustment: PresenceAdjustment, to profile: AtmosphereProfile) -> AtmosphereProfile {
        AtmosphereProfile(
            lightingTone: profile.lightingTone,
            lightIntensity: profile.lightIntensity * adjustment.lightMultiplier,
            reflectionIntensity: profile.reflectionIntensity,
            motionScale: profile.motionScale * adjustment.motionMultiplier,
            ambientSound: adjustment.audioEnabled ? profile.ambientSound : .silent,
            showsSeasonalAccents: profile.showsSeasonalAccents,
            celebrationAccent: profile.celebrationAccent,
            reducesDistractions: profile.reducesDistractions || adjustment.concealsPersonalContent
        )
    }
}
