//
//  LockNotification.m
//  capsulefm
//
//  Created by Tor Langballe on /11/5/16.
//  Copyright © 2016 Capsule.fm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UILocalNotification.h>

#import "notify.h"
#import "ZObjC.Apple.h"

/*
@implementation GeneralNSObject

#pragma GCC diagnostic ignored "-Wundeclared-selector"

+ (void)registerAppforDetectLockState:(id)target {
    
    int notify_token;
    notify_register_dispatch("com.apple.springboard.lockstate", &notify_token,dispatch_get_main_queue(), ^(int token) {
        
        uint64_t state = UINT64_MAX;
        notify_get_state(token, &state);
        if (state == 1) {
            [target performSelector:@selector(HandleScreenLocked)];
        } else {
            [target performSelector:@selector(HandleScreenUnlocked)];
        }
    });
}
@end
*/

CIDetector* ZOpenFaceDetector(NSDictionary<NSString *,id> *opts) {
    return [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:opts];
}
