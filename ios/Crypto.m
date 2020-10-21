//
//  Crypto.m
//  zilpayMobile
//
//  Created by Rinat on 21.10.2020.
//

#import "AppDelegate.h"
#import "Crypto.h"
#import <React/RCTLog.h>
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

// This would name the module AwesomeCalendarManager instead
// RCT_EXPORT_MODULE(AwesomeCalendarManager);

@end
