package ble

class BleScanException(message: String) : Exception(message)
class DeviceNotFoundException : Exception("Device not found")
class DeviceNotConnectedException(message: String = "Device not connected") : Exception(message)
class CharacteristicNotFoundException(type: String) : Exception("$type characteristic not found")
class WriteFailedException(message: String = "Failed to write to characteristic") : Exception(message)
class InvalidSequenceException(message: String) : Exception(message)
class BleTooMuchDataException(message: String) : Exception(message)
class PermissionException(message: String) : Exception(message)

