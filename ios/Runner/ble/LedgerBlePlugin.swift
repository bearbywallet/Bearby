import Flutter
import UIKit
import CoreBluetooth

// ИЗМЕНЕНИЕ: Весь класс теперь работает на главном потоке (Main Actor).
// Это решает большинство ошибок, связанных с вызовом BleManager.
@MainActor
public class LedgerBlePlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    // Эта инициализация теперь корректна, так как мы находимся в @MainActor
    private let bleManager = BleManager()
    private var eventSink: FlutterEventSink?
    private var scanTask: Task<Void, Never>?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "ledger.com/ble", binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: "ledger.com/ble/events", binaryMessenger: registrar.messenger())
        let instance = LedgerBlePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        eventChannel.setStreamHandler(instance)
        
        // ИЗМЕНЕНИЕ: Добавляем обработчик для правильного освобождения ресурсов
        registrar.addApplicationDelegate(instance)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        // ИЗМЕНЕНИЕ: Создаем Task для вызова асинхронного `handleMethodCall`
        // из синхронного метода `handle`.
        Task {
            do {
                let res = try await handleMethodCall(call)
                result(res)
            } catch {
                let flutterError = FlutterError(
                    code: String(describing: type(of: error)),
                    message: error.localizedDescription,
                    details: nil)
                result(flutterError)
            }
        }
    }

    private func handleMethodCall(_ call: FlutterMethodCall) async throws -> Any? {
        switch call.method {
        case "getConnectedDevices":
            return bleManager.getConnectedDevices().map { peripheral -> [String: Any] in
                return [
                    "id": peripheral.identifier.uuidString,
                    "name": peripheral.name ?? "Unknown",
                    "serviceUUID": ""
                ]
            }
        case "startScan":
            startScan()
            return nil
        case "stopScan":
            stopScan()
            return nil
        case "isSupported":
            return bleManager.isSupported()
        case "openDevice":
            guard let deviceId = call.arguments as? String else {
                throw BleError.illegalArgument("Device ID must be a String")
            }
            // `await` здесь обязателен, т.к. open - асинхронная функция
            try await bleManager.open(deviceId: deviceId)
            return nil
        case "exchange":
            guard let args = call.arguments as? [String: Any],
                  let deviceId = args["deviceId"] as? String,
                  let apdu = args["apdu"] as? FlutterStandardTypedData else {
                throw BleError.illegalArgument("Invalid arguments for exchange")
            }
            // `await` здесь обязателен, т.к. exchange - асинхронная функция
            let response = try await bleManager.exchange(deviceId: deviceId, apdu: apdu.data)
            return FlutterStandardTypedData(bytes: response)
        case "closeDevice":
             guard let args = call.arguments as? [String: Any],
                  let deviceId = args["deviceId"] as? String else {
                throw BleError.illegalArgument("Device ID must be a String")
            }
            bleManager.close(deviceId: deviceId)
            return nil
        default:
            throw BleError.unimplemented
        }
    }

    private func startScan() {
        scanTask?.cancel()
        scanTask = Task {
            do {
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
                    eventSink?(event)
                }
            } catch {
                // Обработка ошибок сканирования
                eventSink?(FlutterError(code: "SCAN_ERROR", message: error.localizedDescription, details: nil))
            }
        }
    }

    private func stopScan() {
        scanTask?.cancel()
        scanTask = nil
        bleManager.stopScan()
    }

    // MARK: - FlutterStreamHandler
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        // ИЗМЕНЕНИЕ: Вызываем stopScan внутри Task, чтобы перейти в асинхронный контекст
        Task {
            self.stopScan()
        }
        self.eventSink = nil
        return nil
    }
    
    // ИЗМЕНЕНИЕ: Правильно освобождаем ресурсы при закрытии приложения
    public func applicationWillTerminate(_ application: UIApplication) {
        bleManager.release()
    }
    
    // Удаляем deinit, так как он не может безопасно вызывать асинхронный код
}
