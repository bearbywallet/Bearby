//
//  Crypto.m
//  zilpayMobile
//
//  Created by Rinat on 21.10.2020.
//

#import <React/RCTLog.h>
#import "Crypto.h"
#import "Mnemonic.h"
#import "KeyDerivation.h"
#import "KeyIndexPath.h"
#import "HDKeyPair.h"

@implementation Crypto

- (dispatch_queue_t)methodQueue
{
    return dispatch_queue_create("wallet.golden.keystore_queue", DISPATCH_QUEUE_CONCURRENT);
}

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(generateMnemonic:(NSInteger)length
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    resolve([Mnemonic generateRandomWithStrength:(int)length].value);
}

RCT_EXPORT_METHOD(fromMnemonic:(NSString *)mnemonic
                  passphrase:(NSString *)passphrase
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    resolve([Mnemonic fromMnemonic:mnemonic passphrase:passphrase].value);
}

RCT_EXPORT_METHOD(mnemonicIsValid:(NSString *)mnemonic
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    resolve([Mnemonic isValid:mnemonic] ? @"1" : @"0");
}

RCT_EXPORT_METHOD(createHDKeyPair:(NSString *)mnemonic
                  passphrase:(NSString *)passphrase
                  path:(NSString *)path
                  index:(NSInteger)index
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        Mnemonic *m = [Mnemonic fromMnemonic:mnemonic passphrase:passphrase];
        KeyDerivation *kd = [m keyDerivationWithPath:path];

        if (kd == NULL) return reject(@"PATH_NOT_SUPPORTED", @"Path is not supported", NULL);
        
        HDKeyPair *key = [[kd derivePathFromSeed:m.seed] keyAt:(int)index];
        NSDictionary *result = [NSDictionary dictionaryWithObjectsAndKeys:[key privateKey], @"private_key", [key publicKey], @"public_key", nil];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            resolve(result);
        });
    });
}

RCT_EXPORT_METHOD(createHDKeyPairs:(NSString *)mnemonic
                  passphrase:(NSString *)passphrase
                  path:(NSString *)path
                  from:(NSInteger)fromIndex
                  to:(NSInteger)toIndex
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    Mnemonic *m = [Mnemonic fromMnemonic:mnemonic passphrase:passphrase];
    KeyDerivation *kd = [m keyDerivationWithPath:path];

    if (kd == NULL) return reject(@"PATH_NOT_SUPPORTED", @"Path is not supported", NULL);

    NSMutableArray *result = [[NSMutableArray alloc] init];

    kd = [kd derivePathFromSeed:m.seed];
    for (NSInteger i = fromIndex; i <= toIndex; i++) {
        HDKeyPair *key = [kd keyAt:(int)i];
        NSDictionary *keyDict = [NSDictionary dictionaryWithObjectsAndKeys:[key privateKey], @"private_key", [key publicKey], @"public_key", nil];
        [result addObject: keyDict];
    }

    resolve(result);

}

@end
