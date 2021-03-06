//
//  SimpleHN-objc.h
//  SimpleHN-objc
//
//  Created by James Eunson on 2/11/2015.
//  Copyright © 2015 JEON. All rights reserved.
//

#ifndef SimpleHN_h
#define SimpleHN_h

#import "AppDelegate.h"

#import "SimpleHNSplitViewController.h"
#import "LabelHelper.h"

#import "JBNSLayoutConstraint+LinearEquation.h"
#import "JBNSLayoutConstraint+Install.h"

#import "HNAlgoliaAPIManager.h"
#import "DKNightVersion.h"

#import "AppConfig.h"
#import "NSURL+HNInternalURL.h"
#import "HNItemHelper.h"

#import "HNSessionAPIManager.h"
#import "UIViewController+ErrorAlert.h"

#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

#define kProgressBarTag 51381
#define kProgressBarHeight 2.0f

#define kNightDefaultColor UIColorFromRGB(0x000000)
#define kNightDefaultBorderColor UIColorFromRGB(0x555555)

// Three20 RGBColor macro
#define RGBCOLOR(r,g,b) [UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f alpha:1]

#define kLoginURL @"https://news.ycombinator.com/login?goto=news"

#endif /* SimpleHN_h */
