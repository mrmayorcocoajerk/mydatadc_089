import Foundation
import Testing
@testable import LivingEnvironmentCore

@Test func feelsLikeIsProminentInPanelState() {
    let snapshot = WeatherSnapshot(
        locationName: "New York, NY",
        temperatureFahrenheit: 72,
        feelsLikeFahrenheit: 74,
        highFahrenheit: 78,
        lowFahrenheit: 64,
        condition: .partlyCloudy,
        humidityPercent: 58,
        windMilesPerHour: 6,
        precipitationChancePercent: 10,
        uvIndex: 5
    )
    let state = GrandHallWeatherPanelState(snapshot: snapshot)
    #expect(state.temperatureText == "72°F")
    #expect(state.feelsLikeText == "Feels like 74°F")
    #expect(state.highLowText == "H: 78°F  L: 64°F")
}

@Test func thunderstormElevatesSafetyAndReflections() {
    let snapshot = WeatherSnapshot(
        locationName: "Washington, DC",
        temperatureFahrenheit: 81,
        feelsLikeFahrenheit: 89,
        highFahrenheit: 90,
        lowFahrenheit: 74,
        condition: .thunderstorm,
        humidityPercent: 77,
        windMilesPerHour: 18,
        precipitationChancePercent: 90,
        uvIndex: 2
    )
    let scene = LivingEnvironmentEngine.scene(for: snapshot)
    #expect(scene.isSafetyElevated)
    #expect(scene.showsRainReflections)
    #expect(scene.showsLightningReflections)
    #expect(scene.motionLevel == .urgent)
}

@Test func snowCreatesQuietWinterAtmosphere() {
    let snapshot = WeatherSnapshot(
        locationName: "Buffalo, NY",
        temperatureFahrenheit: 28,
        feelsLikeFahrenheit: 18,
        highFahrenheit: 31,
        lowFahrenheit: 16,
        condition: .snow,
        humidityPercent: 83,
        windMilesPerHour: 14,
        precipitationChancePercent: 100,
        uvIndex: 1
    )
    let scene = LivingEnvironmentEngine.scene(for: snapshot)
    #expect(scene.temperatureCharacter == .cold)
    #expect(scene.showsSnowfall)
    #expect(!scene.showsRainReflections)
}

@Test func weatherInputClampsInvalidPercentages() {
    let snapshot = WeatherSnapshot(
        locationName: "Test",
        temperatureFahrenheit: 70,
        feelsLikeFahrenheit: 70,
        highFahrenheit: 70,
        lowFahrenheit: 70,
        condition: .clear,
        humidityPercent: 120,
        windMilesPerHour: -4,
        precipitationChancePercent: -10,
        uvIndex: 40
    )
    #expect(snapshot.humidityPercent == 100)
    #expect(snapshot.windMilesPerHour == 0)
    #expect(snapshot.precipitationChancePercent == 0)
    #expect(snapshot.uvIndex == 15)
}

@Test func lateNightFocusModeReducesMotionAndSound() {
    let snapshot = WeatherSnapshot(
        locationName: "Washington, DC",
        temperatureFahrenheit: 68,
        feelsLikeFahrenheit: 68,
        highFahrenheit: 75,
        lowFahrenheit: 59,
        condition: .clear,
        humidityPercent: 45,
        windMilesPerHour: 3,
        precipitationChancePercent: 0,
        uvIndex: 0
    )
    let context = LivingContext(
        timeOfDay: .lateNight,
        season: .summer,
        focusModeEnabled: true
    )
    let profile = LivingAtmosphereEngine.profile(weather: snapshot, context: context)
    #expect(profile.lightingTone == .midnight)
    #expect(profile.ambientSound == .silent)
    #expect(profile.motionScale < 0.2)
    #expect(profile.reducesDistractions)
}

@Test func winterSnowSelectsIceLightingAndSnowfallAudio() {
    let snapshot = WeatherSnapshot(
        locationName: "Buffalo, NY",
        temperatureFahrenheit: 24,
        feelsLikeFahrenheit: 12,
        highFahrenheit: 29,
        lowFahrenheit: 10,
        condition: .snow,
        humidityPercent: 88,
        windMilesPerHour: 12,
        precipitationChancePercent: 100,
        uvIndex: 1
    )
    let context = LivingContext(timeOfDay: .morning, season: .winter)
    let profile = LivingAtmosphereEngine.profile(weather: snapshot, context: context)
    #expect(profile.lightingTone == .ice)
    #expect(profile.ambientSound == .snowfall)
    #expect(profile.reflectionIntensity >= 0.6)
}

@Test func celebrationStateFlowsIntoAtmosphere() {
    let snapshot = WeatherSnapshot(
        locationName: "New York, NY",
        temperatureFahrenheit: 48,
        feelsLikeFahrenheit: 45,
        highFahrenheit: 50,
        lowFahrenheit: 40,
        condition: .cloudy,
        humidityPercent: 60,
        windMilesPerHour: 5,
        precipitationChancePercent: 10,
        uvIndex: 2
    )
    let context = LivingContext(
        timeOfDay: .evening,
        season: .winter,
        celebration: .birthday
    )
    let profile = LivingAtmosphereEngine.profile(weather: snapshot, context: context)
    #expect(profile.celebrationAccent == .birthday)
    #expect(profile.showsSeasonalAccents)
}

@Test func timeAndSeasonDeriveFromCalendarDate() {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    let components = DateComponents(
        calendar: calendar,
        timeZone: calendar.timeZone,
        year: 2026,
        month: 10,
        day: 15,
        hour: 18
    )
    let date = components.date!
    #expect(LivingContext.timeOfDay(for: date, calendar: calendar) == .evening)
    #expect(LivingContext.season(for: date, calendar: calendar) == .autumn)
}

@Test func environmentTransitionUsesCinematicPaceForMajorChange() {
    let old = AtmosphereProfile(
        lightingTone: .daylight,
        lightIntensity: 0.9,
        reflectionIntensity: 0.4,
        motionScale: 0.2,
        ambientSound: .softRoom,
        showsSeasonalAccents: true,
        celebrationAccent: .none,
        reducesDistractions: false
    )
    let new = AtmosphereProfile(
        lightingTone: .midnight,
        lightIntensity: 0.2,
        reflectionIntensity: 0.9,
        motionScale: 0.6,
        ambientSound: .rain,
        showsSeasonalAccents: true,
        celebrationAccent: .none,
        reducesDistractions: false
    )
    let transition = LivingAtmosphereEngine.transition(from: old, to: new)
    #expect(transition.pace == .cinematic)
    #expect(transition.crossfadesAudio)
    #expect(transition.interpolatesLighting)
}


@Test func awayModeDimsAndSilencesProfile() {
    let profile = AtmosphereProfile(lightingTone: .daylight, lightIntensity: 0.8, reflectionIntensity: 0.5, motionScale: 0.7, ambientSound: .softRoom, showsSeasonalAccents: true, celebrationAccent: .none, reducesDistractions: false)
    let adjustment = PresenceEngine.adjustment(for: PresenceState(occupancy: .away))
    let result = PresenceEngine.apply(adjustment, to: profile)
    #expect(result.ambientSound == .silent)
    #expect(result.lightIntensity < profile.lightIntensity)
    #expect(result.reducesDistractions)
}

@Test func arrivingModeWelcomesResident() {
    let adjustment = PresenceEngine.adjustment(for: PresenceState(occupancy: .arriving, nearbyDeviceCount: 2))
    #expect(adjustment.welcomesResident)
    #expect(adjustment.audioEnabled)
}

@Test func privacyModeConcealsContent() {
    let adjustment = PresenceEngine.adjustment(for: PresenceState(occupancy: .present, privacyModeEnabled: true))
    #expect(adjustment.concealsPersonalContent)
    #expect(!adjustment.audioEnabled)
}

@Test func safetyAlertOverridesOtherSignals() {
    let signals = [
        CrystalHeartbeatEngine.signal(for: .notification),
        CrystalHeartbeatEngine.signal(for: .success),
        CrystalHeartbeatEngine.signal(for: .safetyAlert)
    ]
    #expect(CrystalHeartbeatEngine.prioritized(signals).event == .safetyAlert)
}

@Test func renderProgressClampsAndRaisesIntensity() {
    let start = CrystalHeartbeatEngine.signal(for: .renderProgress, progress: 0)
    let finish = CrystalHeartbeatEngine.signal(for: .renderProgress, progress: 2)
    #expect(finish.intensity > start.intensity)
    #expect(finish.intensity <= 1)
}

@Test func focusSignalSuppressesOtherSignals() {
    #expect(CrystalHeartbeatEngine.signal(for: .focusStarted).suppressesOtherSignals)
}

@Test func recallPrefersSameSeasonAndTag() {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    let target = calendar.date(from: DateComponents(year: 2030, month: 7, day: 12))!
    let profile = AtmosphereProfile(lightingTone: .amber, lightIntensity: 0.8, reflectionIntensity: 0.4, motionScale: 0.3, ambientSound: .softRoom, showsSeasonalAccents: true, celebrationAccent: .none, reducesDistractions: false)
    let summer = EnvironmentMemory(capturedAt: calendar.date(from: DateComponents(year: 2028, month: 7, day: 12))!, title: "Japan", profile: profile, dominantTags: ["travel"], importance: 0.9)
    let winter = EnvironmentMemory(capturedAt: calendar.date(from: DateComponents(year: 2029, month: 12, day: 25))!, title: "Winter", profile: profile, dominantTags: ["holiday"], importance: 1)
    #expect(SeasonalMemoryEngine.recall(from: [winter, summer], near: target, matchingTags: ["travel"], calendar: calendar)?.title == "Japan")
}

@Test func memoryBlendIsSubtleAndPreservesCurrentAudio() {
    let rememberedProfile = AtmosphereProfile(lightingTone: .amber, lightIntensity: 0.8, reflectionIntensity: 0.4, motionScale: 0.3, ambientSound: .softRoom, showsSeasonalAccents: true, celebrationAccent: .none, reducesDistractions: false)
    let current = AtmosphereProfile(lightingTone: .midnight, lightIntensity: 0.2, reflectionIntensity: 0.2, motionScale: 0.1, ambientSound: .rain, showsSeasonalAccents: false, celebrationAccent: .none, reducesDistractions: true)
    let memory = EnvironmentMemory(capturedAt: .now, title: "Memory", profile: rememberedProfile)
    let blended = SeasonalMemoryEngine.blend(current: current, recalled: memory, strength: 1)
    #expect(blended.ambientSound == .rain)
    #expect(blended.lightIntensity < rememberedProfile.lightIntensity)
    #expect(blended.lightIntensity > current.lightIntensity)
}
