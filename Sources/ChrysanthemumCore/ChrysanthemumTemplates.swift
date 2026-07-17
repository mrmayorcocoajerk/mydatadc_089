import Foundation

public enum ChrysanthemumTemplates {
    public static func dayOneRules() -> [ChrysanthemumRule] {
        [
            ChrysanthemumRule(
                name: "Refresh weather panel",
                eventKind: .dataChanged,
                source: .netSphere,
                subjectPrefix: "weather",
                actions: [.refreshPanel(identifier: "grandHall.weather")]
            ),
            ChrysanthemumRule(
                name: "Surface urgent commerce activity",
                eventKind: .attentionRequired,
                source: .commerce,
                minimumPriority: 70,
                actions: [
                    .openDistrict(.commerce),
                    .postNotification(title: "Commerce needs attention", body: "A delivery, return, or order requires review.")
                ]
            ),
            ChrysanthemumRule(
                name: "Prepare interview scene",
                eventKind: .attentionRequired,
                source: .productivity,
                subjectPrefix: "career.interview",
                minimumPriority: 60,
                actions: [
                    .activateScene(identifier: "work.interview-prep"),
                    .refreshPanel(identifier: "career.upcoming-interview")
                ]
            ),
            ChrysanthemumRule(
                name: "Record completed creative workflow",
                eventKind: .workflowCompleted,
                source: .creative,
                actions: [.recordTimeline(category: "creative")]
            )
        ]
    }
}
