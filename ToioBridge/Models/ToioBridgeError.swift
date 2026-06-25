import Foundation

enum ToioBridgeError: LocalizedError, Equatable {
    case bluetoothPoweredOff
    case bluetoothPermissionDenied
    case bluetoothUnavailable(String)
    case cubeNotConnected
    case cubeNotFound(String)
    case characteristicNotFound(String)
    case invalidSpeed(Int)
    case invalidDuration(Int)
    case invalidRGB(red: Int, green: Int, blue: Int)
    case invalidSoundEffect(Int)
    case writeFailed(String)

    var errorDescription: String? {
        switch self {
        case .bluetoothPoweredOff:
            return "Bluetooth is off. Turn on Bluetooth and try again."
        case .bluetoothPermissionDenied:
            return "Bluetooth permission is not available for ToioBridge. Allow Bluetooth access in System Settings."
        case .bluetoothUnavailable(let state):
            return "Bluetooth is not ready: \(state)."
        case .cubeNotConnected:
            return "No toio Core Cube is connected. Connect a cube in ToioBridge and try again."
        case .cubeNotFound(let id):
            return "The selected toio Core Cube is not connected: \(id)."
        case .characteristicNotFound(let name):
            return "The cube is connected, but the \(name) characteristic was not discovered."
        case .invalidSpeed(let value):
            return "Motor speed must be between -100 and 100. Received \(value)."
        case .invalidDuration(let value):
            return "Duration must be between 0 and 2550 milliseconds. Received \(value)."
        case .invalidRGB(let red, let green, let blue):
            return "RGB values must be between 0 and 255. Received red \(red), green \(green), blue \(blue)."
        case .invalidSoundEffect(let value):
            return "Sound effect ID must be between 0 and 10. Received \(value)."
        case .writeFailed(let detail):
            return "Failed to write to the cube: \(detail)."
        }
    }
}
