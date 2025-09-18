import Flutter
import UIKit
import CoreBluetooth
import os.log

@MainActor
public class LedgerBlePlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    
    private static let logger = Logger(subsystem: "com.zilpay.ble", category: "LedgerBlePlugin")
    
    private let bleManager = BleManager()
    private var eventSink: FlutterEventSink?
    private var scanTask: Task<Void, Never>?

    public static func register(with registrar: FlutterPluginRegistrar) {
        logger.info("Registering LedgerBlePlugin...")
        
        let channel = FlutterMethodChannel(name: "ledger.com/ble", binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: "ledger.com/ble/events", binaryMessenger: registrar.messenger())
        let instance = LedgerBlePlugin()
        
        registrar.addMethodCallDelegate(instance, channel: channel)
        eventChannel.setStreamHandler(instance)
        registrar.addApplicationDelegate(instance)
        
        logger.info("LedgerBlePlugin registered successfully")
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        Self.logger.info("Method call received: \(call.method)")
        Self.logger.info("Arguments: \(String(describing: call.arguments))")
        
        Task {
            do {
                let res = try await handleMethodCall(call)
                Self.logger.info("Method \(call.method) completed successfully")
                result(res)
            } catch {
                Self.logger.error("Method \(call.method) failed: \(error.localizedDescription)")
                let flutterError = FlutterError(
                    code: String(describing: type(of: error)),
                    message: error.localizedDescription,
                    details: nil)
                result(flutterError)
            }
        }
    }

    private func handleMethodCall(_ call: FlutterMethodCall) async throws -> Any? {
        Self.logger.info("Handling method: \(call.method)")
        
        switch call.method {
        case "getConnectedDevices":
            Self.logger.info("Getting connected devices...")
            let devices = bleManager.getConnectedDevices().map { peripheral -> [String: Any] in
                let deviceInfo = [
                    "id": peripheral.identifier.uuidString,
                    "name": peripheral.name ?? "Unknown",
                    "serviceUUID": ""
                ]
                Self.logger.info("Found connected device: \(deviceInfo)")
                return deviceInfo
            }
            Self.logger.info("Returning \(devices.count) connected devices")
            return devices
            
        case "startScan":
            Self.logger.info("Starting scan...")
            startScan()
            Self.logger.info("Scan started")
            return nil
            
        case "stopScan":
            Self.logger.info("Stopping scan...")
            stopScan()
            Self.logger.info("Scan stopped")
            return nil
            
        case "isSupported":
            let supported = bleManager.isSupported()
            Self.logger.info("BLE support check result: \(supported)")
            return supported
            
        case "openDevice":
            guard let deviceId = call.arguments as? String else {
                Self.logger.error("Invalid device ID argument")
                throw BleError.illegalArgument("Device ID must be a String")
            }
            Self.logger.info("Opening device: \(deviceId)")
            try await bleManager.open(deviceId: deviceId)
            Self.logger.info("Device opened successfully: \(deviceId)")
            return nil
            
        case "exchange":
            guard let args = call.arguments as? [String: Any],
                  let deviceId = args["deviceId"] as? String,
                  let apdu = args["apdu"] as? FlutterStandardTypedData else {
                Self.logger.error("Invalid exchange arguments")
                throw BleError.illegalArgument("Invalid arguments for exchange")
            }
            
            Self.logger.info("Starting exchange for device: \(deviceId)")
            Self.logger.info("APDU size: \(apdu.data.count) bytes")
            
            let response = try await bleManager.exchange(deviceId: deviceId, apdu: apdu.data)
            Self.logger.info("Exchange completed successfully")
            Self.logger.info("Response size: \(response.count) bytes")
            
            return FlutterStandardTypedData(bytes: response)
            
        case "closeDevice":
             guard let args = call.arguments as? [String: Any],
                  let deviceId = args["deviceId"] as? String else {
                Self.logger.error("Invalid close device arguments")
                throw BleError.illegalArgument("Device ID must be a String")
            }
            Self.logger.info("Closing device: \(deviceId)")
            bleManager.close(deviceId: deviceId)
            Self.logger.info("Device closed: \(deviceId)")
            return nil
            
        default:
            Self.logger.error("Unimplemented method: \(call.method)")
            throw BleError.unimplemented
        }
    }

    private func startScan() {
        Self.logger.info("Setting up scan task...")
        scanTask?.cancel()
        scanTask = Task {
            do {
                Self.logger.info("Starting to listen for devices...")
                for try await peripheral in bleManager.listen() {
                    let deviceInfo: [String: Any] = [
                        "id": peripheral.identifier.uuidString,
                        "name": peripheral.name ?? "Unknown",
                        "serviceUUID": ""
                    ]
                    let event: [String: Any] = [
                        "type": "add",
                        "descriptor": deviceInfo
                    ]
                    
                    Self.logger.info("Sending device discovery event: \(deviceInfo)")
                    eventSink?(event)
                }
                Self.logger.info("Scan stream ended")
            } catch {
                Self.logger.error("Scan error: \(error.localizedDescription)")
                eventSink?(FlutterError(code: "SCAN_ERROR", message: error.localizedDescription, details: nil))
            }
        }
        Self.logger.info("Scan task configured")
    }

    private func stopScan() {
        Self.logger.info("Cancelling scan task...")
        scanTask?.cancel()
        scanTask = nil
        bleManager.stopScan()
        Self.logger.info("Scan stopped completely")
    }

    // MARK: - FlutterStreamHandler
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        Self.logger.info("Event stream listener attached")
        Self.logger.info("Arguments: \(String(describing: arguments))")
        self.eventSink = events
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        Self.logger.info("Event stream listener cancelled")
        Task {
            self.stopScan()
        }
        self.eventSink = nil
        return nil
    }
    
    public func applicationWillTerminate(_ application: UIApplication) {
        Self.logger.info("Application terminating - releasing BLE resources...")
        bleManager.release()
        Self.logger.info("BLE resources released")
    }
}
