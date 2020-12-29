package com.crypto;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;
import com.crypto.libs.ECPoint;
import com.crypto.libs.KeyDerivation;
import com.crypto.libs.Mnemonic;

import java.security.SecureRandom;

import io.github.novacrypto.bip39.MnemonicValidator;
import io.github.novacrypto.bip39.Validation.InvalidChecksumException;
import io.github.novacrypto.bip39.Validation.InvalidWordCountException;
import io.github.novacrypto.bip39.Validation.UnexpectedWhiteSpaceException;
import io.github.novacrypto.bip39.Validation.WordNotFoundException;
import io.github.novacrypto.bip39.wordlists.English;

public class CryptoModule extends ReactContextBaseJavaModule {

    private final ReactApplicationContext reactContext;

    public CryptoModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;
    }

    @Override
    public String getName() {
        return "Crypto";
    }

    @ReactMethod
    public void generateMnemonic(int length, Promise p) {
        byte[] entropy = new byte[length / 8];
        new SecureRandom().nextBytes(entropy);
        Mnemonic mnemonic = new Mnemonic(entropy);
        p.resolve(mnemonic.GetSentence());
    }

    @ReactMethod
    public void mnemonicIsValid(String mnemonic, Promise p) {
        try {
            MnemonicValidator.ofWordList(English.INSTANCE).validate(mnemonic);
            p.resolve(1);
        } catch (UnexpectedWhiteSpaceException e) {
            p.resolve(0);
        } catch (InvalidWordCountException e) {
            p.resolve(0);
        } catch (InvalidChecksumException e) {
            p.resolve(0);
        } catch (WordNotFoundException e) {
            p.resolve(0);
        }
    }

    @ReactMethod
    public void createHDKeyPair(String mnemonic, String passphrase, String path, int index, Promise p) {
        byte[] seed2 = new Mnemonic(mnemonic).GetSeed(passphrase);
        KeyDerivation key = KeyDerivation.createFromSeed(seed2);
        String pathFormated = path.replace("/index", "");
        KeyDerivation child = key.derive(pathFormated);
        if (child == null) {
            p.reject("PATH_NOT_SUPPORTED", "Path is not supported");
        } else {
            ECPoint ecPoint = child.derive(index).getKey();
            String priKey = ecPoint.getPrivateKeyHex();
            String pubKey = ecPoint.getPublicKeyHex();
            WritableMap mapResult = Arguments.createMap();
            mapResult.putString("private_key", priKey);
            mapResult.putString("public_key", pubKey);
            p.resolve(mapResult);
        }

    }

    @ReactMethod
    public void createHDKeyPairs(String mnemonic, String passphrase, String path, int from, int to, Promise p) {
        byte[] seed2 = new Mnemonic(mnemonic).GetSeed(passphrase);
        String Seed_Str = Mnemonic.bytesToHex(seed2);
        System.out.println("ahihi" + seed2 + Seed_Str);
        KeyDerivation key = KeyDerivation.createFromSeed(seed2);
        String pathFormated = path.replace("/index", "");
        KeyDerivation child = key.derive(pathFormated);
        if (child == null) {
            p.reject("PATH_NOT_SUPPORTED", "Path is not supported");
        } else {
            WritableArray results = Arguments.createArray();
            for (int i = from; i < to + 1; i++) {
                ECPoint ecPoint = child.derive(i).getKey();
                String priKey = ecPoint.getPrivateKeyHex();
                String pubKey = ecPoint.getPublicKeyHex();
                WritableMap mapResult = Arguments.createMap();
                mapResult.putString("private_key", priKey);
                mapResult.putString("public_key", pubKey);
                mapResult.putString("seed", Seed_Str);
                results.pushMap(mapResult);
            }
            p.resolve(results);
        }
    }
}
