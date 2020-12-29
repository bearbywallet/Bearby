package com.crypto.libs;
/**
 * Created by skylab on 7/23/18.
 */

public interface KeyPair {
    public byte[] getPrivateKey();

    public byte[] getPublicKey();

    public String getPrivateKeyHex();

    public String getPublicKeyHex();
}
