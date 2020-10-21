//
//  Crypto.m
//  zilpayMobile
//
//  Created by Rinat on 21.10.2020.
//

#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>
#import <TrezorCrypto/TrezorCrypto.h>

@interface RCT_EXTERN_MODULE(Crypto, NSObject)
RCT_EXTERN_METHOD(mnemonic_generate:(NSInteger *)strength)
@end
