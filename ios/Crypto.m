//
//  Crypto.m
//  zilpayMobile
//
//  Created by Rinat on 21.10.2020.
//

#import "AppDelegate.h"
#import "Crypto.h"
#import <TrezorCrypto/TrezorCrypto.h>

@implementation Crypto

// To export a module named CalendarManager
RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(signHash:(nonnull NSData *)hash privateKey:(nonnull NSData *)privateKey
                  resolver:(RCTPromiseResolveBlock)resolve) {
  NSMutableData *signature = [[NSMutableData alloc] initWithLength:65];
  uint8_t by = 0;
  ecdsa_sign_digest(&secp256k1, privateKey.bytes, hash.bytes, signature.mutableBytes, &by, nil);
  ((uint8_t *)signature.mutableBytes)[64] = by;

  resolve(signature);
}

RCT_EXPORT_METHOD(getPublicKeyFrom:(nonnull NSData *)privateKey
                  resolver:(RCTPromiseResolveBlock)resolve) {
  NSMutableData *publicKey = [[NSMutableData alloc] initWithLength:65];
  ecdsa_get_public_key65(&secp256k1, privateKey.bytes, publicKey.mutableBytes);
  
  resolve(publicKey);
}

RCT_EXPORT_METHOD(deriveSeedFromMnemonic:(nonnull NSString *)mnemonic passphrase:(nonnull NSString *)passphrase
                  resolver:(RCTPromiseResolveBlock)resolve) {
  uint8_t seed[512 / 8];
  mnemonic_to_seed([mnemonic cStringUsingEncoding:NSUTF8StringEncoding], [passphrase cStringUsingEncoding:NSUTF8StringEncoding], seed, nil);
  
  resolve([[NSData alloc] initWithBytes:seed length:512 / 8]);
}

RCT_EXPORT_METHOD(base58DecodeRaw:(nonnull NSString *)string
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
  const char *str = [string cStringUsingEncoding:NSUTF8StringEncoding];

  size_t len = 128;
  size_t res = len;
  uint8_t buff[len];

  if (b58tobin(buff, &res, str) != true) {
    NSError *error = nil;

    reject(@"b58tobin_fail", @"b58tobin failed", error);
  }

  resolve([[NSData alloc] initWithBytes:buff + len - res length:res]);
}

RCT_EXPORT_METHOD(isValidMnemonic:(NSString *)mnemonic
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
  if (mnemonic == nil) {
    NSError *error = nil;

    reject(@"mnemonic_fail", @"mnemonic failed", error);
  } else {
    const char *csmnemonic = [mnemonic cStringUsingEncoding:NSUTF8StringEncoding];
    const int *isValid = mnemonic_check(csmnemonic);

    NSNumber *checked = [NSNumber numberWithInt:isValid];

    resolve(checked);
  }
}

RCT_EXPORT_METHOD(generateMnemonic:(NSInteger *)strength
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
  if (strength == nil) {
    NSError *error = nil;

    reject(@"strength_fail", @"strength failed", error);
  } else {
    const char *cstring = mnemonic_generate((int)strength);
  
    resolve([[NSString alloc] initWithCString:cstring encoding:NSUTF8StringEncoding]);
  }
}

@end
