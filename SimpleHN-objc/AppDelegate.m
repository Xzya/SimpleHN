//
//  AppDelegate.m
//  SimpleHN-objc
//
//  Created by James Eunson on 26/09/2015.
//  Copyright © 2015 JEON. All rights reserved.
//

#import "AppDelegate.h"
#import "DetailViewController.h"

#import "Firebase.h"

@interface AppDelegate () <UISplitViewControllerDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
    UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
    navigationController.topViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem;
    splitViewController.delegate = self;
    
    [[UIView appearance] setTintColor:[UIColor orangeColor]];
    
//    Firebase *ref = [[Firebase alloc] initWithUrl:@"https://hacker-news.firebaseio.com/v0/"];
//    __block Firebase *itemRef = nil;
//    FQuery *topStories = [[ref childByAppendingPath:@"topstories"] queryLimitedToFirst:25];
////    Firebase *firstStory = [topStories childByAppendingPath:@"0"];
//    
//    [topStories observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
//        
//        if(snapshot.hasChildren) {
//            NSEnumerator * children = snapshot.children;
//            for(FDataSnapshot * child in children) {
//                
//                NSString *itemId = [NSString stringWithFormat:@"item/%@", child.value];
//                itemRef = [ref childByAppendingPath:itemId];
//                [itemRef observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *itemSnap) {
//                    NSLog(@"%@", itemSnap.value);
//                }];
//                
//                break;
//            }
//        }
//    }];
    
//    FirebaseHandle handle = [firstStory observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
//        if(itemRef != nil) {
//            [itemRef removeObserverWithHandle: handle];
//        }
//        NSString *itemId = [NSString stringWithFormat:@"item/%@",snapshot.value];
//        itemRef = [ref childByAppendingPath:itemId];
//        [itemRef observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *itemSnap) {
//            NSLog(@"%@", itemSnap.value);
//        }];
//    }];
    
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
    if ([secondaryViewController isKindOfClass:[UINavigationController class]] && [[(UINavigationController *)secondaryViewController topViewController] isKindOfClass:[DetailViewController class]] && ([(DetailViewController *)[(UINavigationController *)secondaryViewController topViewController] detailItem] == nil)) {
        // Return YES to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
        return YES;
    } else {
        return NO;
    }
}

@end
