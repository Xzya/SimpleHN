//
//  AppDelegate.m
//  SimpleHN-objc
//
//  Created by James Eunson on 26/09/2015.
//  Copyright © 2015 JEON. All rights reserved.
//

#import "AppDelegate.h"
#import "StoryDetailViewController.h"
#import "Firebase.h"
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

@interface AppDelegate () <UISplitViewControllerDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // Override point for customization after application launch.
    id rootVC = self.window.rootViewController;
    NSLog(@"rootVC: %@", NSStringFromClass([rootVC class]));
    
//    SimpleHNSplitViewController *splitViewController =
//        (SimpleHNSplitViewController *)self.window.rootViewController;
//    
//    UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
//    navigationController.topViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem;
//    splitViewController.delegate = self;
//    
//    splitViewController.tabBarController = [splitViewController.viewControllers firstObject];
//    splitViewController.storyDetailViewController =
//        (StoryDetailViewController*)navigationController.topViewController;
    
    self.window.tintColor = [UIColor orangeColor];
    
    self.masterProgress = [NSProgress progressWithTotalUnitCount:0];
    
    [self updateNightMode];
    
    [Fabric with:@[[Crashlytics class]]];    
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Split view

- (BOOL)splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UIViewController *)secondaryViewController ontoPrimaryViewController:(UIViewController *)primaryViewController {
    
    if ([secondaryViewController isKindOfClass:[UINavigationController class]] && [[(UINavigationController *)secondaryViewController topViewController] isKindOfClass:[StoryDetailViewController class]] && ([(StoryDetailViewController *)[(UINavigationController *)secondaryViewController topViewController] detailItem] == nil)) {
        // Return YES to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
        return YES;
    } else {
        return NO;
    }
}

- (void)updateNightMode {
    if([[AppConfig sharedConfig] nightModeEnabled]) {
        
        if([DKNightVersionManager currentThemeVersion] != DKThemeVersionNight) {
            [DKNightVersionManager nightFalling];
        }
        
    } else {
        
        if([DKNightVersionManager currentThemeVersion] != DKThemeVersionNormal) {
            [DKNightVersionManager dawnComing];
        }
    }
}

@end
