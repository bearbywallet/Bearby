package com.crypto.libs;
import android.util.Log;

import java.util.Arrays;
import java.security.MessageDigest;

import io.github.novacrypto.bip39.wordlists.English;

public class Mnemonic {

    private final String salt = "mnemonic";
    private byte[] ent;
    private int[] wordIndexes;
    private String sentence;
    private final IPBKDF2WithHmacSHA512Algorithm algorithm = SpongyCastlePBKDF2WithHmacSHA512.INSTANCE;

    public Mnemonic(CharSequence entropyHex) {
        final int length = entropyHex.length();
        if (length % 2 == 1)
            throw new RuntimeException("Length of hex chars must be divisible by 2");
        final byte[] entropy = new byte[length / 2];
        Arrays.fill(entropy, (byte) 0);
        for (int i = 0, j = 0; i < length; i += 2, j++) {
            entropy[j] = (byte) (parseHex(entropyHex.charAt(i)) << 4 | parseHex(entropyHex.charAt(i + 1)));
        }
        new Mnemonic(entropy);
    }

    public Mnemonic(byte[] entropy) {
        int[] wordIndexes = wordIndexes(entropy);
        this.ent = entropy;
        this.wordIndexes = wordIndexes;
        this.sentence = this.getSentence();
    }

    public Mnemonic(String sentence) {
        this.sentence = sentence;
    }

    private String getSentence() {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < this.wordIndexes.length; i++) {
            if (i > 0)
                sb.append(" ");
            sb.append(getWordByIndex(this.wordIndexes[i]));
        }
        return sb.toString();
    }

    public String GetSentence() {
        return this.sentence;
    }

    public byte[] GetSeed(String passphrase) {
        try {
            char[] data = this.sentence.toCharArray();
            byte[] saltBytes = (salt).getBytes("UTF-8");
            return algorithm.hash(data, saltBytes);
        } catch (Exception e) {
            Log.e("Exception", e.getMessage());
        }
        return new byte[0];
    }

    private int[] wordIndexes(byte[] entropy) {
        final int ent = entropy.length * 8;
        entropyLengthCheck(ent);

        final byte[] entropyWithChecksum = Arrays.copyOf(entropy, entropy.length + 1);
        entropyWithChecksum[entropy.length] = firstByteOfSha256(entropy);

        // checksum length
        final int cs = ent / 32;
        // mnemonic length
        final int ms = (ent + cs) / 11;

        // get the indexes into the word list
        final int[] wordIndexes = new int[ms];
        for (int i = 0, wi = 0; wi < ms; i += 11, wi++) {
            wordIndexes[wi] = next11Bits(entropyWithChecksum, i);
        }
        return wordIndexes;
    }

    private byte firstByteOfSha256(byte[] entropy) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(entropy);
            return hash[0];
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }

    private int parseHex(char c) {
        if (c >= '0' && c <= '9')
            return c - '0';
        if (c >= 'a' && c <= 'f')
            return (c - 'a') + 10;
        if (c >= 'A' && c <= 'F')
            return (c - 'A') + 10;
        throw new RuntimeException("Invalid hex char '" + c + '\'');
    }

    private int next11Bits(byte[] bytes, int offset) {
        final int skip = offset / 8;
        final int lowerBitsToRemove = (3 * 8 - 11) - (offset % 8);
        return (((int) bytes[skip] & 0xff) << 16 | ((int) bytes[skip + 1] & 0xff) << 8
                | (lowerBitsToRemove < 8 ? ((int) bytes[skip + 2] & 0xff) : 0)) >> lowerBitsToRemove & (1 << 11) - 1;
    }

    private void entropyLengthCheck(int entropyLength) {
        if (entropyLength < 128 || entropyLength > 256 || entropyLength % 32 != 0) {
            throw new RuntimeException(
                    "entropy must between 128-256 and be divisible by 32, but got " + entropyLength + " bits.");
        }
    }

    private String getWordByIndex(int index) {
        if (index > 2048) {
            throw new RuntimeException("index must be less than 2048");
        }
        return English.INSTANCE.getWord(index);
    }

    // Returns hex string from byte array
    private final static char[] hexArray = "0123456789ABCDEF".toCharArray();

    public static String bytesToHex(byte[] bytes) {
        char[] hexChars = new char[bytes.length * 2];
        for (int j = 0; j < bytes.length; j++) {
            int v = bytes[j] & 0xFF;
            hexChars[j * 2] = hexArray[v >>> 4];
            hexChars[j * 2 + 1] = hexArray[v & 0x0F];
        }
        return new String(hexChars);
    }
}
