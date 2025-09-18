import Foundation
import CoreBluetooth
import os.log

@MainActor
class BleTransport: NSObject, CBPeripheralDelegate {

    private static let logger = Logger(subsystem: "com.zilpay.ble", category: "BleTransport")

    let peripheral: CBPeripheral
    private(set) var serviceUuid: CBUUID?

    private var writeCharacteristic: CBCharacteristic?
    private var notifyCharacteristic: CBCharacteristic?

    private var connectContinuation: CheckedContinuation<Void, Error>?
    private var writeContinuation: CheckedContinuation<Void, Error>?

    private let notificationStreamController = AsyncThrowingStream<Data, Error>.makeStream()
    private lazy var notificationStream = notificationStreamController.stream

    private var mtuSize = 20

    init(peripheral: CBPeripheral) {
        Self.logger.info("Creating BleTransport for peripheral: \(peripheral.identifier.uuidString) (\(peripheral.name ?? "Unknown"))")
        self.peripheral = peripheral
        super.init()
        self.peripheral.delegate = self
        Self.logger.info("BleTransport created and delegate set")
    }

    func connect() async throws {
        Self.logger.info("Starting connection process...")
        Self.logger.info("Current peripheral state: \(self.peripheral.state.rawValue)")

        if peripheral.state == .connected {
            Self.logger.info("Peripheral already connected")
            return
        }

        Self.logger.info("Waiting for connection...")
        try await withCheckedThrowingContinuation { continuation in
            self.connectContinuation = continuation
            Self.logger.info("Connection continuation set")
        }
        Self.logger.info("Connection process completed")
    }

    func didConnect() {
        Self.logger.info("didConnect called - starting service discovery")
        let serviceUuids = Devices.getBluetoothServiceUuids()
        Self.logger.info("Discovering services: \(serviceUuids.map { $0.uuidString })")
        peripheral.discoverServices(serviceUuids)
    }

    func didFailToConnect(error: Error?) {
        let errorMsg = error?.localizedDescription ?? "Unknown connection error"
        Self.logger.error("didFailToConnect: \(errorMsg)")
        connectContinuation?.resume(throwing: error ?? BleError.notConnected("Failed to connect"))
        connectContinuation = nil
        Self.logger.info("Connection continuation cleared after failure")
    }

    func didDisconnect(error: Error?) {
        if let error = error {
            Self.logger.error("didDisconnect with error: \(error.localizedDescription)")
        } else {
            Self.logger.info("didDisconnect - clean disconnection")
        }

        let disconnectionError = error ?? BleError.notConnected("Device disconnected")
        connectContinuation?.resume(throwing: disconnectionError)
        writeContinuation?.resume(throwing: disconnectionError)
        connectContinuation = nil
        writeContinuation = nil
        notificationStreamController.continuation.finish(throwing: disconnectionError)
        Self.logger.info("All continuations cleared after disconnection")
    }

    func close() {
        Self.logger.info("Closing transport...")
        notificationStreamController.continuation.finish()
        Self.logger.info("Transport closed")
    }

    // MARK: - CBPeripheralDelegate methods

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        Self.logger.info("didDiscoverServices called")

        if let error = error {
            Self.logger.error("Service discovery failed: \(error.localizedDescription)")
            connectContinuation?.resume(throwing: error)
            connectContinuation = nil
            return
        }

        guard let services = peripheral.services else {
            Self.logger.error("No services found")
            connectContinuation?.resume(throwing: BleError.notConnected("No services found"))
            connectContinuation = nil
            return
        }

        Self.logger.info("Found \(services.count) services:")
        for (index, service) in services.enumerated() {
            Self.logger.info("  \(index + 1). \(service.uuid.uuidString)")
        }

        guard let ledgerService = services.first(where: { Devices.isLedgerService(uuid: $0.uuid) }) else {
            Self.logger.error("Ledger service not found in discovered services")
            connectContinuation?.resume(throwing: BleError.notConnected("Ledger service not found"))
            connectContinuation = nil
            return
        }

        Self.logger.info("Found Ledger service: \(ledgerService.uuid.uuidString)")
        self.serviceUuid = ledgerService.uuid

        guard let infos = Devices.getInfosForServiceUuid(uuid: ledgerService.uuid) else {
            Self.logger.error("No device info found for service: \(ledgerService.uuid.uuidString)")
            connectContinuation?.resume(throwing: BleError.notConnected("Service info not found"))
            connectContinuation = nil
            return
        }

        Self.logger.info("Discovering characteristics for service...")
        Self.logger.info("  Write UUID: \(infos.writeUuid.uuidString)")
        Self.logger.info("  Notify UUID: \(infos.notifyUuid.uuidString)")
        peripheral.discoverCharacteristics([infos.notifyUuid, infos.writeUuid], for: ledgerService)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        Self.logger.info("didDiscoverCharacteristics called for service: \(service.uuid.uuidString)")

        if let error = error {
            Self.logger.error("Characteristic discovery failed: \(error.localizedDescription)")
            connectContinuation?.resume(throwing: error)
            connectContinuation = nil
            return
        }

        guard let characteristics = service.characteristics else {
            Self.logger.error("No characteristics found")
            connectContinuation?.resume(throwing: BleError.characteristicNotFound("Characteristics not found"))
            connectContinuation = nil
            return
        }

        Self.logger.info("Found \(characteristics.count) characteristics:")
        for (index, char) in characteristics.enumerated() {
            Self.logger.info("  \(index + 1). \(char.uuid.uuidString) - Properties: \(char.properties.rawValue)")
        }

        guard let infos = Devices.getInfosForServiceUuid(uuid: service.uuid) else {
            Self.logger.error("No device info found for service: \(service.uuid.uuidString)")
            connectContinuation?.resume(throwing: BleError.notConnected("Service info not found"))
            connectContinuation = nil
            return
        }

        writeCharacteristic = characteristics.first { $0.uuid == infos.writeUuid }
        notifyCharacteristic = characteristics.first { $0.uuid == infos.notifyUuid }

        if let writeChar = writeCharacteristic {
            Self.logger.info("Write characteristic found: \(writeChar.uuid.uuidString)")
        } else {
            Self.logger.error("Write characteristic not found")
            connectContinuation?.resume(throwing: BleError.characteristicNotFound("Write characteristic"))
            connectContinuation = nil
            return
        }

        guard let notifyChar = notifyCharacteristic else {
            Self.logger.error("Notify characteristic not found")
            connectContinuation?.resume(throwing: BleError.characteristicNotFound("Notify characteristic"))
            connectContinuation = nil
            return
        }

        Self.logger.info("Notify characteristic found: \(notifyChar.uuid.uuidString)")
        Self.logger.info("Enabling notifications...")
        peripheral.setNotifyValue(true, for: notifyChar)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        Self.logger.info("didUpdateNotificationState for characteristic: \(characteristic.uuid.uuidString)")

        if characteristic.uuid == notifyCharacteristic?.uuid {
            if let error = error {
                Self.logger.error("Failed to enable notifications: \(error.localizedDescription)")
                connectContinuation?.resume(throwing: error)
            } else if characteristic.isNotifying {
                Self.logger.info("Notifications enabled successfully")
                connectContinuation?.resume(returning: ())
            } else {
                Self.logger.error("Notifications not enabled")
                connectContinuation?.resume(throwing: BleError.notConnected("Failed to enable notifications"))
            }
            connectContinuation = nil
            Self.logger.info("Connection process completed")
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        Self.logger.info("didWriteValue for characteristic: \(characteristic.uuid.uuidString)")

        if let error = error {
            Self.logger.error("Write failed: \(error.localizedDescription)")
            writeContinuation?.resume(throwing: BleError.writeFailed(error.localizedDescription))
        } else {
            Self.logger.info("Write successful")
            writeContinuation?.resume(returning: ())
        }
        writeContinuation = nil
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        Self.logger.info("didUpdateValue for characteristic: \(characteristic.uuid.uuidString)")

        if let error = error {
            Self.logger.error("Value update failed: \(error.localizedDescription)")
            notificationStreamController.continuation.finish(throwing: error)
            return
        }

        if let value = characteristic.value {
            Self.logger.info("Received data (\(value.count) bytes): \(value.prefix(20).map { String(format: "%02x", $0) }.joined())\(value.count > 20 ? "..." : "")")
            notificationStreamController.continuation.yield(value)
        } else {
            Self.logger.warning("Received notification with no data")
        }
    }

    // MARK: - Public API

    func inferMtu() async throws {
        Self.logger.info("Starting MTU inference...")

        let systemMtu = self.peripheral.maximumWriteValueLength(for: .withResponse)
        Self.logger.info("System MTU (with response): \(systemMtu)")

        self.mtuSize = max(systemMtu, 20)
        Self.logger.info("Initial MTU set to: \(self.mtuSize)")

        let inferMtuCommand = Data([0x08, 0, 0, 0, 0])
        Self.logger.info("Sending MTU inference command: \(inferMtuCommand.map { String(format: "%02x", $0) }.joined())")

        try await withTimeout(5.0) {
            Self.logger.info("Setting up MTU response listener...")
            let responseTask = Task { [weak self] in
                guard let self = self else {
                    Self.logger.error("Transport deallocated during MTU inference")
                    throw BleError.notConnected("Transport deallocated")
                }

                Self.logger.info("Listening for MTU response...")
                for try await value in self.notificationStream {
                    Self.logger.info("Received notification during MTU inference (\(value.count) bytes): \(value.prefix(10).map { String(format: "%02x", $0) }.joined())")
                    if value.count > 5 && value[0] == 0x08 {
                        Self.logger.info("Found MTU response packet")
                        return value
                    } else {
                        Self.logger.info("Skipping non-MTU packet")
                    }
                }
                Self.logger.error("No MTU response received")
                throw BleError.notConnected("No MTU response received")
            }

            Self.logger.info("Waiting 50ms before sending command...")
            try await Task.sleep(nanoseconds: 50_000_000)

            Self.logger.info("Writing MTU inference command...")
            try await self.write(data: inferMtuCommand, withResponse: true)

            Self.logger.info("Waiting for MTU response...")
            let response = try await responseTask.value

            let newMtu = Int(response[5])
            Self.logger.info("Device reported MTU: \(newMtu)")
            self.mtuSize = newMtu
            Self.logger.info("MTU inference completed, final MTU: \(self.mtuSize)")

            responseTask.cancel()
        }
    }

    func exchange(apdu: Data) async throws -> Data {
        Self.logger.info("Starting APDU exchange...")
        Self.logger.info("APDU to send (\(apdu.count) bytes): \(apdu.map { String(format: "%02x", $0) }.joined())")
        Self.logger.info("Using MTU size: \(self.mtuSize)")

        return try await withTimeout(30.0) {
            Self.logger.info("Setting up response stream...")
            let responseStream = receiveApdu(notificationStream: self.notificationStream)

            let responseTask = Task {
                Self.logger.info("Waiting for APDU response...")
                for try await data in responseStream {
                    Self.logger.info("Received APDU response (\(data.count) bytes): \(data.map { String(format: "%02x", $0) }.joined())")
                    return data
                }
                Self.logger.error("No response received during exchange")
                throw BleError.notConnected("No response received during exchange")
            }

            Self.logger.info("Starting APDU send process...")
            try await sendApdu(write: { [weak self] data in
                guard let self = self else {
                    Self.logger.error("Transport deallocated during send")
                    throw BleError.notConnected("Transport deallocated")
                }
                Self.logger.info("Writing chunk (\(data.count) bytes): \(data.map { String(format: "%02x", $0) }.joined())")
                try await self.write(data: data, withResponse: true)
                Self.logger.info("Chunk written successfully")
            }, apdu: apdu, mtuSize: self.mtuSize)

            Self.logger.info("APDU send completed, waiting for response...")
            let response = try await responseTask.value
            responseTask.cancel()

            Self.logger.info("APDU exchange completed successfully")
            return response
        }
    }

    private func write(data: Data, withResponse: Bool) async throws {
        Self.logger.info("Writing data (with response: \(withResponse))")
        Self.logger.info("Data (\(data.count) bytes): \(data.map { String(format: "%02x", $0) }.joined())")

        guard let characteristic = writeCharacteristic else {
            Self.logger.error("Write characteristic not available")
            throw BleError.characteristicNotFound("Write")
        }

        Self.logger.info("Using characteristic: \(characteristic.uuid.uuidString)")

        if !withResponse {
            Self.logger.info("Writing without response...")
            peripheral.writeValue(data, for: characteristic, type: .withoutResponse)
            Self.logger.info("Write without response completed")
            return
        }

        Self.logger.info("Writing with response...")
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.writeContinuation = continuation
            Self.logger.info("Write continuation set")
            self.peripheral.writeValue(data, for: characteristic, type: .withResponse)
        }
        Self.logger.info("Write with response completed")
    }
}

extension BleTransport {
    private func withTimeout<T>(_ seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        Self.logger.info("Starting operation with \(seconds)s timeout")

        let result = try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                Self.logger.info("Starting main operation...")
                let result = try await operation()
                Self.logger.info("Main operation completed")
                return result
            }

            group.addTask {
                Self.logger.info("Starting timeout timer...")
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                Self.logger.error("Operation timed out after \(seconds)s")
                throw BleError.notConnected("Operation timed out")
            }

            guard let result = try await group.next() else {
                Self.logger.error("No result from task group")
                throw BleError.notConnected("No result")
            }

            Self.logger.info("Operation completed within timeout")
            group.cancelAll()
            return result
        }

        Self.logger.info("Timeout operation completed successfully")
        return result
    }
}
