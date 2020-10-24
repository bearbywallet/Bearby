//
//  KeyDerivation.m
//  zilpayMobile
//
//  Created by Rinat on 24.10.2020.
//

#import <TrezorCrypto/TrezorCrypto.h>
#import "KeyDerivation.h"
#import "KeyIndexPath.h"
#import "HDKeyPair.h"


@implementation KeyDerivation {
  NSArray<KeyIndexPath*> *indexes;
  HDNode currentNode;
}

- (instancetype)initWithPath:(NSString *)path {
  if (self = [self init]) {
    self.path = [path stringByReplacingOccurrencesOfString:@"/index" withString:@""];
    indexes = [self parsePath:self.path];
    if (indexes == NULL) return NULL;
  }
  
  return self;
}

-(NSArray *)parsePath:(NSString *)path {
  NSMutableArray<KeyIndexPath*> *result = [[NSMutableArray alloc] init];
  NSArray *components = [path componentsSeparatedByString:@"/"];
  
  for (NSString *component in components) {
    if ([component isEqualToString:@"m"]) continue;
    
    UInt32 value = 0;
    BOOL hardened = NO;
    
    if ([component hasSuffix:@"'"]) {
      value = [[component stringByReplacingOccurrencesOfString:@"'" withString:@""] intValue];
      hardened = YES;
    } else {
      value = [component intValue];
      hardened = NO;
    }
    
    KeyIndexPath *kd = [[KeyIndexPath alloc] initWithValue:value hardened:hardened];
    [result addObject:kd];
  }
  
  return result;
}

- (KeyDerivation *)derivePathFromSeed:(NSData *)seed {
  HDNode node;
  hdnode_from_seed(seed.bytes, (int)seed.length, "secp256k1", &node);
  
  for (KeyIndexPath *indexPath in indexes) {
    hdnode_private_ckd(&node, indexPath.value);
  }
  
  currentNode = node;
  return self;
}

- (HDKeyPair *)keyAt:(UInt32)index {
  if (currentNode.curve == NULL) return NULL;

  HDNode cNode = currentNode;
  hdnode_private_ckd(&cNode, index);
  return [HDKeyPair fromHDNode:cNode];
}
@end
