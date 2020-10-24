//
//  KeyDerivation.h
//  zilpayMobile
//
//  Created by Rinat on 24.10.2020.
//
#import <Foundation/Foundation.h>
@class HDKeyPair;

@interface KeyDerivation : NSObject
@property (strong, nonatomic) NSString *path;
-(instancetype)initWithPath:(NSString *)path;
-(KeyDerivation *)derivePathFromSeed:(NSData *)seed;
-(HDKeyPair *)keyAt:(UInt32)index;
@end
