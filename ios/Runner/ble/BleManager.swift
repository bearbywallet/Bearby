import Foundation
import CoreBluetooth
import os.log

@MainActor
class BleManager: NSObject, CBCentralManagerDelegate {

    private static let logger = Logger(subsystem: "com.zilpay.ble", category: "BleManager")
    
    private var centralManager: CBCentralManager!
    private var transports: [UUID: BleTransport] = [:]
    private var powerOnContinuation: CheckedContinuation<Void, Error>?
    private let scanStreamController = AsyncThrowingStream<CBPeripheral, Error>.makeStream()
    
    lazy var scanStream = scanStreamController.stream

    override init() {
        super.init()
        Self.logger.info("BleManager initializing...")
        centralManager = CBCentralManager(delegate: self, queue: .main)
        Self.logger.info("BleManager initialized with CBCentralManager")
    }
    
    private func ensureBluetoothIsOn() async throws {
        Self.logger.info("Checking Bluetooth state: \(self.centralManager.state.rawValue)")
        
        if centralManager.state == .poweredOn {
            Self.logger.info("Bluetooth is already powered on")
            return
        }
        
        Self.logger.info("Waiting for Bluetooth to power on...")
        try await withCheckedThrowingContinuation { continuation in
            self.powerOnContinuation = continuation
        }
        Self.logger.info("Bluetooth powered on successfully")
    }
    
    func getConnectedDevices() -> [CBPeripheral] {
        Self.logger.info("Getting connected devices...")
        let ledgerServices = Devices.getBluetoothServiceUuids()
        Self.logger.info("Scanning for services: \(ledgerServices.map { $0.uuidString })")
        
        let connectedDevices = centralManager.retrieveConnectedPeripherals(withServices: ledgerServices)
        Self.logger.info("Found \(connectedDevices.count) connected devices:")
        
        for (index, device) in connectedDevices.enumerated() {
            Self.logger.info("  \(index + 1). ID: \(device.identifier.uuidString), Name: \(device.name ?? "Unknown"), State: \(device.state.rawValue)")
        }
        
        return connectedDevices
    }

    func isSupported() -> Bool {
        let supported = centralManager != nil
        Self.logger.info("BLE support check: \(supported)")
        return supported
    }

    func listen() -> AsyncThrowingStream<CBPeripheral, Error> {
        Self.logger.info("Starting to listen for devices...")
        Task {
            do {
                try await ensureBluetoothIsOn()
                let services = Devices.getBluetoothServiceUuids()
                Self.logger.info("Starting scan for services: \(services.map { $0.uuidString })")
                centralManager.scanForPeripherals(withServices: services, options: nil)
                Self.logger.info("Scan started successfully")
            } catch {
                Self.logger.error("Failed to start scan: \(error.localizedDescription)")
            }
        }
        return scanStream
    }

    func stopScan() {
        Self.logger.info("Stopping scan...")
        centralManager.stopScan()
        Self.logger.info("Scan stopped")
    }
    
    func open(deviceId: String) async throws {
        Self.logger.info("Opening device with ID: \(deviceId)")
        
        guard let uuid = UUID(uuidString: deviceId) else {
            Self.logger.error("Invalid device ID format: \(deviceId)")
            throw BleError.illegalArgument("Invalid device ID format")
        }
        
        if transports[uuid] != nil {
            Self.logger.info("Device \(deviceId) is already connected")
            return
        }
        
        try await ensureBluetoothIsOn()
        
        Self.logger.info("Retrieving peripheral with ID: \(uuid.uuidString)")
        guard let peripheral = centralManager.retrievePeripherals(withIdentifiers: [uuid]).first else {
            Self.logger.error("Peripheral not found for ID: \(deviceId)")
            throw BleError.deviceNotFound
        }
        
        Self.logger.info("Found peripheral: \(peripheral.name ?? "Unknown") (\(peripheral.identifier.uuidString))")
        Self.logger.info("Peripheral state: \(peripheral.state.rawValue)")

        let transport = BleTransport(peripheral: peripheral)
        transports[uuid] = transport
        Self.logger.info("Created transport for device: \(deviceId)")
        
        Self.logger.info("Connecting to peripheral...")
        centralManager.connect(peripheral, options: nil)
        
        do {
            Self.logger.info("Waiting for connection...")
            try await transport.connect()
            Self.logger.info("Connection established")
            
            Self.logger.info("Inferring MTU...")
            try await transport.inferMtu()
            Self.logger.info("MTU configured successfully")
            
            Self.logger.info("Device \(deviceId) opened successfully")
        } catch {
            Self.logger.error("Failed to open device \(deviceId): \(error.localizedDescription)")
            close(deviceId: deviceId)
            throw error
        }
    }
    
    func exchange(deviceId: String, apdu: Data) async throws -> Data {
        Self.logger.info("Exchange started for device: \(deviceId)")
        Self.logger.info("APDU data (\(apdu.count) bytes): \(apdu.map { String(format: "%02x", $0) }.joined())")
        
        guard let uuid = UUID(uuidString: deviceId), let transport = transports[uuid] else {
            Self.logger.error("Transport not found for device: \(deviceId)")
            throw BleError.notConnected("Device not connected or transport not found")
        }
        
        do {
            let response = try await transport.exchange(apdu: apdu)
            Self.logger.info("Exchange completed successfully for device: \(deviceId)")
            Self.logger.info("Response data (\(response.count) bytes): \(response.map { String(format: "%02x", $0) }.joined())")
            return response
        } catch {
            Self.logger.error("Exchange failed for device \(deviceId): \(error.localizedDescription)")
            throw error
        }
    }

    func close(deviceId: String) {
        Self.logger.info("Closing device: \(deviceId)")
        
        guard let uuid = UUID(uuidString: deviceId), let transport = transports.removeValue(forKey: uuid) else {
            Self.logger.warning("No transport found for device: \(deviceId)")
            return
        }
        
        let transportPeripheral = transport.peripheral
        Self.logger.info("Disconnecting peripheral: \(transportPeripheral.identifier.uuidString)")
        centralManager.cancelPeripheralConnection(transportPeripheral)
        Self.logger.info("Device \(deviceId) closed")
    }
    
    nonisolated func release() {
        Self.logger.info("Releasing BleManager resources...")
        Task {
            await MainActor.run {
                Self.logger.info("Stopping scan and closing all connections...")
                self.centralManager.stopScan()
                self.transports.keys.forEach { self.close(deviceId: $0.uuidString) }
                self.transports.removeAll()
                Self.logger.info("BleManager resources released")
            }
        }
    }

    // MARK: - CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Self.logger.info("Central manager state changed to: \(central.state.rawValue)")
        
        switch central.state {
        case .unknown:
            Self.logger.info("State: Unknown")
        case .resetting:
            Self.logger.info("State: Resetting")
        case .unsupported:
            Self.logger.error("State: Unsupported")
        case .unauthorized:
            Self.logger.error("State: Unauthorized")
        case .poweredOff:
            Self.logger.info("State: Powered Off")
        case .poweredOn:
            Self.logger.info("State: Powered On")
        @unknown default:
            Self.logger.warning("Unknown state: \(central.state.rawValue)")
        }
        
        if central.state == .poweredOn {
            Self.logger.info("Bluetooth ready, resuming power on continuation")
            powerOnContinuation?.resume(returning: ())
            powerOnContinuation = nil
        } else if let cont = powerOnContinuation {
            Self.logger.error("Bluetooth not ready, failing power on continuation")
            cont.resume(throwing: BleError.permissionError("Bluetooth is not powered on. State: \(central.state.rawValue)"))
            powerOnContinuation = nil
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        Self.logger.info("Discovered peripheral:")
        Self.logger.info("  Name: \(peripheral.name ?? "Unknown")")
        Self.logger.info("  ID: \(peripheral.identifier.uuidString)")
        Self.logger.info("  RSSI: \(RSSI.intValue) dBm")
        Self.logger.info("  Advertisement data: \(advertisementData)")
        
        scanStreamController.continuation.yield(peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        Self.logger.info("Connected to peripheral: \(peripheral.identifier.uuidString) (\(peripheral.name ?? "Unknown"))")
        transports[peripheral.identifier]?.didConnect()
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        let errorMsg = error?.localizedDescription ?? "Unknown error"
        Self.logger.error("Failed to connect to peripheral \(peripheral.identifier.uuidString): \(errorMsg)")
        transports[peripheral.identifier]?.didFailToConnect(error: error)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let error = error {
            Self.logger.error("Disconnected from peripheral \(peripheral.identifier.uuidString) with error: \(error.localizedDescription)")
        } else {
            Self.logger.info("Disconnected from peripheral: \(peripheral.identifier.uuidString)")
        }
        
        transports[peripheral.identifier]?.didDisconnect(error: error)
        transports.removeValue(forKey: peripheral.identifier)
        Self.logger.info("Removed transport for peripheral: \(peripheral.identifier.uuidString)")
    }
}
