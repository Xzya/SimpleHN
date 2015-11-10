//
//  AskHNViewController.m
//  SimpleHN-objc
//
//  Created by James Eunson on 10/11/2015.
//  Copyright © 2015 JEON. All rights reserved.
//

#import "AskHNViewController.h"

@implementation AskHNViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Ask";
    
    Firebase * askStoriesRef = [[Firebase alloc] initWithUrl:
                                @"https://hacker-news.firebaseio.com/v0/askstories"];
    [self loadStoryIdentifiersWithRef:askStoriesRef];
}

@end
