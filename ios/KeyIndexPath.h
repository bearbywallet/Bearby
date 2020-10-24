//
//  KeyIndexPath.h
//  zilpayMobile
//
//  Created by Rinat on 24.10.2020.
//
#import <Foundation/Foundation.h>

@interface KeyIndexPath : NSObject
@property (nonatomic) UInt32 value;
@property (nonatomic) BOOL hardened;
-(instancetype)initWithValue:(UInt32)value hardened:(bool)hardened;
@end
