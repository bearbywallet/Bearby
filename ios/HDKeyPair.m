//
//  HDKeyPair.m
//  zilpayMobile
//
//  Created by Rinat on 24.10.2020.
//

#import "HDKeyPair.h"
#import "Data+HexString.h"

@implementation HDKeyPair {
  HDNode _node;
}

-(instancetype)initWithHDNode:(HDNode)node {
  if (self = [self init]) {
    _node = node;
  }
  
  return self;
}

+ (instancetype)fromHDNode:(HDNode)node {
  HDKeyPair *keypair = [[HDKeyPair alloc] initWithHDNode:node];
  return keypair;
}

- (NSData *)privateKeyData {
  return [NSData dataWithBytes:_node.private_key length:sizeof(_node.private_key)];
}

- (NSData *)publicKeyData {
  NSUInteger length = 512/8;
//  uint8_t *key = malloc(length);
//  memset(key, 0, length);
  uint8_t *key = (uint8_t *)[NSMutableData dataWithLength:length].bytes;
  
  ecdsa_get_public_key65(_node.curve->params, [self privateKeyData].bytes, key);
  NSData *keyData = [NSData dataWithBytes:key length:length];

  return keyData;
}

- (NSString *)privateKey {
  return [[self privateKeyData] hexString];
}

- (NSString *)publicKey {
  return [[self publicKeyData] hexString];
}

@end
