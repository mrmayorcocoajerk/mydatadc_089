import Foundation

public enum AETHEREvent: Sendable, Codable, Equatable {
    case workspaceOpened(String)
    case workspaceClosed(String)
    case objectUpdated(String)
}
