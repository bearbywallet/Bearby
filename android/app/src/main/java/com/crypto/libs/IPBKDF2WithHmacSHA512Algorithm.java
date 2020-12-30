package com.crypto.libs;

public interface IPBKDF2WithHmacSHA512Algorithm {
    byte[] hash(final char[] chars, final byte[] salt);
}
