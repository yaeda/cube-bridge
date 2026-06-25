import AppIntents
import Foundation

struct CubeEntityQuery: EntityQuery {
    func entities(for identifiers: [CubeEntity.ID]) async throws -> [CubeEntity] {
        await MainActor.run {
            CubeManager.shared.connectedCubeSnapshots()
                .filter { identifiers.contains($0.id) }
                .map(CubeEntity.init(snapshot:))
        }
    }

    func suggestedEntities() async throws -> [CubeEntity] {
        await MainActor.run {
            CubeManager.shared.connectedCubeSnapshots()
                .map(CubeEntity.init(snapshot:))
        }
    }

    func defaultResult() async -> CubeEntity? {
        await MainActor.run {
            CubeManager.shared.connectedCubeSnapshots()
                .first
                .map(CubeEntity.init(snapshot:))
        }
    }
}
