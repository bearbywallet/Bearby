//
//  Mnemonic.m
//  zilpayMobile
//
//  Created by Rinat on 24.10.2020.
//

#import <TrezorCrypto/TrezorCrypto.h>
#import "Mnemonic.h"
#import "KeyDerivation.h"

@implementation Mnemonic
-(instancetype)initWithString:(NSString *)value seed:(NSData *)seed {
  if (self = [self init]) {
    self.value = value;
    self.seed = seed;
  }
  return self;
}

+ (instancetype)generateRandomWithStrength:(int)strength {
  const char *rawStr = mnemonic_generate(strength);
  NSString *str = [NSString stringWithCString:rawStr encoding:NSASCIIStringEncoding];
  NSData *seed = [Mnemonic deriveSeedString:str passphrase:@""];
  
  return [[Mnemonic alloc] initWithString:str seed:seed];
}

+ (instancetype)fromMnemonic:(NSString *)mnemonic passphrase:(NSString *)passphrase {
  NSData *seed = [Mnemonic deriveSeedString:mnemonic passphrase:passphrase];
  return [[Mnemonic alloc] initWithString:mnemonic seed:seed];
}

+ (instancetype)fromDataSeed:(NSData *)seed {
  const char *mnemonicChar = mnemonic_from_data(seed.bytes, (int)seed.length);
  NSString *str = [NSString stringWithCString:mnemonicChar encoding:NSASCIIStringEncoding];
  return [[Mnemonic alloc] initWithString:str seed:seed];
}


+ (NSData *)deriveSeedString:(NSString *)mnemonic passphrase:(NSString *)password {
  NSUInteger length = 512/8;
//  uint8_t *seed = malloc(length);
//  memset(seed, 0, length);
  uint8_t *seed = (uint8_t *)[NSMutableData dataWithLength:length].bytes;
  
  const char *mnemonicChar = [mnemonic cStringUsingEncoding:NSASCIIStringEncoding];
  const char *passChar = [password cStringUsingEncoding:NSASCIIStringEncoding];
  mnemonic_to_seed(mnemonicChar, passChar, seed, nil);

  return [NSData dataWithBytes:seed length:length];
}

+ (BOOL)isValid:(NSString *)mnemonic {
  const char *mnemonicChar = [mnemonic cStringUsingEncoding:NSASCIIStringEncoding];
  return mnemonic_check(mnemonicChar) != 0;
}

- (KeyDerivation *)keyDerivationWithPath:(NSString *)path {
  return [[KeyDerivation alloc] initWithPath:path];
}
@end
