import AppIntents
import Foundation

struct CubeEntity: AppEntity, Identifiable {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "toio Cube")
    static var defaultQuery = CubeEntityQuery()

    let id: String
    let name: String
    let displayID: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name)",
            subtitle: "ID: \(displayID)"
        )
    }

    init(snapshot: CubeSnapshot) {
        self.id = snapshot.id
        self.name = snapshot.name
        self.displayID = snapshot.displayID
    }
}
