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

//RCT_EXPORT_METHOD(isValidMnemonic:(NSString *)mnemonic
//                  resolver:(RCTPromiseResolveBlock)resolve
//                  rejecter:(RCTPromiseRejectBlock)reject) {
//  const char *str = [mnemonic cStringUsingEncoding:NSUTF8StringEncoding];
//
//  resolve(str);
//
////  resolve([mnemonic_check([mnemonic cStringUsingEncoding:NSUTF8StringEncoding])]);
//}

@end
