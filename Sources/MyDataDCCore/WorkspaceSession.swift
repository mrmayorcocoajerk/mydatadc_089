import Foundation
public struct WorkspaceSession: Codable, Sendable, Equatable {
 public var activeWorkspaceID:AETHERWorkspaceID?
 public var openWorkspaceIDs:[AETHERWorkspaceID]
 public var schemaVersion:Int
 public init(activeWorkspaceID:AETHERWorkspaceID?,openWorkspaceIDs:[AETHERWorkspaceID],schemaVersion:Int=82){
 self.activeWorkspaceID=activeWorkspaceID; self.openWorkspaceIDs=openWorkspaceIDs; self.schemaVersion=schemaVersion}
}
