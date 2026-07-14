import XCTest

@MainActor
final class CubeCommandQueueTests: XCTestCase {
    func testSameCubeCommandsRunSeriallyInFIFOOrder() async throws {
        let queue = CubeCommandQueue()
        let firstStarted = expectation(description: "First command started")
        let releaseFirst = TestGate()
        var events: [String] = []

        let first = Task { @MainActor in
            try await queue.perform(cubeID: "cube-a") {
                events.append("first-start")
                firstStarted.fulfill()
                await releaseFirst.wait()
                events.append("first-end")
            }
        }

        await fulfillment(of: [firstStarted], timeout: 1)

        let second = Task { @MainActor in
            try await queue.perform(cubeID: "cube-a") {
                events.append("second")
            }
        }
        await Task.yield()

        let third = Task { @MainActor in
            try await queue.perform(cubeID: "cube-a") {
                events.append("third")
            }
        }
        await Task.yield()

        XCTAssertEqual(events, ["first-start"])

        await releaseFirst.open()
        try await first.value
        try await second.value
        try await third.value
        XCTAssertEqual(events, ["first-start", "first-end", "second", "third"])
    }

    func testDifferentCubeCommandsRunConcurrently() async throws {
        let queue = CubeCommandQueue()
        let firstStarted = expectation(description: "First cube command started")
        let secondStarted = expectation(description: "Second cube command started")
        let releaseCommands = TestGate()

        let first = Task { @MainActor in
            try await queue.perform(cubeID: "cube-a") {
                firstStarted.fulfill()
                await releaseCommands.wait()
            }
        }
        let second = Task { @MainActor in
            try await queue.perform(cubeID: "cube-b") {
                secondStarted.fulfill()
                await releaseCommands.wait()
            }
        }

        await fulfillment(of: [firstStarted, secondStarted], timeout: 1)
        await releaseCommands.open()
        try await first.value
        try await second.value
    }

    func testThrownOperationReleasesCube() async throws {
        let queue = CubeCommandQueue()

        do {
            try await queue.perform(cubeID: "cube-a") {
                throw TestError.expected
            }
            XCTFail("Expected command to throw")
        } catch TestError.expected {
        }

        let result = try await queue.perform(cubeID: "cube-a") { "completed" }
        XCTAssertEqual(result, "completed")
    }

    func testCancelledWaiterReleasesCubeForFollowingCommand() async throws {
        let queue = CubeCommandQueue()
        let firstStarted = expectation(description: "First command started")
        let releaseFirst = TestGate()

        let first = Task { @MainActor in
            try await queue.perform(cubeID: "cube-a") {
                firstStarted.fulfill()
                await releaseFirst.wait()
            }
        }
        await fulfillment(of: [firstStarted], timeout: 1)

        let cancelled = Task { @MainActor in
            try await queue.perform(cubeID: "cube-a") {
                XCTFail("Cancelled operation should not run")
            }
        }
        await Task.yield()
        cancelled.cancel()

        await releaseFirst.open()
        try await first.value

        do {
            try await cancelled.value
            XCTFail("Expected cancellation")
        } catch is CancellationError {
        }

        let result = try await queue.perform(cubeID: "cube-a") { "completed" }
        XCTAssertEqual(result, "completed")
    }
}

private actor TestGate {
    private var isOpen = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func wait() async {
        guard !isOpen else {
            return
        }

        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }

    func open() {
        isOpen = true
        let currentWaiters = waiters
        waiters.removeAll()
        currentWaiters.forEach { $0.resume() }
    }
}

private enum TestError: Error {
    case expected
}
