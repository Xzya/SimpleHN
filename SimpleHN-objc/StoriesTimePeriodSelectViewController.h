//
//  StoriesTimePeriodSelectViewController.h
//  SimpleHN-objc
//
//  Created by James Eunson on 26/11/2015.
//  Copyright © 2015 JEON. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, StoriesTimePeriods) {
    StoriesTimePeriodsNoPeriod,
    StoriesTimePeriodsNow,
    StoriesTimePeriodsLast24hrs,
    StoriesTimePeriodsPastWeek,
    StoriesTimePeriodsPastMonth,
    StoriesTimePeriodsPastYear,
    StoriesTimePeriodsAllTime
};

#define kTimePeriodsLookup @{ @(StoriesTimePeriodsNoPeriod): @"None", @(StoriesTimePeriodsNow): @"Now", @(StoriesTimePeriodsLast24hrs): @"Last 24hrs", @(StoriesTimePeriodsPastWeek): @"Past Week", @(StoriesTimePeriodsPastMonth): @"Past Month", @(StoriesTimePeriodsPastYear): @"Past Year", @(StoriesTimePeriodsAllTime): @"All Time" }

#define kTimePeriods @[ @(StoriesTimePeriodsNow), @(StoriesTimePeriodsLast24hrs), @(StoriesTimePeriodsPastWeek), @(StoriesTimePeriodsPastMonth), @(StoriesTimePeriodsPastYear), @(StoriesTimePeriodsAllTime) ]

#define kSearchTimePeriods @[ @(StoriesTimePeriodsNoPeriod), @(StoriesTimePeriodsLast24hrs), @(StoriesTimePeriodsPastWeek), @(StoriesTimePeriodsPastMonth), @(StoriesTimePeriodsPastYear), @(StoriesTimePeriodsAllTime) ]

@protocol StoriesTimePeriodSelectViewController;
@interface StoriesTimePeriodSelectViewController : UITableViewController

@property (nonatomic, assign) NSInteger selectedPeriodIndex;
@property (nonatomic, strong) NSIndexPath * lastPeriodSelected;

@property (nonatomic, assign) __unsafe_unretained id<StoriesTimePeriodSelectViewController> delegate;

@end

@protocol StoriesTimePeriodSelectViewController <NSObject>
- (void)storiesTimePeriodSelectViewController:(StoriesTimePeriodSelectViewController*)controller
                    didChangeSelectedTimePeriod:(NSNumber*)period;
- (void)storiesTimePeriodSelectViewControllerDidCancelSelect:(StoriesTimePeriodSelectViewController*)controller;
@end