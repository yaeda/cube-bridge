import XCTest

final class CubeCommandTests: XCTestCase {
    func testMoveEncodesForwardBackwardAndDuration() throws {
        let command = try CubeCommand.move(left: 100, right: -20, durationMs: 100)

        XCTAssertEqual(command.target, .motor)
        XCTAssertEqual(Array(command.data), [0x02, 0x01, 0x01, 100, 0x02, 0x02, 20, 10])
    }

    func testMoveEncodesZeroDurationAsUnlimited() throws {
        let command = try CubeCommand.move(left: 0, right: 0, durationMs: 0)

        XCTAssertEqual(Array(command.data), [0x02, 0x01, 0x01, 0, 0x02, 0x01, 0, 0])
    }

    func testMoveRoundsDurationUpToTenMillisecondUnits() throws {
        let command = try CubeCommand.move(left: 10, right: 10, durationMs: 101)

        XCTAssertEqual(Array(command.data).last, 11)
    }

    func testStopCommandBytes() {
        let command = CubeCommand.stop()

        XCTAssertEqual(command.target, .motor)
        XCTAssertEqual(Array(command.data), [0x01, 0x01, 0x01, 0x00, 0x02, 0x01, 0x00])
    }

    func testLampCommandBytes() throws {
        let command = try CubeCommand.setLamp(red: 255, green: 32, blue: 16, durationMs: 160)

        XCTAssertEqual(command.target, .lamp)
        XCTAssertEqual(Array(command.data), [0x03, 16, 0x01, 0x01, 255, 32, 16])
    }

    func testTurnOffLampCommandBytes() {
        let command = CubeCommand.turnOffLamp()

        XCTAssertEqual(command.target, .lamp)
        XCTAssertEqual(Array(command.data), [0x01])
    }

    func testInvalidSpeedThrows() {
        XCTAssertThrowsError(try CubeCommand.move(left: 101, right: 0, durationMs: 100)) { error in
            XCTAssertEqual(error as? ToioBridgeError, .invalidSpeed(101))
        }
    }

    func testInvalidDurationThrows() {
        XCTAssertThrowsError(try CubeCommand.move(left: 0, right: 0, durationMs: 2551)) { error in
            XCTAssertEqual(error as? ToioBridgeError, .invalidDuration(2551))
        }
    }

    func testInvalidRGBThrows() {
        XCTAssertThrowsError(try CubeCommand.setLamp(red: 256, green: 0, blue: 0, durationMs: 100)) { error in
            XCTAssertEqual(error as? ToioBridgeError, .invalidRGB(red: 256, green: 0, blue: 0))
        }
    }
}
