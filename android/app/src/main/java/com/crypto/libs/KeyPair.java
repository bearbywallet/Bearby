package com.crypto.libs;

public interface KeyPair {
	public byte[] getPrivateKey();

	public byte[] getPublicKey();

	public String getPrivateKeyHex();

	public String getPublicKeyHex();
}
