//
//  HDKeyPair.h
//  zilpayMobile
//
//  Created by Rinat on 24.10.2020.
//

#import <Foundation/Foundation.h>
#import <TrezorCrypto/TrezorCrypto.h>

@interface HDKeyPair : NSObject
+(instancetype)fromHDNode:(HDNode)node;
-(NSData *)privateKeyData;
-(NSData *)publicKeyData;
-(NSString *)privateKey;
-(NSString *)publicKey;
@end
