package com.crypto.libs;

import org.spongycastle.asn1.x9.X9ECParameters;
import org.spongycastle.crypto.ec.CustomNamedCurves;

import java.math.BigInteger;

/**
 * Created by skylab on 7/23/18.
 */

public class ECPoint implements KeyPair{

    private byte[] key;
    private byte[] publicKey;
    private boolean compressed;
    private X9ECParameters CURVE = CustomNamedCurves.getByName("secp256k1");

    public ECPoint(byte[] key) {
        this.key = key;
        this.publicKey = calculatePublicKey(key);
        this.compressed = true;
    }

    public ECPoint(byte[] publicKey, boolean compressed) {
        this.publicKey = publicKey;
        this.compressed = compressed;
        this.key = null;
    }

    private byte[] calculatePublicKey(byte[] priKey) {
        if (priKey == null) {
            return null;
        }
        BigInteger pri = new BigInteger(1, priKey);
        return CURVE.getG().multiply(pri).getEncoded(true);
    }

    private String bytesToHexString(byte[] bytes) {
        StringBuilder sb = new StringBuilder();
        for (byte b : bytes) {
            sb.append(String.format("%02x", b));
        }
        return sb.toString();
    }

    @Override
    public byte[] getPrivateKey() {
        return this.key;
    }

    @Override
    public byte[] getPublicKey() {
        return this.publicKey;
    }

    @Override
    public String getPrivateKeyHex() {
        if (this.key == null) return "";
        return bytesToHexString(this.key);
    }

    @Override
    public String getPublicKeyHex() {
        if (this.publicKey == null) return "";
        return bytesToHexString(this.publicKey);
    }
}
