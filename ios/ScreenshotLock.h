//
//  ScreenshotLock.h
//  zilpayMobile
//
//  Created by Rinat on 09.01.2021.
//

#import <React/RCTEventEmitter.h>
#import <React/RCTBridgeModule.h>

@interface ScreenshotLock : RCTEventEmitter <RCTBridgeModule>

- (void)setupAndListen:(RCTBridge*)bridge;
- (void)screenshotDetected:(NSNotification*)notification;

@end
