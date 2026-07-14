import Combine
import CoreBluetooth
import Foundation

enum CubeConnectionState: String {
    case discovered = "Discovered"
    case connecting = "Connecting"
    case connected = "Connected"
    case ready = "Ready"
    case disconnected = "Disconnected"
    case failed = "Failed"
}

final class ToioCube: ObservableObject, Identifiable {
    let id: String
    let peripheralIdentifier: UUID
    let displayID: String
    let peripheral: CBPeripheral

    @Published var name: String
    @Published var rssi: Int
    @Published var connectionState: CubeConnectionState
    @Published var lastErrorMessage: String?

    var motorCharacteristic: CBCharacteristic?
    var lampCharacteristic: CBCharacteristic?
    var soundCharacteristic: CBCharacteristic?

    var isReady: Bool {
        connectionState == .ready
    }

    init(peripheral: CBPeripheral, name: String, rssi: Int) {
        self.id = peripheral.identifier.uuidString
        self.peripheralIdentifier = peripheral.identifier
        self.peripheral = peripheral
        self.name = name
        self.rssi = rssi
        self.connectionState = .discovered
        self.displayID = Self.extractDisplayID(from: name) ?? String(peripheral.identifier.uuidString.prefix(5))
    }

    func update(name: String, rssi: Int) {
        self.name = name
        self.rssi = rssi
    }

    private static func extractDisplayID(from name: String) -> String? {
        if let range = name.range(of: "toio-") {
            let suffix = name[range.upperBound...].prefix(3)
            return suffix.isEmpty ? nil : String(suffix)
        }

        if let range = name.range(of: "toio Core Cube-") {
            let suffix = name[range.upperBound...].prefix(3)
            return suffix.isEmpty ? nil : String(suffix)
        }

        return nil
    }
}
