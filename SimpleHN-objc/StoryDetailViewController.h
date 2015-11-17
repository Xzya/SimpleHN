//
//  DetailViewController.h
//  SimpleHN-objc
//
//  Created by James Eunson on 26/09/2015.
//  Copyright © 2015 JEON. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Firebase.h"
#import "CommentCell.h"
#import "Story.h"

//UITableViewDataSource, UITableViewDelegate, 
@interface StoryDetailViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, CommentCellDelegate>

@property (nonatomic, strong) UITableView * tableView;
@property (nonatomic, strong) Story * detailItem;

@end

