@MainActor
final class CubeCommandQueue {
    private var activeCubeIDs: Set<String> = []
    private var waitersByCubeID: [String: [CheckedContinuation<Void, Never>]] = [:]

    func perform<T>(cubeID: String, operation: () async throws -> T) async throws -> T {
        await acquire(cubeID: cubeID)
        defer { release(cubeID: cubeID) }
        try Task.checkCancellation()
        return try await operation()
    }

    private func acquire(cubeID: String) async {
        if activeCubeIDs.insert(cubeID).inserted {
            return
        }

        await withCheckedContinuation { continuation in
            waitersByCubeID[cubeID, default: []].append(continuation)
        }
    }

    private func release(cubeID: String) {
        guard var waiters = waitersByCubeID[cubeID], !waiters.isEmpty else {
            activeCubeIDs.remove(cubeID)
            return
        }

        let next = waiters.removeFirst()
        waitersByCubeID[cubeID] = waiters.isEmpty ? nil : waiters
        next.resume()
    }
}
