package com.crypto.libs;
import android.util.Log;

import javax.crypto.SecretKey;
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.PBEKeySpec;

/**
 * Created by skylab on 7/23/18.
 */

public enum SecretKeyFactoryPBKDF2WithHmacSHA512Algorithm implements IPBKDF2WithHmacSHA512Algorithm {
    INSTANCE;

    // Does not support API version < 26
    @Override
    public byte[] hash(char[] chars, byte[] salt) {
        try {
            SecretKeyFactory f = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA512");
            SecretKey key = f.generateSecret(new PBEKeySpec(chars, salt, 2048, 512));
            return key.getEncoded();
        } catch (Exception e) {
            Log.e("Exception: ", e.getMessage());
        }
        return new byte[0];
    }
}
