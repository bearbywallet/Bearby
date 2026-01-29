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
        Log.d(TAG, "biometricType() - BIOMETRIC_STRONG check result: $strongResult")

        val deviceCredResult = biometricManager.canAuthenticate(AndroidBiometricManager.Authenticators.DEVICE_CREDENTIAL)
        Log.d(TAG, "biometricType() - DEVICE_CREDENTIAL check result: $deviceCredResult")

        val combinedResult = biometricManager.canAuthenticate(
            AndroidBiometricManager.Authenticators.BIOMETRIC_STRONG or AndroidBiometricManager.Authenticators.DEVICE_CREDENTIAL
        )
        Log.d(TAG, "biometricType() - BIOMETRIC_STRONG | DEVICE_CREDENTIAL check result: $combinedResult")

        val result = when (strongResult) {
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

        Log.d(TAG, "biometricType() - Final result: $result")
        return result
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
        Log.d(TAG, "encryptKey() - Starting encryption, data size: ${data.size}")
        return try {
            Log.d(TAG, "encryptKey() - Getting or creating key")
            val key = getOrCreateKey()
            val hasBiometric = isBiometricEnrolled()
            Log.d(TAG, "encryptKey() - Key obtained, biometric enrolled: $hasBiometric")

            if (hasBiometric) {
                // Biometric flow: Initialize cipher first, then authenticate
                Log.d(TAG, "encryptKey() - Biometric flow: Initializing cipher before authentication")
                val cipher = getCipher(Cipher.ENCRYPT_MODE, key)

                authenticateWithBiometric(activity, cipher)?.let { authenticatedCipher ->
                    Log.d(TAG, "encryptKey() - Authentication succeeded, encrypting data")
                    val encryptedData = authenticatedCipher.doFinal(data)
                    val iv = authenticatedCipher.iv
                    Log.d(TAG, "encryptKey() - Encryption successful, IV size: ${iv.size}, encrypted size: ${encryptedData.size}")
                    Result.success(iv + encryptedData)
                } ?: run {
                    Log.e(TAG, "encryptKey() - Authentication failed")
                    Result.failure(Exception("Authentication failed"))
                }
            } else {
                // Device credential flow: Authenticate first, then initialize cipher
                Log.d(TAG, "encryptKey() - Device credential flow: Authenticating before cipher initialization")

                if (authenticateWithDeviceCredential(activity)) {
                    Log.d(TAG, "encryptKey() - Authentication succeeded, initializing cipher")
                    val cipher = getCipher(Cipher.ENCRYPT_MODE, key)
                    val encryptedData = cipher.doFinal(data)
                    val iv = cipher.iv
                    Log.d(TAG, "encryptKey() - Encryption successful, IV size: ${iv.size}, encrypted size: ${encryptedData.size}")
                    Result.success(iv + encryptedData)
                } else {
                    Log.e(TAG, "encryptKey() - Authentication failed")
                    Result.failure(Exception("Authentication failed"))
                }
            }
        } catch (e: android.security.keystore.KeyPermanentlyInvalidatedException) {
            Log.e(TAG, "encryptKey() - Key permanently invalidated (biometric enrollment changed)", e)
            Log.d(TAG, "encryptKey() - Deleting invalidated key")
            deleteKey()
            Result.failure(Exception("Key invalidated due to biometric enrollment change. Please re-enroll."))
        } catch (e: Exception) {
            Log.e(TAG, "encryptKey() - Exception occurred", e)
            Result.failure(e)
        }
    }

    suspend fun decryptKey(activity: FragmentActivity, encryptedData: ByteArray): Result<ByteArray> {
        Log.d(TAG, "decryptKey() - Starting decryption, encrypted data size: ${encryptedData.size}")
        return try {
            Log.d(TAG, "decryptKey() - Checking if key exists in keystore")
            val key = keyStore.getKey(KEY_ALIAS, null) as? SecretKey
                ?: run {
                    Log.e(TAG, "decryptKey() - Key not found in keystore")
                    return Result.failure(Exception("Key not found"))
                }

            Log.d(TAG, "decryptKey() - Key found, extracting IV and ciphertext")
            val iv = encryptedData.copyOfRange(0, IV_SIZE)
            val cipherText = encryptedData.copyOfRange(IV_SIZE, encryptedData.size)
            Log.d(TAG, "decryptKey() - IV size: ${iv.size}, ciphertext size: ${cipherText.size}")

            val hasBiometric = isBiometricEnrolled()
            Log.d(TAG, "decryptKey() - Biometric enrolled: $hasBiometric")

            if (hasBiometric) {
                // Biometric flow: Initialize cipher first, then authenticate
                Log.d(TAG, "decryptKey() - Biometric flow: Initializing cipher before authentication")
                val cipher = getCipher(Cipher.DECRYPT_MODE, key, iv)

                authenticateWithBiometric(activity, cipher)?.let { authenticatedCipher ->
                    Log.d(TAG, "decryptKey() - Authentication succeeded, decrypting data")
                    val decryptedData = authenticatedCipher.doFinal(cipherText)
                    Log.d(TAG, "decryptKey() - Decryption successful, decrypted size: ${decryptedData.size}")
                    Result.success(decryptedData)
                } ?: run {
                    Log.e(TAG, "decryptKey() - Authentication failed")
                    Result.failure(Exception("Authentication failed"))
                }
            } else {
                // Device credential flow: Authenticate first, then initialize cipher
                Log.d(TAG, "decryptKey() - Device credential flow: Authenticating before cipher initialization")

                if (authenticateWithDeviceCredential(activity)) {
                    Log.d(TAG, "decryptKey() - Authentication succeeded, initializing cipher")
                    val cipher = getCipher(Cipher.DECRYPT_MODE, key, iv)
                    val decryptedData = cipher.doFinal(cipherText)
                    Log.d(TAG, "decryptKey() - Decryption successful, decrypted size: ${decryptedData.size}")
                    Result.success(decryptedData)
                } else {
                    Log.e(TAG, "decryptKey() - Authentication failed")
                    Result.failure(Exception("Authentication failed"))
                }
            }
        } catch (e: android.security.keystore.KeyPermanentlyInvalidatedException) {
            Log.e(TAG, "decryptKey() - Key permanently invalidated (biometric enrollment changed)", e)
            Log.d(TAG, "decryptKey() - Deleting invalidated key")
            deleteKey()
            Result.failure(Exception("Key invalidated due to biometric enrollment change. Please re-enroll."))
        } catch (e: Exception) {
            Log.e(TAG, "decryptKey() - Exception occurred", e)
            Result.failure(e)
        }
    }

    @Keep
    fun deleteKey(): Boolean {
        Log.d(TAG, "deleteKey() - Attempting to delete biometric key")
        return try {
            if (keyStore.containsAlias(KEY_ALIAS)) {
                Log.d(TAG, "deleteKey() - Key exists, deleting")
                keyStore.deleteEntry(KEY_ALIAS)
                Log.d(TAG, "deleteKey() - Key deleted successfully")
            } else {
                Log.d(TAG, "deleteKey() - Key does not exist, nothing to delete")
            }
            true
        } catch (e: Exception) {
            Log.e(TAG, "deleteKey() - Failed to delete key", e)
            false
        }
    }

    private fun getOrCreateKey(): SecretKey {
        return if (keyStore.containsAlias(KEY_ALIAS)) {
            Log.d(TAG, "getOrCreateKey() - Key already exists, retrieving from keystore")
            keyStore.getKey(KEY_ALIAS, null) as SecretKey
        } else {
            Log.d(TAG, "getOrCreateKey() - Key does not exist, creating new key")
            createKey()
        }
    }

    private fun isBiometricEnrolled(): Boolean {
        val biometricManager = AndroidBiometricManager.from(context)
        val result = biometricManager.canAuthenticate(AndroidBiometricManager.Authenticators.BIOMETRIC_STRONG)
        return result == AndroidBiometricManager.BIOMETRIC_SUCCESS
    }

    private fun createKey(): SecretKey {
        Log.d(TAG, "createKey() - Creating new biometric key")
        val keyGenerator = KeyGenerator.getInstance(
            KeyProperties.KEY_ALGORITHM_AES,
            KEYSTORE_PROVIDER
        )

        val hasBiometric = isBiometricEnrolled()
        Log.d(TAG, "createKey() - Biometric enrolled: $hasBiometric")

        val keySpec = KeyGenParameterSpec.Builder(
            KEY_ALIAS,
            KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
        ).apply {
            setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            setUserAuthenticationRequired(true)

            if (hasBiometric) {
                // Biometric is enrolled - use biometric-only authentication
                Log.d(TAG, "createKey() - Configuring for biometric authentication (invalidated on enrollment change)")
                setInvalidatedByBiometricEnrollment(true)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    // API 30+: explicitly set biometric authenticator
                    setUserAuthenticationParameters(
                        0, // 0 = require authentication for every use
                        KeyProperties.AUTH_BIOMETRIC_STRONG
                    )
                }
            } else {
                // No biometric enrolled - use device credential (PIN/Pattern/Password)
                // Must use timeout-based authentication for device credentials
                Log.d(TAG, "createKey() - Configuring for device credential authentication (PIN/Pattern/Password)")
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    // API 30+: allow device credential
                    setUserAuthenticationParameters(
                        30, // Authentication valid for 30 seconds
                        KeyProperties.AUTH_DEVICE_CREDENTIAL or KeyProperties.AUTH_BIOMETRIC_STRONG
                    )
                } else {
                    // API < 30: Use timeout to enable device credential
                    setUserAuthenticationValidityDurationSeconds(30)
                }
            }
        }.build()

        Log.d(TAG, "createKey() - Key spec configured, generating key")
        keyGenerator.init(keySpec)
        val key = keyGenerator.generateKey()
        Log.d(TAG, "createKey() - Key generated successfully")
        return key
    }

    private fun getCipher(mode: Int, key: SecretKey, iv: ByteArray? = null): Cipher {
        val modeStr = if (mode == Cipher.ENCRYPT_MODE) "ENCRYPT" else "DECRYPT"
        Log.d(TAG, "getCipher() - Creating cipher for $modeStr mode")

        return Cipher.getInstance(TRANSFORMATION).apply {
            try {
                if (mode == Cipher.ENCRYPT_MODE) {
                    Log.d(TAG, "getCipher() - Initializing cipher for encryption")
                    init(mode, key)
                } else {
                    Log.d(TAG, "getCipher() - Initializing cipher for decryption with IV")
                    val spec = GCMParameterSpec(GCM_TAG_LENGTH, iv)
                    init(mode, key, spec)
                }
                Log.d(TAG, "getCipher() - Cipher initialized successfully for $modeStr")
            } catch (e: Exception) {
                Log.e(TAG, "getCipher() - Failed to initialize cipher for $modeStr", e)
                throw e
            }
        }
    }

    private suspend fun authenticateWithDeviceCredential(
        activity: FragmentActivity
    ): Boolean = suspendCoroutine { continuation ->
        Log.d(TAG, "authenticateWithDeviceCredential() - Starting device credential authentication")
        var isResumed = false

        val promptInfo = BiometricPrompt.PromptInfo.Builder()
            .setTitle("Device Authentication")
            .setSubtitle("Authenticate with your device PIN, pattern, or password")
            .setAllowedAuthenticators(
                AndroidBiometricManager.Authenticators.DEVICE_CREDENTIAL or
                AndroidBiometricManager.Authenticators.BIOMETRIC_STRONG
            )
            .build()

        Log.d(TAG, "authenticateWithDeviceCredential() - Prompt info created, setting up callback")

        val biometricPrompt = BiometricPrompt(
            activity,
            object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                    Log.d(TAG, "onAuthenticationSucceeded() - Device credential authentication succeeded")
                    if (!isResumed) {
                        isResumed = true
                        continuation.resume(true)
                    } else {
                        Log.w(TAG, "onAuthenticationSucceeded() - Already resumed, ignoring")
                    }
                }

                override fun onAuthenticationFailed() {
                    Log.w(TAG, "onAuthenticationFailed() - Individual authentication attempt failed (not final)")
                }

                override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                    Log.e(TAG, "onAuthenticationError() - Error code: $errorCode, message: $errString")
                    if (!isResumed) {
                        isResumed = true
                        Log.e(TAG, "onAuthenticationError() - Resuming with false (authentication failed)")
                        continuation.resume(false)
                    } else {
                        Log.w(TAG, "onAuthenticationError() - Already resumed, ignoring")
                    }
                }
            }
        )

        Log.d(TAG, "authenticateWithDeviceCredential() - Showing device credential prompt (no CryptoObject)")
        try {
            // No CryptoObject - user must authenticate first, then key becomes available
            biometricPrompt.authenticate(promptInfo)
            Log.d(TAG, "authenticateWithDeviceCredential() - Prompt shown successfully")
        } catch (e: Exception) {
            Log.e(TAG, "authenticateWithDeviceCredential() - Failed to show prompt", e)
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
        Log.d(TAG, "authenticateWithBiometric() - Starting biometric authentication with CryptoObject")
        var isResumed = false

        val promptInfo = BiometricPrompt.PromptInfo.Builder()
            .setTitle("Biometric Authentication")
            .setSubtitle("Authenticate to access secure data")
            .setNegativeButtonText("Cancel")
            .build()

        Log.d(TAG, "authenticateWithBiometric() - Prompt info created, setting up callback")

        val biometricPrompt = BiometricPrompt(
            activity,
            object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                    Log.d(TAG, "onAuthenticationSucceeded() - Biometric authentication succeeded")
                    if (!isResumed) {
                        isResumed = true
                        val cipher = result.cryptoObject?.cipher
                        Log.d(TAG, "onAuthenticationSucceeded() - Cipher from result: ${cipher != null}")
                        continuation.resume(cipher)
                    } else {
                        Log.w(TAG, "onAuthenticationSucceeded() - Already resumed, ignoring")
                    }
                }

                override fun onAuthenticationFailed() {
                    Log.w(TAG, "onAuthenticationFailed() - Individual authentication attempt failed (not final)")
                }

                override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                    Log.e(TAG, "onAuthenticationError() - Error code: $errorCode, message: $errString")
                    if (!isResumed) {
                        isResumed = true
                        Log.e(TAG, "onAuthenticationError() - Resuming with null (authentication failed)")
                        continuation.resume(null)
                    } else {
                        Log.w(TAG, "onAuthenticationError() - Already resumed, ignoring")
                    }
                }
            }
        )

        Log.d(TAG, "authenticateWithBiometric() - Showing biometric prompt")
        try {
            biometricPrompt.authenticate(promptInfo, BiometricPrompt.CryptoObject(cipher))
            Log.d(TAG, "authenticateWithBiometric() - Biometric prompt shown successfully")
        } catch (e: Exception) {
            Log.e(TAG, "authenticateWithBiometric() - Failed to show biometric prompt", e)
            if (!isResumed) {
                isResumed = true
                continuation.resume(null)
            }
        }
    }

    @Keep
    fun encryptKeyAsync(activity: FragmentActivity, data: ByteArray, callback: BiometricCallback) {
        Log.d(TAG, "encryptKeyAsync() - Called from Rust, data size: ${data.size}")
        CoroutineScope(Dispatchers.Main).launch {
            Log.d(TAG, "encryptKeyAsync() - Launching coroutine on Main dispatcher")
            val result = encryptKey(activity, data)
            result.onSuccess { encryptedData ->
                Log.d(TAG, "encryptKeyAsync() - Success, calling Rust callback with encrypted data")
                callback.onSuccess(encryptedData)
            }.onFailure { error ->
                Log.e(TAG, "encryptKeyAsync() - Failure: ${error.message}", error)
                callback.onError(error.message ?: "Unknown error")
            }
        }
    }

    @Keep
    fun decryptKeyAsync(activity: FragmentActivity, encryptedData: ByteArray, callback: BiometricCallback) {
        Log.d(TAG, "decryptKeyAsync() - Called from Rust, encrypted data size: ${encryptedData.size}")
        CoroutineScope(Dispatchers.Main).launch {
            Log.d(TAG, "decryptKeyAsync() - Launching coroutine on Main dispatcher")
            val result = decryptKey(activity, encryptedData)
            result.onSuccess { decryptedData ->
                Log.d(TAG, "decryptKeyAsync() - Success, calling Rust callback with decrypted data")
                callback.onSuccess(decryptedData)
            }.onFailure { error ->
                Log.e(TAG, "decryptKeyAsync() - Failure: ${error.message}", error)
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