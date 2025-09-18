import Foundation
import CoreBluetooth

@MainActor
class BleTransport: NSObject, CBPeripheralDelegate {
    
    private let peripheral: CBPeripheral
    private(set) var serviceUuid: CBUUID?
    
    private var writeCharacteristic: CBCharacteristic?
    private var notifyCharacteristic: CBCharacteristic?
    
    // Используем 'Continuation' для превращения колбеков в async/await
    private var connectContinuation: CheckedContinuation<Void, Error>?
    private var writeContinuation: CheckedContinuation<Void, Error>?
    
    private let notificationStreamController = AsyncThrowingStream<Data, Error>.makeStream()
    private lazy var notificationStream = notificationStreamController.stream
    
    private var mtuSize = 20
    
    init(peripheral: CBPeripheral) {
        self.peripheral = peripheral
        super.init()
        self.peripheral.delegate = self
    }
    
    func connect() async throws {
        if peripheral.state == .connected { return }
        
        try await withCheckedThrowingContinuation { continuation in
            self.connectContinuation = continuation
        }
    }
    
    func didConnect() {
        peripheral.discoverServices(Devices.getBluetoothServiceUuids())
    }
    
    func didFailToConnect(error: Error?) {
        connectContinuation?.resume(throwing: error ?? BleError.notConnected("Failed to connect"))
        connectContinuation = nil
    }
    
    func didDisconnect(error: Error?) {
        let disconnectionError = error ?? BleError.notConnected("Device disconnected")
        connectContinuation?.resume(throwing: disconnectionError)
        writeContinuation?.resume(throwing: disconnectionError)
        connectContinuation = nil
        writeContinuation = nil
        notificationStreamController.continuation.finish(throwing: disconnectionError)
    }

    func close() {
        // BleManager call cancelPeripheralConnection
    }
    
    // MARK: - CBPeripheralDelegate methods
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services, let ledgerService = services.first(where: { Devices.isLedgerService(uuid: $0.uuid) }) else {
            connectContinuation?.resume(throwing: BleError.notConnected("Ledger service not found"))
            connectContinuation = nil
            return
        }
        
        self.serviceUuid = ledgerService.uuid
        let infos = Devices.getInfosForServiceUuid(uuid: ledgerService.uuid)!
        peripheral.discoverCharacteristics([infos.notifyUuid, infos.writeUuid], for: ledgerService)
    }
    

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else {
            connectContinuation?.resume(throwing: BleError.characteristicNotFound("Characteristics not found"))
            connectContinuation = nil
            return
        }
        
        let infos = Devices.getInfosForServiceUuid(uuid: service.uuid)!
        writeCharacteristic = characteristics.first { $0.uuid == infos.writeUuid }
        notifyCharacteristic = characteristics.first { $0.uuid == infos.notifyUuid }
        
        if let notifyChar = notifyCharacteristic {
            peripheral.setNotifyValue(true, for: notifyChar)
        } else {
            connectContinuation?.resume(throwing: BleError.characteristicNotFound("Notify"))
            connectContinuation = nil
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.uuid == notifyCharacteristic?.uuid {
            if error == nil && characteristic.isNotifying {
                connectContinuation?.resume(returning: ())
            } else {
                connectContinuation?.resume(throwing: error ?? BleError.notConnected("Failed to enable notifications"))
            }
            connectContinuation = nil
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            writeContinuation?.resume(throwing: BleError.writeFailed(error.localizedDescription))
        } else {
            writeContinuation?.resume(returning: ())
        }
        writeContinuation = nil
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let value = characteristic.value {
            notificationStreamController.continuation.yield(value)
        }
    }
    
    // MARK: - Public API
    
    func inferMtu() async throws {
        let inferMtuCommand = Data([0x08, 0, 0, 0, 0])

        async let firstResponse: Data = {
            for try await value in notificationStream {
                if value.count > 5 && value[0] == 0x08 {
                    return value
                }
            }
            throw BleError.notConnected("No MTU response")
        }()

        try await write(data: inferMtuCommand, withResponse: true)
        
        let response = try await firstResponse
        let newMtu = Int(response[5])
        mtuSize = newMtu
    }

    func exchange(apdu: Data) async throws -> Data {
        let responseStream = receiveApdu(notificationStream: notificationStream)

        async let response: Data = {
             for try await data in responseStream {
                 return data
             }
             throw BleError.notConnected("No response received during exchange")
        }()
        
        try await sendApdu(write: { data in
            try await self.write(data: data, withResponse: true)
        }, apdu: apdu, mtuSize: mtuSize)
        
        return try await response
    }
    
    private func write(data: Data, withResponse: Bool) async throws {
        guard let characteristic = writeCharacteristic else { throw BleError.characteristicNotFound("Write") }
        
        if !withResponse {
            peripheral.writeValue(data, for: characteristic, type: .withoutResponse)
            return
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.writeContinuation = continuation
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
        }
    }
}
