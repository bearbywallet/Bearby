import Foundation
import CoreBluetooth

@MainActor
class BleManager: NSObject, CBCentralManagerDelegate {

    private var centralManager: CBCentralManager!
    private var transports: [UUID: BleTransport] = [:]
    private var powerOnContinuation: CheckedContinuation<Void, Error>?
    private let scanStreamController = AsyncThrowingStream<CBPeripheral, Error>.makeStream()
    
    lazy var scanStream = scanStreamController.stream

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main)
    }
    
    private func ensureBluetoothIsOn() async throws {
        if centralManager.state == .poweredOn { return }
        
        try await withCheckedThrowingContinuation { continuation in
            self.powerOnContinuation = continuation
        }
    }
    
    func getConnectedDevices() -> [CBPeripheral] {
        let ledgerServices = Devices.getBluetoothServiceUuids()
        return centralManager.retrieveConnectedPeripherals(withServices: ledgerServices)
    }

    func isSupported() -> Bool {
        return centralManager != nil
    }

    func listen() -> AsyncThrowingStream<CBPeripheral, Error> {
        Task {
            try await ensureBluetoothIsOn()
            let services = Devices.getBluetoothServiceUuids()
            centralManager.scanForPeripherals(withServices: services, options: nil)
        }
        return scanStream
    }

    func stopScan() {
        centralManager.stopScan()
    }
    
    func open(deviceId: String) async throws {
        guard let uuid = UUID(uuidString: deviceId) else {
            throw BleError.illegalArgument("Invalid device ID format")
        }
        
        if transports[uuid] != nil { return }
        
        try await ensureBluetoothIsOn()
        
        guard let peripheral = centralManager.retrievePeripherals(withIdentifiers: [uuid]).first else {
            throw BleError.deviceNotFound
        }

        let transport = BleTransport(peripheral: peripheral)
        transports[uuid] = transport
        
        centralManager.connect(peripheral, options: nil)
        
        do {
            try await transport.connect()
            try await transport.inferMtu()
        } catch {
            close(deviceId: deviceId)
            throw error
        }
    }
    
    func exchange(deviceId: String, apdu: Data) async throws -> Data {
        guard let uuid = UUID(uuidString: deviceId), let transport = transports[uuid] else {
            throw BleError.notConnected("Device not connected or transport not found")
        }
        return try await transport.exchange(apdu: apdu)
    }

    func close(deviceId: String) {
        guard let uuid = UUID(uuidString: deviceId), let transport = transports.removeValue(forKey: uuid) else {
            return
        }
        
        let transportPeripheral = transport.peripheral
        centralManager.cancelPeripheralConnection(transportPeripheral)
    }
    
    nonisolated func release() {
        Task {
            await MainActor.run {
                self.centralManager.stopScan()
                self.transports.keys.forEach { self.close(deviceId: $0.uuidString) }
                self.transports.removeAll()
            }
        }
    }

    // MARK: - CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            powerOnContinuation?.resume(returning: ())
            powerOnContinuation = nil
        } else if let cont = powerOnContinuation {
            cont.resume(throwing: BleError.permissionError("Bluetooth is not powered on. State: \(central.state.rawValue)"))
            powerOnContinuation = nil
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        scanStreamController.continuation.yield(peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        transports[peripheral.identifier]?.didConnect()
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        transports[peripheral.identifier]?.didFailToConnect(error: error)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        transports[peripheral.identifier]?.didDisconnect(error: error)
        transports.removeValue(forKey: peripheral.identifier)
    }
}
