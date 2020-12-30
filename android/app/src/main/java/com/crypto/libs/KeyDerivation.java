package com.crypto.libs;

import org.spongycastle.asn1.x9.X9ECParameters;
import org.spongycastle.crypto.ec.CustomNamedCurves;

import java.math.BigInteger;
import java.security.InvalidKeyException;
import java.security.NoSuchAlgorithmException;
import java.security.NoSuchProviderException;
import java.security.SecureRandom;
import java.security.Security;
import java.util.Arrays;
import java.nio.charset.StandardCharsets;

import javax.crypto.Mac;
import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;

public class KeyDerivation {
	private static final SecureRandom rnd = new SecureRandom ();
	private X9ECParameters CURVE = CustomNamedCurves.getByName("secp256k1");

	private byte[] chainCode;
	private int depth;
	private int parent;
	private int sequence;
	private int childNumber;
	private ECPoint ecPoint;

	private static final byte[] SEED = "Bitcoin seed".getBytes (StandardCharsets.UTF_8);
	private static final String HMAC_SHA512 = "HmacSHA512";

	public KeyDerivation(byte[] key, byte[] chainCode) {
		this.ecPoint = new ECPoint(key);
		this.chainCode = chainCode;
		this.depth = 0;
		this.childNumber = 0;
		this.parent = 0;
	}

	public static KeyDerivation createFromSeed(byte[] seed) {
		try {
			Mac sha512Hmac = Mac.getInstance(HMAC_SHA512);
			SecretKeySpec keySpec = new SecretKeySpec(SEED, HMAC_SHA512);
			sha512Hmac.init(keySpec);
			byte[] lr = sha512Hmac.doFinal(seed);
			byte[] l = Arrays.copyOfRange(lr, 0, 32);
			byte[] r = Arrays.copyOfRange(lr, 32, 64);
			return new KeyDerivation(l, r);
		}
		catch (NoSuchAlgorithmException n)
		{
			throw new RuntimeException(n);
		}
		catch (InvalidKeyException i)
		{
			throw new RuntimeException(i);
		}

	}

	public KeyDerivation setDepth(int depth) {
		this.depth = depth;
		return this;
	}

	public KeyDerivation setParent(int parent) {
		this.parent = parent;
		return this;
	}

	public KeyDerivation setChildNumber(int childNumber) {
		this.childNumber = childNumber;
		return this;
	}

	public ECPoint getKey() {
		return this.ecPoint;
	}

	public KeyDerivation derive(CharSequence derivationPath) {
		final int length = derivationPath.length();
		if (length == 0)
			throw new IllegalArgumentException("Path cannot be empty");
		if (derivationPath.charAt(0) != 'm')
			throw new IllegalArgumentException("Path must start with m");
		if (length == 1)
			return this;
		if (derivationPath.charAt(1) != '/')
			throw new IllegalArgumentException("Path must start with m/");
		KeyDerivation currentNode = this;
		int buffer = 0;
		for (int i = 2; i < length; i++) {
			final char c = derivationPath.charAt(i);
			switch (c) {
				case '\'':
					buffer = buffer | 0x80000000;
					break;
				case '/':
					currentNode = currentNode.derive(buffer);
					buffer = 0;
					break;
				default:
					buffer *= 10;
					if (c < '0' || c > '9')
						throw new IllegalArgumentException("Illegal character in path: " + c);
					buffer += c - '0';
					if ((buffer & 0x80000000) != 0)
						throw new IllegalArgumentException("Index number too large");
			}
		}
		return currentNode.derive(buffer);
	}

	public KeyDerivation derive(int index) {
		try {
			byte[] extended;

			byte[] pub = this.ecPoint.getPublicKey();

			if ((index & 0x80000000) != 0) {
				byte[] privateKey = this.ecPoint.getPrivateKey();
				extended = new byte[privateKey.length + 5];
				System.arraycopy(privateKey, 0, extended, 1, privateKey.length);
				extended[privateKey.length + 1] = (byte) ((index >>> 24) & 0xff);
				extended[privateKey.length + 2] = (byte) ((index >>> 16) & 0xff);
				extended[privateKey.length + 3] = (byte) ((index >>> 8) & 0xff);
				extended[privateKey.length + 4] = (byte) (index & 0xff);
			} else {
				extended = new byte[pub.length + 4];
				System.arraycopy(pub, 0, extended, 0, pub.length);
				extended[pub.length] = (byte) ((index >>> 24) & 0xff);
				extended[pub.length + 1] = (byte) ((index >>> 16) & 0xff);
				extended[pub.length + 2] = (byte) ((index >>> 8) & 0xff);
				extended[pub.length + 3] = (byte) (index & 0xff);
			}

			Mac mac = Mac.getInstance (HMAC_SHA512);
			SecretKey key = new SecretKeySpec (this.chainCode, HMAC_SHA512);
			mac.init (key);

			byte[] lr = mac.doFinal (extended);
			byte[] l = Arrays.copyOfRange (lr, 0, 32);
			byte[] r = Arrays.copyOfRange (lr, 32, 64);

			BigInteger bigIntL =  new BigInteger(1, l);
			BigInteger bigKey = new BigInteger(1, this.ecPoint.getPrivateKey());
			BigInteger hI = bigIntL.add(bigKey).mod(CURVE.getN());

			if (bigIntL.compareTo(CURVE.getN()) > 0 || hI.equals(BigInteger.ZERO)) {
				return derive(index + 1);
			}

			ser256(l, hI);

			return new KeyDerivation(l, r);
		}
		catch ( NoSuchAlgorithmException e )
		{
			throw new RuntimeException (e);
		} catch ( InvalidKeyException e )
		{
			throw new RuntimeException (e);
		}

	}

	private void ser256(final byte[] target, final BigInteger integer) {
		if (integer.bitLength() > target.length * 8)
			throw new RuntimeException("ser256 failed, cannot fit integer in buffer");
		final byte[] modArr = integer.toByteArray();
		Arrays.fill(target, (byte) 0);
		copyTail(modArr, target);
		Arrays.fill(modArr, (byte) 0);
	}

	private void copyTail(final byte[] src, final byte[] dest) {
		if (src.length < dest.length) {
			System.arraycopy(src, 0, dest, dest.length - src.length, src.length);
		} else {
			System.arraycopy(src, src.length - dest.length, dest, 0, dest.length);
		}
	}


}
