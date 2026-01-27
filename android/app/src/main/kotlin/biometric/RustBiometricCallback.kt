package biometric

import androidx.annotation.Keep

@Keep
class RustBiometricCallback(private val callbackPtr: Long) : BiometricCallback {
    override fun onSuccess(data: ByteArray) {
        nativeOnSuccess(callbackPtr, data)
    }

    override fun onError(message: String) {
        nativeOnError(callbackPtr, message)
    }

    private external fun nativeOnSuccess(callbackPtr: Long, data: ByteArray)
    private external fun nativeOnError(callbackPtr: Long, message: String)
}
