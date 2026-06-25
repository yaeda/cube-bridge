import Foundation

struct CubeCommand: Equatable {
    enum Target: Equatable {
        case motor
        case lamp
        case sound
    }

    let target: Target
    let data: Data

    static func move(left: Int, right: Int, durationMs: Int) throws -> CubeCommand {
        try validateSpeed(left)
        try validateSpeed(right)
        let duration = try durationUnit(from: durationMs)
        let leftMotor = motorBytes(id: 0x01, speed: left)
        let rightMotor = motorBytes(id: 0x02, speed: right)

        return CubeCommand(
            target: .motor,
            data: Data([
                0x02,
                leftMotor.id, leftMotor.direction, leftMotor.speed,
                rightMotor.id, rightMotor.direction, rightMotor.speed,
                duration
            ])
        )
    }

    static func stop() -> CubeCommand {
        CubeCommand(
            target: .motor,
            data: Data([0x01, 0x01, 0x01, 0x00, 0x02, 0x01, 0x00])
        )
    }

    static func setLamp(red: Int, green: Int, blue: Int, durationMs: Int) throws -> CubeCommand {
        guard (0...255).contains(red), (0...255).contains(green), (0...255).contains(blue) else {
            throw ToioBridgeError.invalidRGB(red: red, green: green, blue: blue)
        }

        let duration = try durationUnit(from: durationMs)
        return CubeCommand(
            target: .lamp,
            data: Data([0x03, duration, 0x01, 0x01, UInt8(red), UInt8(green), UInt8(blue)])
        )
    }

    static func turnOffLamp() -> CubeCommand {
        CubeCommand(target: .lamp, data: Data([0x01]))
    }

    static func playSoundEffect(id: Int, volume: Int = 255) throws -> CubeCommand {
        guard (0...10).contains(id) else {
            throw ToioBridgeError.invalidSoundEffect(id)
        }
        guard (0...255).contains(volume) else {
            throw ToioBridgeError.invalidRGB(red: volume, green: volume, blue: volume)
        }

        return CubeCommand(target: .sound, data: Data([0x02, UInt8(id), UInt8(volume)]))
    }

    static func stopSound() -> CubeCommand {
        CubeCommand(target: .sound, data: Data([0x01]))
    }

    private static func validateSpeed(_ speed: Int) throws {
        guard (-100...100).contains(speed) else {
            throw ToioBridgeError.invalidSpeed(speed)
        }
    }

    private static func durationUnit(from durationMs: Int) throws -> UInt8 {
        guard (0...2550).contains(durationMs) else {
            throw ToioBridgeError.invalidDuration(durationMs)
        }
        guard durationMs > 0 else {
            return 0
        }
        return UInt8((durationMs + 9) / 10)
    }

    private static func motorBytes(id: UInt8, speed: Int) -> (id: UInt8, direction: UInt8, speed: UInt8) {
        let direction: UInt8 = speed < 0 ? 0x02 : 0x01
        return (id, direction, UInt8(abs(speed)))
    }
}
