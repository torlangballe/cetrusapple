//
//  ZObjC.h
//  capsulefm
//
//  Created by Tor Langballe on /11/5/16.
//  Copyright © 2016 Capsule.fm. All rights reserved.
//

#ifndef ZOBJC_M
#define ZOBJC_M

#import "CoreImage/CoreImage.h"

extern CIDetector* ZOpenFaceDetector(NSDictionary<NSString *,id> *opts);
extern void DoFabricStuff(void);

#endif
/* ZObjC_h */
