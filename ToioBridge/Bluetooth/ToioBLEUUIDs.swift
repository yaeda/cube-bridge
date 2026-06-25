import CoreBluetooth

enum ToioBLEUUIDs {
    static let service = CBUUID(string: "10B20100-5B3B-4571-9508-CF3EFCD7BBAE")
    static let motor = CBUUID(string: "10B20102-5B3B-4571-9508-CF3EFCD7BBAE")
    static let lamp = CBUUID(string: "10B20103-5B3B-4571-9508-CF3EFCD7BBAE")
    static let sound = CBUUID(string: "10B20104-5B3B-4571-9508-CF3EFCD7BBAE")

    static let commandCharacteristics = [motor, lamp, sound]
}
