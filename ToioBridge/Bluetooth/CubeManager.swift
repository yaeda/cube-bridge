import Combine
import CoreBluetooth
import Foundation

@MainActor
final class CubeManager: NSObject, ObservableObject {
    static let shared = CubeManager()

    @Published private(set) var bluetoothStateDescription = "Unknown"
    @Published private(set) var authorizationDescription = "Unknown"
    @Published private(set) var isScanning = false
    @Published private(set) var scanModeDescription = "Idle"
    @Published private(set) var lastScanStartedAt: Date?
    @Published private(set) var discoveryCallbackCount = 0
    @Published private(set) var retrievedPeripheralCount = 0
    @Published private(set) var lastDiscoveryDescription = "None"
    @Published private(set) var discoveredCubes: [ToioCube] = []
    @Published private(set) var connectedCubes: [ToioCube] = []
    @Published var lastErrorMessage: String?

    private var centralManager: CBCentralManager!
    private var cubesByPeripheralID: [UUID: ToioCube] = [:]
    private var pendingWrites: [String: CheckedContinuation<Void, Error>] = [:]
    private let commandQueue = CubeCommandQueue()

    private override init() {
        super.init()
        authorizationDescription = Self.describeAuthorization(CBCentralManager.authorization)
        centralManager = CBCentralManager(
            delegate: self,
            queue: .main,
            options: [CBCentralManagerOptionShowPowerAlertKey: true]
        )
    }

    func startScanning() {
        guard centralManager.state == .poweredOn else {
            lastErrorMessage = ToioBridgeError.bluetoothUnavailable(bluetoothStateDescription).localizedDescription
            return
        }

        isScanning = true
        scanModeDescription = "toio service UUID"
        lastScanStartedAt = Date()
        discoveryCallbackCount = 0
        retrievedPeripheralCount = 0
        lastDiscoveryDescription = "None"
        lastErrorMessage = nil
        loadConnectedServicePeripherals()
        centralManager.scanForPeripherals(
            withServices: [ToioBLEUUIDs.service],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
    }

    func stopScanning() {
        centralManager.stopScan()
        isScanning = false
        scanModeDescription = "Idle"
    }

    func connect(_ cube: ToioCube) {
        cube.connectionState = .connecting
        centralManager.connect(cube.peripheral, options: nil)
    }

    func disconnect(_ cube: ToioCube) {
        centralManager.cancelPeripheralConnection(cube.peripheral)
    }

    func move(cubeID: String? = nil, left: Int, right: Int, durationMs: Int) async throws {
        let cube = try connectedCube(for: cubeID)
        let command = try CubeCommand.move(left: left, right: right, durationMs: durationMs)
        try await performExclusiveCommand(on: cube) {
            try await write(command, to: cube)
        }
    }

    func stop(cubeID: String? = nil) async throws {
        let cube = try connectedCube(for: cubeID)
        try await performExclusiveCommand(on: cube) {
            try await write(.stop(), to: cube)
        }
    }

    func setLamp(cubeID: String? = nil, red: Int, green: Int, blue: Int, durationMs: Int) async throws {
        let cube = try connectedCube(for: cubeID)
        let command = try CubeCommand.setLamp(red: red, green: green, blue: blue, durationMs: durationMs)
        try await performExclusiveCommand(on: cube) {
            try await write(command, to: cube)
        }
    }

    func turnOffLamp(cubeID: String? = nil) async throws {
        let cube = try connectedCube(for: cubeID)
        try await performExclusiveCommand(on: cube) {
            try await write(.turnOffLamp(), to: cube)
        }
    }

    func playSoundEffect(cubeID: String? = nil, id: Int, volume: Int = 255) async throws {
        let cube = try connectedCube(for: cubeID)
        let command = try CubeCommand.playSoundEffect(id: id, volume: volume)
        try await performExclusiveCommand(on: cube) {
            try await write(command, to: cube)
        }
    }

    func identify(cubeID: String? = nil) async throws {
        let cube = try connectedCube(for: cubeID)

        try await performExclusiveCommand(on: cube) {
            try await write(try CubeCommand.playSoundEffect(id: 0), to: cube)
            try await write(try CubeCommand.setLamp(red: 0, green: 160, blue: 255, durationMs: 1000), to: cube)
            try await write(try CubeCommand.move(left: 30, right: -30, durationMs: 180), to: cube)
            try await Task.sleep(nanoseconds: 180_000_000)
            try await write(try CubeCommand.move(left: -30, right: 30, durationMs: 180), to: cube)
            try await Task.sleep(nanoseconds: 180_000_000)
            try await write(.stop(), to: cube)
        }
    }

    func connectedCubeSnapshots() -> [CubeSnapshot] {
        connectedCubes.map {
            CubeSnapshot(id: $0.id, name: $0.name, displayID: $0.displayID)
        }
    }

    func connectedCube(for cubeID: String?) throws -> ToioCube {
        guard centralManager.state == .poweredOn else {
            throw bluetoothError(for: centralManager.state)
        }

        if let cubeID, !cubeID.isEmpty {
            guard let cube = connectedCubes.first(where: { $0.id == cubeID }) else {
                throw ToioBridgeError.cubeNotFound(cubeID)
            }
            return cube
        }

        guard let cube = connectedCubes.first else {
            throw ToioBridgeError.cubeNotConnected
        }

        return cube
    }

    private func write(_ command: CubeCommand, to cube: ToioCube) async throws {
        guard cube.isReady || cube.connectionState == .connected else {
            throw ToioBridgeError.cubeNotConnected
        }

        let characteristic = try ToioCommandWriter.characteristic(for: command, cube: cube)
        let type = ToioCommandWriter.writeType(for: characteristic)

        switch type {
        case .withResponse:
            let key = pendingWriteKey(for: cube.peripheral, characteristic: characteristic)
            try await withCheckedThrowingContinuation { continuation in
                pendingWrites[key] = continuation
                cube.peripheral.writeValue(command.data, for: characteristic, type: .withResponse)
            }
        case .withoutResponse:
            cube.peripheral.writeValue(command.data, for: characteristic, type: .withoutResponse)
        @unknown default:
            throw ToioBridgeError.writeFailed("Unsupported Core Bluetooth write type.")
        }
    }

    private func performExclusiveCommand<T>(on cube: ToioCube, operation: () async throws -> T) async throws -> T {
        try await commandQueue.perform(cubeID: cube.id, operation: operation)
    }

    private func handleDiscovered(peripheral: CBPeripheral, advertisementData: [String: Any], rssi: NSNumber) {
        let advertisedName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        let name = advertisedName ?? peripheral.name ?? "toio Core Cube"
        discoveryCallbackCount += 1
        lastDiscoveryDescription = "\(name), RSSI \(rssi.intValue)"

        addOrUpdateCube(peripheral: peripheral, name: name, rssi: rssi.intValue)
    }

    private func loadConnectedServicePeripherals() {
        let peripherals = centralManager.retrieveConnectedPeripherals(withServices: [ToioBLEUUIDs.service])
        retrievedPeripheralCount = peripherals.count

        for peripheral in peripherals {
            let name = peripheral.name ?? "toio Core Cube"
            lastDiscoveryDescription = "Retrieved \(name)"
            addOrUpdateCube(peripheral: peripheral, name: name, rssi: 0)

            if peripheral.state == .connected, let cube = cubesByPeripheralID[peripheral.identifier] {
                cube.connectionState = .connected
                peripheral.delegate = self
                peripheral.discoverServices([ToioBLEUUIDs.service])
            }
        }

        refreshConnectedCubes()
    }

    private func addOrUpdateCube(peripheral: CBPeripheral, name: String, rssi: Int) {
        if let cube = cubesByPeripheralID[peripheral.identifier] {
            cube.update(name: name, rssi: rssi)
            return
        }

        let cube = ToioCube(peripheral: peripheral, name: name, rssi: rssi)
        cubesByPeripheralID[peripheral.identifier] = cube
        discoveredCubes.append(cube)
    }

    private func refreshConnectedCubes() {
        connectedCubes = discoveredCubes.filter { cube in
            cube.connectionState == .connected || cube.connectionState == .ready
        }
    }

    private func pendingWriteKey(for peripheral: CBPeripheral, characteristic: CBCharacteristic) -> String {
        "\(peripheral.identifier.uuidString)-\(characteristic.uuid.uuidString)"
    }

    private func bluetoothError(for state: CBManagerState) -> ToioBridgeError {
        authorizationDescription = Self.describeAuthorization(CBCentralManager.authorization)

        switch CBCentralManager.authorization {
        case .denied, .restricted:
            return .bluetoothPermissionDenied
        default:
            break
        }

        switch state {
        case .poweredOff:
            return .bluetoothPoweredOff
        default:
            return .bluetoothUnavailable(Self.describeState(state))
        }
    }

    private static func describeState(_ state: CBManagerState) -> String {
        switch state {
        case .unknown:
            return "Unknown"
        case .resetting:
            return "Resetting"
        case .unsupported:
            return "Unsupported"
        case .unauthorized:
            return "Unauthorized"
        case .poweredOff:
            return "Powered Off"
        case .poweredOn:
            return "Powered On"
        @unknown default:
            return "Unknown"
        }
    }

    private static func describeAuthorization(_ authorization: CBManagerAuthorization) -> String {
        switch authorization {
        case .allowedAlways:
            return "Allowed"
        case .denied:
            return "Denied"
        case .restricted:
            return "Restricted"
        case .notDetermined:
            return "Not Determined"
        @unknown default:
            return "Unknown"
        }
    }
}

extension CubeManager: CBCentralManagerDelegate {
    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Task { @MainActor in
            bluetoothStateDescription = Self.describeState(central.state)
            authorizationDescription = Self.describeAuthorization(CBCentralManager.authorization)

            if central.state == .poweredOn {
                lastErrorMessage = nil
                startScanning()
            } else {
                isScanning = false
                lastErrorMessage = bluetoothError(for: central.state).localizedDescription
            }
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi: NSNumber
    ) {
        Task { @MainActor in
            handleDiscovered(peripheral: peripheral, advertisementData: advertisementData, rssi: rssi)
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        Task { @MainActor in
            guard let cube = cubesByPeripheralID[peripheral.identifier] else {
                return
            }

            cube.connectionState = .connected
            cube.lastErrorMessage = nil
            peripheral.delegate = self
            peripheral.discoverServices([ToioBLEUUIDs.service])
            refreshConnectedCubes()
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        Task { @MainActor in
            guard let cube = cubesByPeripheralID[peripheral.identifier] else {
                return
            }

            cube.connectionState = .failed
            cube.lastErrorMessage = error?.localizedDescription ?? "Failed to connect."
            refreshConnectedCubes()
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        Task { @MainActor in
            guard let cube = cubesByPeripheralID[peripheral.identifier] else {
                return
            }

            cube.connectionState = .disconnected
            cube.lastErrorMessage = error?.localizedDescription
            cube.motorCharacteristic = nil
            cube.lampCharacteristic = nil
            cube.soundCharacteristic = nil
            refreshConnectedCubes()
        }
    }
}

extension CubeManager: CBPeripheralDelegate {
    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        Task { @MainActor in
            guard let cube = cubesByPeripheralID[peripheral.identifier] else {
                return
            }

            if let error {
                cube.lastErrorMessage = error.localizedDescription
                return
            }

            guard let service = peripheral.services?.first(where: { $0.uuid == ToioBLEUUIDs.service }) else {
                cube.lastErrorMessage = ToioBridgeError.characteristicNotFound("toio service").localizedDescription
                return
            }

            peripheral.discoverCharacteristics(ToioBLEUUIDs.commandCharacteristics, for: service)
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        Task { @MainActor in
            guard let cube = cubesByPeripheralID[peripheral.identifier] else {
                return
            }

            if let error {
                cube.lastErrorMessage = error.localizedDescription
                return
            }

            for characteristic in service.characteristics ?? [] {
                switch characteristic.uuid {
                case ToioBLEUUIDs.motor:
                    cube.motorCharacteristic = characteristic
                case ToioBLEUUIDs.lamp:
                    cube.lampCharacteristic = characteristic
                case ToioBLEUUIDs.sound:
                    cube.soundCharacteristic = characteristic
                default:
                    break
                }
            }

            if cube.motorCharacteristic != nil, cube.lampCharacteristic != nil {
                cube.connectionState = .ready
                cube.lastErrorMessage = nil
            }
            refreshConnectedCubes()
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        Task { @MainActor in
            let key = pendingWriteKey(for: peripheral, characteristic: characteristic)
            guard let continuation = pendingWrites.removeValue(forKey: key) else {
                return
            }

            if let error {
                continuation.resume(throwing: ToioBridgeError.writeFailed(error.localizedDescription))
            } else {
                continuation.resume()
            }
        }
    }
}

struct CubeSnapshot: Equatable, Sendable {
    let id: String
    let name: String
    let displayID: String
}
