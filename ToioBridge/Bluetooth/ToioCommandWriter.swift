import CoreBluetooth
import Foundation

struct ToioCommandWriter {
    static func characteristic(for command: CubeCommand, cube: ToioCube) throws -> CBCharacteristic {
        switch command.target {
        case .motor:
            guard let characteristic = cube.motorCharacteristic else {
                throw ToioBridgeError.characteristicNotFound("motor")
            }
            return characteristic
        case .lamp:
            guard let characteristic = cube.lampCharacteristic else {
                throw ToioBridgeError.characteristicNotFound("lamp")
            }
            return characteristic
        case .sound:
            guard let characteristic = cube.soundCharacteristic else {
                throw ToioBridgeError.characteristicNotFound("sound")
            }
            return characteristic
        }
    }

    static func writeType(for characteristic: CBCharacteristic) -> CBCharacteristicWriteType {
        if characteristic.properties.contains(.write) {
            return .withResponse
        }
        return .withoutResponse
    }
}
