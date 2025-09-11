package ble

class BleScanException(message: String) : Exception(message)
class DeviceNotFoundException : Exception("Device not found")
class DeviceNotConnectedException : Exception("Device not connected")
class CharacteristicNotFoundException(type: String) : Exception("$type characteristic not found")
class WriteFailedException : Exception("Failed to write to characteristic")
class InvalidSequenceException(message: String) : Exception(message)
class BleTooMuchDataException(message: String) : Exception(message)
