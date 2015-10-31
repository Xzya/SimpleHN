//
//  DetailViewController.h
//  SimpleHN-objc
//
//  Created by James Eunson on 26/09/2015.
//  Copyright © 2015 JEON. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Firebase.h"
#import "FirebaseUI.h"

@interface DetailViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) id detailItem;
@property (nonatomic, strong) UITableView * tableView;

//@property (strong, nonatomic) FirebaseTableViewDataSource *dataSource;

@end

