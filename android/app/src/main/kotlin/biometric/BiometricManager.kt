package biometric

import android.content.Context
import android.os.Build
import android.provider.Settings
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Log
import androidx.annotation.Keep
import androidx.biometric.BiometricManager as AndroidBiometricManager
import androidx.biometric.BiometricPrompt
import androidx.fragment.app.FragmentActivity
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

@Keep
class BiometricManager(private val context: Context) {

    companion object {
        private const val TAG = "ZilPayBiometric"
        private const val KEYSTORE_PROVIDER = "AndroidKeyStore"
        private const val KEY_ALIAS = "zilpay_biometric_key"
        private const val TRANSFORMATION = "${KeyProperties.KEY_ALGORITHM_AES}/${KeyProperties.BLOCK_MODE_GCM}/${KeyProperties.ENCRYPTION_PADDING_NONE}"
        private const val GCM_TAG_LENGTH = 128
        private const val IV_SIZE = 12
    }

    private val keyStore = KeyStore.getInstance(KEYSTORE_PROVIDER).apply { load(null) }

    @Keep
    fun biometricType(): String {
        val biometricManager = AndroidBiometricManager.from(context)
        val strongResult = biometricManager.canAuthenticate(AndroidBiometricManager.Authenticators.BIOMETRIC_STRONG)
        val combinedResult = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            biometricManager.canAuthenticate(
                AndroidBiometricManager.Authenticators.BIOMETRIC_STRONG or AndroidBiometricManager.Authenticators.DEVICE_CREDENTIAL
            )
        } else {
            AndroidBiometricManager.BIOMETRIC_ERROR_UNSUPPORTED
        }

        return when (strongResult) {
            AndroidBiometricManager.BIOMETRIC_SUCCESS -> {
                when (combinedResult) {
                    AndroidBiometricManager.BIOMETRIC_SUCCESS -> "BIOMETRIC_STRONG"
                    else -> "BIOMETRIC_WEAK"
                }
            }
            AndroidBiometricManager.BIOMETRIC_ERROR_NO_HARDWARE -> "NO_HARDWARE"
            AndroidBiometricManager.BIOMETRIC_ERROR_HW_UNAVAILABLE -> "HARDWARE_UNAVAILABLE"
            AndroidBiometricManager.BIOMETRIC_ERROR_NONE_ENROLLED -> "NONE_ENROLLED"
            AndroidBiometricManager.BIOMETRIC_ERROR_SECURITY_UPDATE_REQUIRED -> "SECURITY_UPDATE_REQUIRED"
            AndroidBiometricManager.BIOMETRIC_ERROR_UNSUPPORTED -> "UNSUPPORTED"
            AndroidBiometricManager.BIOMETRIC_STATUS_UNKNOWN -> "UNKNOWN"
            else -> "UNKNOWN"
        }
    }

    @Keep
    fun getDeviceIdentifier(): Array<String> {
        val androidId = Settings.Secure.getString(context.contentResolver, Settings.Secure.ANDROID_ID) ?: ""

        return listOf(
            androidId,
            Build.BOARD,
            Build.HARDWARE,
            Build.DEVICE,
            Build.PRODUCT,
            Build.MANUFACTURER
        ).filter { it.isNotEmpty() }.distinct().toTypedArray()
    }

    suspend fun encryptKey(activity: FragmentActivity, data: ByteArray): Result<ByteArray> {
        return try {
            val key = getOrCreateKey()
            val hasBiometric = isBiometricEnrolled()
            var useDeviceCredentialFlow = false

            if (hasBiometric) {
                try {
                    val cipher = getCipher(Cipher.ENCRYPT_MODE, key)
                    authenticateWithBiometric(activity, cipher)?.let { authenticatedCipher ->
                        val encryptedData = authenticatedCipher.doFinal(data)
                        val iv = authenticatedCipher.iv
                        return Result.success(iv + encryptedData)
                    } ?: run {
                        Log.e(TAG, "encryptKey() - Biometric authentication failed")
                        return Result.failure(Exception("Authentication failed"))
                    }
                } catch (e: android.security.keystore.UserNotAuthenticatedException) {
                    Log.w(TAG, "encryptKey() - Key requires device credentials, switching flow")
                    useDeviceCredentialFlow = true
                }
            } else {
                useDeviceCredentialFlow = true
            }

            if (useDeviceCredentialFlow) {
                if (authenticateWithDeviceCredential(activity)) {
                    val cipher = getCipher(Cipher.ENCRYPT_MODE, key)
                    val encryptedData = cipher.doFinal(data)
                    val iv = cipher.iv
                    Result.success(iv + encryptedData)
                } else {
                    Log.e(TAG, "encryptKey() - Authentication failed")
                    Result.failure(Exception("Authentication failed"))
                }
            } else {
                Log.e(TAG, "encryptKey() - Unexpected code path")
                Result.failure(Exception("Unexpected error in encryption flow"))
            }
        } catch (e: android.security.keystore.KeyPermanentlyInvalidatedException) {
            Log.e(TAG, "encryptKey() - Key invalidated, deleting", e)
            deleteKey()
            Result.failure(Exception("Key invalidated due to biometric enrollment change. Please re-enroll."))
        } catch (e: Exception) {
            Log.e(TAG, "encryptKey() - Exception", e)
            Result.failure(e)
        }
    }

    suspend fun decryptKey(activity: FragmentActivity, encryptedData: ByteArray): Result<ByteArray> {
        return try {
            val key = keyStore.getKey(KEY_ALIAS, null) as? SecretKey
                ?: run {
                    Log.e(TAG, "decryptKey() - Key not found")
                    return Result.failure(Exception("Key not found"))
                }

            val iv = encryptedData.copyOfRange(0, IV_SIZE)
            val cipherText = encryptedData.copyOfRange(IV_SIZE, encryptedData.size)
            val hasBiometric = isBiometricEnrolled()
            var useDeviceCredentialFlow = false

            if (hasBiometric) {
                try {
                    val cipher = getCipher(Cipher.DECRYPT_MODE, key, iv)
                    authenticateWithBiometric(activity, cipher)?.let { authenticatedCipher ->
                        val decryptedData = authenticatedCipher.doFinal(cipherText)
                        return Result.success(decryptedData)
                    } ?: run {
                        Log.e(TAG, "decryptKey() - Biometric authentication failed")
                        return Result.failure(Exception("Authentication failed"))
                    }
                } catch (e: android.security.keystore.UserNotAuthenticatedException) {
                    Log.w(TAG, "decryptKey() - Key requires device credentials, switching flow")
                    useDeviceCredentialFlow = true
                }
            } else {
                useDeviceCredentialFlow = true
            }

            if (useDeviceCredentialFlow) {
                if (authenticateWithDeviceCredential(activity)) {
                    val cipher = getCipher(Cipher.DECRYPT_MODE, key, iv)
                    val decryptedData = cipher.doFinal(cipherText)
                    Result.success(decryptedData)
                } else {
                    Log.e(TAG, "decryptKey() - Authentication failed")
                    Result.failure(Exception("Authentication failed"))
                }
            } else {
                Log.e(TAG, "decryptKey() - Unexpected code path")
                Result.failure(Exception("Unexpected error in decryption flow"))
            }
        } catch (e: android.security.keystore.KeyPermanentlyInvalidatedException) {
            Log.e(TAG, "decryptKey() - Key invalidated, deleting", e)
            deleteKey()
            Result.failure(Exception("Key invalidated due to biometric enrollment change. Please re-enroll."))
        } catch (e: Exception) {
            Log.e(TAG, "decryptKey() - Exception", e)
            Result.failure(e)
        }
    }

    @Keep
    fun deleteKey(): Boolean {
        return try {
            if (keyStore.containsAlias(KEY_ALIAS)) {
                keyStore.deleteEntry(KEY_ALIAS)
            }
            true
        } catch (e: Exception) {
            Log.e(TAG, "deleteKey() - Failed", e)
            false
        }
    }

    private fun getOrCreateKey(): SecretKey {
        return if (keyStore.containsAlias(KEY_ALIAS)) {
            keyStore.getKey(KEY_ALIAS, null) as SecretKey
        } else {
            createKey()
        }
    }

    private fun isBiometricEnrolled(): Boolean {
        val biometricManager = AndroidBiometricManager.from(context)
        val result = biometricManager.canAuthenticate(AndroidBiometricManager.Authenticators.BIOMETRIC_STRONG)
        return result == AndroidBiometricManager.BIOMETRIC_SUCCESS
    }

    private fun createKey(): SecretKey {
        val keyGenerator = KeyGenerator.getInstance(
            KeyProperties.KEY_ALGORITHM_AES,
            KEYSTORE_PROVIDER
        )

        val keySpec = KeyGenParameterSpec.Builder(
            KEY_ALIAS,
            KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
        ).apply {
            setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            setUserAuthenticationRequired(true)
            setInvalidatedByBiometricEnrollment(false)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                setUserAuthenticationParameters(
                    30,
                    KeyProperties.AUTH_DEVICE_CREDENTIAL or KeyProperties.AUTH_BIOMETRIC_STRONG
                )
            } else {
                @Suppress("DEPRECATION")
                setUserAuthenticationValidityDurationSeconds(30)
            }
        }.build()

        keyGenerator.init(keySpec)
        return keyGenerator.generateKey()
    }

    private fun getCipher(mode: Int, key: SecretKey, iv: ByteArray? = null): Cipher {
        return Cipher.getInstance(TRANSFORMATION).apply {
            if (mode == Cipher.ENCRYPT_MODE) {
                init(mode, key)
            } else {
                val spec = GCMParameterSpec(GCM_TAG_LENGTH, iv)
                init(mode, key, spec)
            }
        }
    }

    private suspend fun authenticateWithDeviceCredential(
        activity: FragmentActivity
    ): Boolean = suspendCoroutine { continuation ->
        var isResumed = false

        val promptInfo = BiometricPrompt.PromptInfo.Builder()
            .setTitle("Device Authentication")
            .setSubtitle("Authenticate with your device PIN, pattern, or password")

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            promptInfo.setAllowedAuthenticators(
                AndroidBiometricManager.Authenticators.DEVICE_CREDENTIAL or
                AndroidBiometricManager.Authenticators.BIOMETRIC_STRONG
            )
        } else {
            promptInfo.setAllowedAuthenticators(
                AndroidBiometricManager.Authenticators.DEVICE_CREDENTIAL
            )
        }

        val biometricPrompt = BiometricPrompt(
            activity,
            object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                    if (!isResumed) {
                        isResumed = true
                        continuation.resume(true)
                    }
                }

                override fun onAuthenticationFailed() {}

                override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                    if (!isResumed) {
                        isResumed = true
                        continuation.resume(false)
                    }
                }
            }
        )

        try {
            biometricPrompt.authenticate(promptInfo.build())
        } catch (e: Exception) {
            Log.e(TAG, "authenticateWithDeviceCredential() - Failed", e)
            if (!isResumed) {
                isResumed = true
                continuation.resume(false)
            }
        }
    }

    private suspend fun authenticateWithBiometric(
        activity: FragmentActivity,
        cipher: Cipher
    ): Cipher? = suspendCoroutine { continuation ->
        var isResumed = false

        val promptInfo = BiometricPrompt.PromptInfo.Builder()
            .setTitle("Biometric Authentication")
            .setSubtitle("Authenticate to access secure data")
            .setNegativeButtonText("Cancel")
            .build()

        val biometricPrompt = BiometricPrompt(
            activity,
            object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                    if (!isResumed) {
                        isResumed = true
                        continuation.resume(result.cryptoObject?.cipher)
                    }
                }

                override fun onAuthenticationFailed() {}

                override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                    if (!isResumed) {
                        isResumed = true
                        continuation.resume(null)
                    }
                }
            }
        )

        try {
            biometricPrompt.authenticate(promptInfo, BiometricPrompt.CryptoObject(cipher))
        } catch (e: Exception) {
            Log.e(TAG, "authenticateWithBiometric() - Failed", e)
            if (!isResumed) {
                isResumed = true
                continuation.resume(null)
            }
        }
    }

    @Keep
    fun encryptKeyAsync(activity: FragmentActivity, data: ByteArray, callback: BiometricCallback) {
        CoroutineScope(Dispatchers.Main).launch {
            val result = encryptKey(activity, data)
            result.onSuccess { encryptedData ->
                callback.onSuccess(encryptedData)
            }.onFailure { error ->
                callback.onError(error.message ?: "Unknown error")
            }
        }
    }

    @Keep
    fun decryptKeyAsync(activity: FragmentActivity, encryptedData: ByteArray, callback: BiometricCallback) {
        CoroutineScope(Dispatchers.Main).launch {
            val result = decryptKey(activity, encryptedData)
            result.onSuccess { decryptedData ->
                callback.onSuccess(decryptedData)
            }.onFailure { error ->
                callback.onError(error.message ?: "Unknown error")
            }
        }
    }
}

@Keep
interface BiometricCallback {
    fun onSuccess(data: ByteArray)
    fun onError(message: String)
}
