package biometric

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import androidx.biometric.BiometricManager
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

class BiometricManager(private val context: Context) {

    companion object {
        private const val KEYSTORE_PROVIDER = "AndroidKeyStore"
        private const val KEY_ALIAS = "zilpay_biometric_key"
        private const val TRANSFORMATION = "${KeyProperties.KEY_ALGORITHM_AES}/${KeyProperties.BLOCK_MODE_GCM}/${KeyProperties.ENCRYPTION_PADDING_NONE}"
        private const val GCM_TAG_LENGTH = 128
        private const val IV_SIZE = 12
    }

    private val keyStore = KeyStore.getInstance(KEYSTORE_PROVIDER).apply { load(null) }

    fun biometricType(): String {
        val biometricManager = BiometricManager.from(context)

        return when (biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_STRONG)) {
            BiometricManager.BIOMETRIC_SUCCESS -> {
                when (biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_STRONG or BiometricManager.Authenticators.DEVICE_CREDENTIAL)) {
                    BiometricManager.BIOMETRIC_SUCCESS -> "BIOMETRIC_STRONG"
                    else -> "BIOMETRIC_WEAK"
                }
            }
            BiometricManager.BIOMETRIC_ERROR_NO_HARDWARE -> "NO_HARDWARE"
            BiometricManager.BIOMETRIC_ERROR_HW_UNAVAILABLE -> "HARDWARE_UNAVAILABLE"
            BiometricManager.BIOMETRIC_ERROR_NONE_ENROLLED -> "NONE_ENROLLED"
            BiometricManager.BIOMETRIC_ERROR_SECURITY_UPDATE_REQUIRED -> "SECURITY_UPDATE_REQUIRED"
            BiometricManager.BIOMETRIC_ERROR_UNSUPPORTED -> "UNSUPPORTED"
            BiometricManager.BIOMETRIC_STATUS_UNKNOWN -> "UNKNOWN"
            else -> "UNKNOWN"
        }
    }

    suspend fun encryptKey(activity: FragmentActivity, data: ByteArray): Result<ByteArray> {
        return try {
            val key = getOrCreateKey()
            val cipher = getCipher(Cipher.ENCRYPT_MODE, key)

            authenticateWithBiometric(activity, cipher)?.let { authenticatedCipher ->
                val encryptedData = authenticatedCipher.doFinal(data)
                val iv = authenticatedCipher.iv
                Result.success(iv + encryptedData)
            } ?: Result.failure(Exception("Authentication failed"))
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun decryptKey(activity: FragmentActivity, encryptedData: ByteArray): Result<ByteArray> {
        return try {
            val key = keyStore.getKey(KEY_ALIAS, null) as? SecretKey
                ?: return Result.failure(Exception("Key not found"))

            val iv = encryptedData.copyOfRange(0, IV_SIZE)
            val cipherText = encryptedData.copyOfRange(IV_SIZE, encryptedData.size)

            val cipher = getCipher(Cipher.DECRYPT_MODE, key, iv)

            authenticateWithBiometric(activity, cipher)?.let { authenticatedCipher ->
                val decryptedData = authenticatedCipher.doFinal(cipherText)
                Result.success(decryptedData)
            } ?: Result.failure(Exception("Authentication failed"))
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    fun deleteKey(): Boolean {
        return try {
            if (keyStore.containsAlias(KEY_ALIAS)) {
                keyStore.deleteEntry(KEY_ALIAS)
            }
            true
        } catch (e: Exception) {
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
            setInvalidatedByBiometricEnrollment(true)
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

                override fun onAuthenticationFailed() {
                    // Don't resume on individual failed attempts, only on final error
                }

                override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                    if (!isResumed) {
                        isResumed = true
                        continuation.resume(null)
                    }
                }
            }
        )

        biometricPrompt.authenticate(promptInfo, BiometricPrompt.CryptoObject(cipher))
    }

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

interface BiometricCallback {
    fun onSuccess(data: ByteArray)
    fun onError(message: String)
}