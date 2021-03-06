//
//  DetailViewController.m
//  SimpleHN-objc
//
//  Created by James Eunson on 26/09/2015.
//  Copyright © 2015 JEON. All rights reserved.
//

#import "StoryDetailViewController.h"
#import "Story.h"
#import "UserViewController.h"
#import "ActionDrawerButton.h"
#import "RegexKitLite.h"
#import "StoryCommentsNoCommentsCell.h"
#import "StoryCommentsContentLoadingCell.h"
#import "SimpleHNWebViewController.h"
#import "StoryDetailNoContentSelectedTableViewCell.h"
#import "StoryLoadingMoreCommentsCell.h"

#define kStoryCellReuseIdentifier @"storyCellReuseIdentifier"
#define kCommentCellReuseIdentifier @"commentCellReuseIdentifier"
#define kNoCommentsReuseIdentifier @"noCommentsReuseIdentifier"

#define kStoryCommentsContentLoadingCellReuseIdentifier @"storyCommentsContentLoadingCellReuseIdentifier"

#define kStoryLoadingMoreCommentsCellReuseIdentifier @"storyLoadingMoreCommentsCellReuseIdentifier"
#define kNoContentSelectedCellReuseIdentifier @"noContentSelectedCellReuseIdentifier"

//@import WebKit;

@interface StoryDetailViewController ()

@property (nonatomic, assign) StoryDetailViewControllerLoadStatus loadStatus;
@property (nonatomic, strong) NSProgress * loadingProgress;
@property (nonatomic, strong) NSDateFormatter * refreshDateFormatter;

@property (nonatomic, strong) UIColor * defaultSeparatorColor;
@property (nonatomic, assign) BOOL commentCollapseExpandBeginUpdatesOpen;

- (void)loadContent;

- (void)reloadContent:(id)sender;

- (void)commentCreated:(NSNotification*)notification;

- (void)commentCollapsedStarted:(NSNotification*)notification;
- (void)commentCollapsedChanged:(NSNotification*)notification;
- (void)commentCollapsedComplete:(NSNotification*)notification;

- (void)commentExpandedStarted:(NSNotification*)notification;
- (void)commentExpandedChanged:(NSNotification*)notification;
- (void)commentExpandedComplete:(NSNotification*)notification;

- (void)storyCommentsUpdated:(NSNotification*)notification;

- (void)expandCollapseCommentForRow:(NSIndexPath *)indexPath;

- (Comment*)checkCorrectStoryForCollapseExpandNotification:(NSNotification*)notification;

- (void)configureViewForStory;
- (void)configureViewForComment;

- (void)nightModeEvent:(NSNotification*)notification;
- (void)updateNightMode;

@end

@implementation StoryDetailViewController

#pragma mark - Managing the detail item

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)awakeFromNib {
    
    _commentCollapseExpandBeginUpdatesOpen = NO;
    
    self.loadStatus = StoryDetailViewControllerLoadStatusNotLoaded;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(commentCreated:)
                                                 name:kCommentCreated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(storyCommentsUpdated:)
                                                 name:kStoryCommentsUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(commentCollapsedStarted:)
                                                 name:kCommentCollapsedStarted object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(commentCollapsedChanged:)
                                                 name:kCommentCollapsedChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(commentCollapsedComplete:)
                                                 name:kCommentCollapsedComplete object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(commentExpandedStarted:)
                                                 name:kCommentExpandedStarted object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(commentExpandedChanged:)
                                                 name:kCommentExpandedChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(commentExpandedComplete:)
                                                 name:kCommentExpandedComplete object:nil];
    
    self.refreshDateFormatter = [[NSDateFormatter alloc] init];
    [_refreshDateFormatter setDateFormat:@"MMM d, h:mm a"];
    NSLocale * locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    _refreshDateFormatter.locale = locale;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(nightModeEvent:)
                                                 name:DKNightVersionNightFallingNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(nightModeEvent:)
                                                 name:DKNightVersionDawnComingNotification object:nil];
}

- (void)loadView {
    [super loadView];
    
    self.navigationController.delegate = self;
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    [self.tableView registerClass:[StoryCell class]
           forCellReuseIdentifier:kStoryCellReuseIdentifier];
    
    [self.tableView registerClass:[CommentCell class]
           forCellReuseIdentifier:kCommentCellReuseIdentifier];
    
    [self.tableView registerClass:[StoryCommentsNoCommentsCell class]
           forCellReuseIdentifier:kNoCommentsReuseIdentifier];

    [self.tableView registerClass:[StoryCommentsContentLoadingCell class]
           forCellReuseIdentifier:kStoryCommentsContentLoadingCellReuseIdentifier];
    
    [self.tableView registerClass:[StoryLoadingMoreCommentsCell class]
           forCellReuseIdentifier:kStoryLoadingMoreCommentsCellReuseIdentifier];
    
    [self.tableView registerClass:[StoryDetailNoContentSelectedTableViewCell class]
           forCellReuseIdentifier:kNoContentSelectedCellReuseIdentifier];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.backgroundColor = [UIColor whiteColor];
    self.refreshControl.tintColor = [UIColor grayColor];
    [self.refreshControl addTarget:self
                            action:@selector(reloadContent:)
                  forControlEvents:UIControlEventValueChanged];
    
    [self updateNightMode];
}

- (void)setDetailItem:(Story*)newDetailItem {
    if (_detailItem != newDetailItem) {
        
        self.loadStatus = StoryDetailViewControllerLoadStatusLoadingStory;
        [self.tableView reloadData];
        
        if(newDetailItem.algoliaResult) {
            
            [Story createStoryFromItemIdentifier:newDetailItem.storyId completion:^(Story *story) {
                _detailItem = [story copy];
                _detailItem.sizeStatus = StorySizeStatusExpanded;
                
                [self.tableView reloadData];
                [self configureViewForStory];
            }];
            
        } else {
            _detailItem = [newDetailItem copy];
            _detailItem.sizeStatus = StorySizeStatusExpanded;
            
            [self.tableView reloadData];
            [self configureViewForStory];
        }
    }
}

- (void)setDetailComment:(Comment *)newDetailComment {
    if (_detailComment != newDetailComment) {
        
        _detailComment = [newDetailComment copy];
        self.loadStatus = StoryDetailViewControllerLoadStatusLoadingStory;
        
        [self.tableView reloadData];
        [self configureViewForComment];
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
         self.tableView.contentInset = UIEdgeInsetsMake(self.navigationController
                                                        .navigationBar.frame.size.height, 0, 0, 0);
    } completion:nil];
    
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

- (void)configureViewForStory {
    
    self.title = _detailItem.title;
    [self loadContent];
}

- (void)configureViewForComment {
    NSLog(@"configureViewForComment stub");
    
    // Find root item (the story) by traversing upwards
    [self.detailComment findStoryForComment:^(Story *story) {
        NSLog(@"root: %@", story);
        self.detailItem = story;
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
    self.navigationItem.leftItemsSupplementBackButton = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.view addSubview:[ProgressBarView sharedProgressBarView]];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[ProgressBarView sharedProgressBarView] removeFromSuperview];
}

#pragma mark - UITableViewDataSource Methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if(_loadStatus == StoryDetailViewControllerLoadStatusLoadingComments
       || _loadStatus == StoryDetailViewControllerLoadStatusLoadingCommentsFirstCommentLoaded
       || _loadStatus == StoryDetailViewControllerLoadStatusLoaded) {
        
        if(section == 0) {
            return 1;
            
        } else {
            
            if(_loadStatus == StoryDetailViewControllerLoadStatusLoadingComments) {
                return 1;
                
            } else if(_loadStatus == StoryDetailViewControllerLoadStatusLoadingCommentsFirstCommentLoaded) {
                return 2;
                
            } else {
                
                NSInteger commentCount = [_detailItem.flatVisibleDisplayComments count];
                if(_loadStatus == StoryDetailViewControllerLoadStatusLoaded) {
                    return commentCount;
                } else {
                    return 1;
                }
            }
        }
        
    } else {
        return 1;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if(_loadStatus == StoryDetailViewControllerLoadStatusNotLoaded) {
        return 1;
        
    } else if(_loadStatus == StoryDetailViewControllerLoadStatusLoadingComments ||
              _loadStatus == StoryDetailViewControllerLoadStatusLoadingCommentsFirstCommentLoaded ||
              _loadStatus == StoryDetailViewControllerLoadStatusLoaded) {
        return 2;
        
    } else { // StoryDetailViewControllerLoadStatusLoadingStory, StoryDetailViewControllerLoadStatusLoadingComments, loading view
        return 1;
    }
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if(indexPath.section == 0) {
        if(_loadStatus == StoryDetailViewControllerLoadStatusLoaded ||
           _loadStatus == StoryDetailViewControllerLoadStatusLoadingCommentsFirstCommentLoaded ||
           _loadStatus == StoryDetailViewControllerLoadStatusLoadingComments) {
            
            StoryCell *cell = [tableView dequeueReusableCellWithIdentifier:
                               kStoryCellReuseIdentifier forIndexPath:indexPath];
            
            cell.story = self.detailItem;
            cell.storyCellDelegate = self;
            cell.contextType = StoryCellContextTypeDetail;
            
            return cell;
            
        } else if(_loadStatus == StoryDetailViewControllerLoadStatusLoadingStory) {
            
            StoryCommentsContentLoadingCell * cell = [tableView dequeueReusableCellWithIdentifier:
                                                      kStoryCommentsContentLoadingCellReuseIdentifier forIndexPath:indexPath];
            [cell.loadingView.loadingView startAnimating];
            return cell;
            
        } else {
            
            StoryDetailNoContentSelectedTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:
                                                                kNoContentSelectedCellReuseIdentifier forIndexPath:indexPath];
            return cell;
        }
        
    } else if(indexPath.section == 1) {
     
        if(_loadStatus == StoryDetailViewControllerLoadStatusLoaded ||
           (_loadStatus == StoryDetailViewControllerLoadStatusLoadingCommentsFirstCommentLoaded && indexPath.row == 0)) {
            
            if(_loadStatus == StoryDetailViewControllerLoadStatusLoadingCommentsFirstCommentLoaded) {
                Comment * comment = _detailItem.flatVisibleDisplayComments[indexPath.row];
                
                CommentCell * cell = [tableView dequeueReusableCellWithIdentifier:kCommentCellReuseIdentifier
                                                                     forIndexPath:indexPath];
                cell.comment = comment;
                cell.commentCellDelegate = self;
                
                return cell;
                
            } else {
             
                NSInteger commentCount = [_detailItem.flatVisibleDisplayComments count];
                
                if(commentCount == 0 && _loadStatus == StoryDetailViewControllerLoadStatusLoadingComments) {
                    StoryCommentsNoCommentsCell * cell = [tableView dequeueReusableCellWithIdentifier:kNoCommentsReuseIdentifier forIndexPath:indexPath];
                    return cell;
                    
                } else {
                    
                    Comment * comment = _detailItem.flatVisibleDisplayComments[indexPath.row];
                    
                    CommentCell * cell = [tableView dequeueReusableCellWithIdentifier:kCommentCellReuseIdentifier
                                                                         forIndexPath:indexPath];
                    cell.comment = comment;
                    cell.commentCellDelegate = self;
                    
                    return cell;
                }
            }
            
        } else if(_loadStatus == StoryDetailViewControllerLoadStatusLoadingCommentsFirstCommentLoaded && indexPath.row == 1) {

            StoryLoadingMoreCommentsCell *cell = [tableView dequeueReusableCellWithIdentifier:
                                       kStoryLoadingMoreCommentsCellReuseIdentifier forIndexPath:indexPath];
            [cell.loadingView startAnimating];
            return cell;
            
        } else if(_loadStatus == StoryDetailViewControllerLoadStatusLoadingComments) {
            
            StoryCommentsContentLoadingCell * cell = [tableView dequeueReusableCellWithIdentifier:
                                                      kStoryCommentsContentLoadingCellReuseIdentifier forIndexPath:indexPath];
            [cell.loadingView.loadingView startAnimating];            
            return cell;
        }
    }
    
    return [[UITableViewCell alloc] init];
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    return 88.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    
    if(indexPath.section == 0) {
        if(_loadStatus == StoryDetailViewControllerLoadStatusLoaded ||
           _loadStatus == StoryDetailViewControllerLoadStatusLoadingComments ||
           _loadStatus == StoryDetailViewControllerLoadStatusLoadingCommentsFirstCommentLoaded) {
            
            return [StoryCell heightForStoryCellWithStory:self.detailItem
                                                    width:tableView.frame.size.width context:StoryCellContextTypeDetail];
        } else {
            return tableView.frame.size.height - tableView.contentInset.top - tableView.contentInset.bottom;
        }
        
    } else if(indexPath.section == 1) {
        if(_loadStatus == StoryDetailViewControllerLoadStatusLoaded ||
           _loadStatus == StoryDetailViewControllerLoadStatusLoadingCommentsFirstCommentLoaded) {
            
            if(_loadStatus == StoryDetailViewControllerLoadStatusLoaded) {
                NSInteger commentCount = [_detailItem.flatVisibleDisplayComments count];
                if(commentCount == 0) {
                    CGFloat headerHeight = [StoryCell heightForStoryCellWithStory:self.detailItem
                                                                            width:tableView.frame.size.width];
                    return self.tableView.frame.size.height - headerHeight - self.tabBarController.tabBar.frame.size.height - self.navigationController.navigationBar.frame.size.height;
                    
                } else {
                    Comment * comment = _detailItem.flatVisibleDisplayComments[indexPath.row];
                    return [CommentCell heightForCommentCell:comment
                                                       width:tableView.frame.size.width];
                }
                
            } else {
                if(indexPath.row == 0) {
                    Comment * comment = _detailItem.flatVisibleDisplayComments[indexPath.row];
                    return [CommentCell heightForCommentCell:comment
                                                       width:tableView.frame.size.width];
                } else {
                    return 44.0f;
                }
            }
            
        } else if(_loadStatus == StoryDetailViewControllerLoadStatusLoadingComments) {
            
            CGFloat storyDetailHeight = [StoryCell heightForStoryCellWithStory:self.detailItem
                                                                         width:tableView.frame.size.width context:StoryCellContextTypeDetail];
            return tableView.frame.size.height - tableView.contentInset.top - tableView.contentInset.bottom - storyDetailHeight;
        }
    }
    
    return 0;
}

- (void)tableView:(UITableView *)tableView didHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if((_loadStatus == StoryDetailViewControllerLoadStatusLoaded) && indexPath.section == 1) {
        
        CommentCell * cell = [tableView cellForRowAtIndexPath:indexPath];

        if([[AppConfig sharedConfig] nightModeEnabled]) {
            cell.backgroundColor = UIColorFromRGB(0x222222);
            
        } else {
            cell.backgroundColor = [UIColor whiteColor];
        }
    }
}

- (void)tableView:(UITableView *)tableView didUnhighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if((_loadStatus == StoryDetailViewControllerLoadStatusLoaded) && indexPath.section == 1) {
        CommentCell * cell = [tableView cellForRowAtIndexPath:indexPath];
        
        if([[AppConfig sharedConfig] nightModeEnabled]) {
            cell.backgroundColor = kNightDefaultColor;
            
        } else {
            cell.backgroundColor = [UIColor whiteColor];
        }
    }
}

#pragma mark - UITableViewDelegate Methods
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if(_loadStatus == StoryDetailViewControllerLoadStatusLoaded) {
        
        if(indexPath.section == 0 && indexPath.row == 0) {
            
            if(self.detailItem.url) {
                [self performSegueWithIdentifier:@"showWeb" sender:nil];
            }
            
        } else {
            NSInteger commentCount = [_detailItem.flatVisibleDisplayComments count];
            if(commentCount > 0) {
                [self expandCollapseCommentForRow:indexPath];
            }
        }
    }
}

#pragma mark - UIScrollViewDelegate Methods
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [[ProgressBarView sharedProgressBarView] enclosingScrollViewDidScroll:scrollView];
}

#pragma mark - Private Methods
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if([[segue identifier] isEqualToString:@"showUser"]) {
        
        __block UserViewController *controller = nil;
        if([[segue destinationViewController] isKindOfClass:[UINavigationController class]]) {
            controller = (UserViewController *)[[segue destinationViewController] topViewController];
        } else {
            controller = (UserViewController *)[segue destinationViewController];
        }
        
        if(sender && [sender isKindOfClass:[NSString class]]) {
            controller.author = sender;
            
        } else if(sender && [sender isKindOfClass:[User class]]) {
            controller.user = sender;
        }
        
        controller.navigationItem.leftBarButtonItem =
            self.splitViewController.displayModeButtonItem;
        controller.navigationItem.leftItemsSupplementBackButton = YES;
        
    } else if([[segue identifier] isEqualToString:@"showDetail"]) {
        
        NSNumber * itemIdentifier = (NSNumber*)sender;
        
        __block StoryDetailViewController *controller = nil;
        if([[segue destinationViewController] isKindOfClass:[UINavigationController class]]) {
            controller = (StoryDetailViewController *)[[segue destinationViewController] topViewController];
        } else {
            controller = (StoryDetailViewController *)[segue destinationViewController];
        }
        
        NSString * itemURL = [NSString stringWithFormat:
                              @"https://hacker-news.firebaseio.com/v0/item/%@", itemIdentifier];
        __block Firebase * itemRef = [[Firebase alloc] initWithUrl:itemURL];
        [itemRef observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
            
            HNItemHelperIdentificationResult result = [HNItemHelper identifyHNItemWithSnapshotDictionary:
                                                       snapshot.value];
            if(result == HNItemHelperIdentificationResultComment) {
                [[Comment class] createCommentFromSnapshot:snapshot completion:^(Comment *comment) {
                    controller.detailComment = comment;
                }];
                
            } else if(result == HNItemHelperIdentificationResultStory) {
                [Story createStoryFromSnapshot:snapshot completion:^(Story *story) {
                    controller.detailItem = story;
                }];
                
            } else {
                NSLog(@"ERROR: Unrecognized or unsupported item type.");
            }
            [itemRef removeAllObservers];
        }];
        
        controller.navigationItem.leftBarButtonItem =
            self.splitViewController.displayModeButtonItem;
        controller.navigationItem.leftItemsSupplementBackButton = YES;
        
    } else if([[segue identifier] isEqualToString:@"showWeb"]) {
        
        SimpleHNWebViewController *controller = nil;
        if([[segue destinationViewController] isKindOfClass:[UINavigationController class]]) {
            controller = (SimpleHNWebViewController *)[[segue destinationViewController] topViewController];
        } else {
            controller = (SimpleHNWebViewController *)[segue destinationViewController];
        }
        
        if(sender && [sender isKindOfClass:[NSURL class]]) {
            controller.selectedURL = sender;
            
        } else {
            controller.selectedStory = self.detailItem;
        }
        
        controller.navigationItem.leftBarButtonItem =
            self.splitViewController.displayModeButtonItem;
        controller.navigationItem.leftItemsSupplementBackButton = YES;
    }
}

- (void)commentCreated:(NSNotification*)notification {
    
    if(self.loadingProgress.completedUnitCount < self.loadingProgress.totalUnitCount) {
        self.loadingProgress.completedUnitCount++;
    }
}

- (void)storyCommentsUpdated:(NSNotification*)notification {
    Story * story = notification.object;
    if(![story.storyId isEqual:self.detailItem.storyId]) {
        return;
    }

    [self.detailItem refreshVisibleDisplayComments];
    
    if(_loadStatus == StoryDetailViewControllerLoadStatusLoaded) {
        [self.tableView reloadData];
    }
    
    NSLog(@"storyCommentsUpdated, %lu of %@ expected",
          [self.detailItem.flatVisibleDisplayComments count],
          self.detailItem.totalCommentCount);
}

- (void)commentCollapsedStarted:(NSNotification*)notification {
    Comment * comment = nil;
    if(!(comment = [self checkCorrectStoryForCollapseExpandNotification:notification])) {
        return;
    }
    
    NSMutableDictionary * indexes = [[NSMutableDictionary alloc] init];
    
    // No cycles so we don't need seen array
    NSMutableArray * queue = [[NSMutableArray alloc] init];
    [queue addObject:comment];
    
    NSArray * visibleDisplayComments = [self.detailItem.flatDisplayComments filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id  _Nonnull evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        
        if(((Comment*)evaluatedObject).sizeStatus == CommentSizeStatusCollapsed) {
            return NO;
        }
        return YES;
    }]];
    
    while([queue count] > 0) {
        Comment * currentComment = [queue firstObject];
        [queue removeObject:currentComment];
        
        if(!currentComment.collapseExpandOrigin) {
            NSInteger index = [visibleDisplayComments indexOfObject:currentComment];
            if(index == NSNotFound) {
                NSLog(@"SHOULD NEVER HAPPEN, %@", indexes);
                //                abort();
                continue;
            }
            indexes[currentComment.commentId] = @(index);
        }

        for(Comment * child in [currentComment childComments]) {
            [queue addObject:child];
        }
    }
    comment.collapseExpandOriginIndexes = indexes;
    
    [self.tableView beginUpdates];
    _commentCollapseExpandBeginUpdatesOpen = YES;
}

- (void)commentCollapsedChanged:(NSNotification*)notification {
    Comment * comment = nil;
    if(!(comment = [self checkCorrectStoryForCollapseExpandNotification:notification])) {
        return;
    }
    
    if(comment.collapseExpandOrigin) {
        // TODO
        return;
    }
    
    if(comment.sizeStatus == CommentSizeStatusCollapsed) {
        NSDictionary * indexes = [Comment currentCollapseExpandOrigin].collapseExpandOriginIndexes;
        
        if(![[indexes allKeys] containsObject:comment.commentId]) {
            NSLog(@"SHOULD NEVER HAPPEN");
            return;
        }
        
        NSInteger commentIndex = [indexes[comment.commentId] integerValue];
        [self.tableView deleteRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:commentIndex inSection:1] ]
                              withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)commentCollapsedComplete:(NSNotification*)notification {
    
    Comment * comment = nil;
    if(!(comment = [self checkCorrectStoryForCollapseExpandNotification:notification])) {
        return;
    }
    
    if(_commentCollapseExpandBeginUpdatesOpen) {
        [self.detailItem refreshVisibleDisplayComments];
        
        [self.tableView endUpdates];
        _commentCollapseExpandBeginUpdatesOpen = NO;
    }
}

- (void)commentExpandedStarted:(NSNotification*)notification {
    Comment * comment = nil;
    if(!(comment = [self checkCorrectStoryForCollapseExpandNotification:notification])) {
        return;
    }
    
    NSMutableDictionary * indexes = [[NSMutableDictionary alloc] init];
    
    // No cycles so we don't need seen array
    NSMutableArray * queue = [[NSMutableArray alloc] init];
    [queue addObject:comment];
    
    NSInteger baseIndex = [self.detailItem.flatVisibleDisplayComments indexOfObject:comment];
    int i = 0;
    while([queue count] > 0) {
        Comment * currentComment = [queue firstObject];
        [queue removeObject:currentComment];
        
        if(!currentComment.collapseExpandOrigin) {
            indexes[currentComment.commentId] = @(baseIndex + i);
        }
        
        for(Comment * child in [currentComment childComments]) {
            [queue addObject:child];
        }
        i++;
    }
    
    comment.collapseExpandOriginIndexes = indexes;
    
    [self.tableView beginUpdates];
    _commentCollapseExpandBeginUpdatesOpen = YES;
}

- (void)commentExpandedChanged:(NSNotification*)notification {
    Comment * comment = nil;
    if(!(comment = [self checkCorrectStoryForCollapseExpandNotification:notification])) {
        return;
    }
    
    if(comment.collapseExpandOrigin) {
        return;
    }
    
    if(comment.sizeStatus == CommentSizeStatusNormal) {
        NSDictionary * indexes = [Comment currentCollapseExpandOrigin].collapseExpandOriginIndexes;
        
        if(![[indexes allKeys] containsObject:comment.commentId]) {
            NSLog(@"SHOULD NEVER HAPPEN");
            return;
        }
        
        NSInteger commentIndex = [indexes[comment.commentId] integerValue];
        [self.tableView insertRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:commentIndex inSection:1] ]
                              withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)commentExpandedComplete:(NSNotification*)notification {
    Comment * comment = nil;
    if(!(comment = [self checkCorrectStoryForCollapseExpandNotification:notification])) {
        return;
    }
    
    if(_commentCollapseExpandBeginUpdatesOpen) {
        [self.detailItem refreshVisibleDisplayComments];
        
        [self.tableView endUpdates];
        _commentCollapseExpandBeginUpdatesOpen = NO;
    }
}

- (Comment*)checkCorrectStoryForCollapseExpandNotification:(NSNotification*)notification {
    Comment * comment = nil;
    NSDictionary * userInfo = notification.userInfo;
    
    if([[userInfo allKeys] containsObject:kCommentCollapsedExpandedStartedChangedCompleteComment]) {
        comment = userInfo[kCommentCollapsedExpandedStartedChangedCompleteComment];
        if(![comment.storyId isEqual: self.detailItem.storyId]) {
            return nil;
        }
    }
    if(!comment) {
        return nil;
    }
    return comment;
}

- (void)loadContent {
    
    if(!_detailItem) {
        return;
    }
    
    Story * detailStory = (Story*)_detailItem;
    if(!detailStory.kids || [detailStory.kids count] == 0) {
        
        self.loadStatus = StoryDetailViewControllerLoadStatusLoaded;
        
        self.tableView.scrollEnabled = NO;
        [self.tableView reloadData]; // Display no comments cell
        
    } else {

        self.tableView.scrollEnabled = YES;
        
        [detailStory loadCommentsForStory];
        
        self.loadingProgress = [NSProgress progressWithTotalUnitCount:
                                ([detailStory.totalCommentCount intValue])];
        [self.loadingProgress addObserver:self forKeyPath:@"fractionCompleted"
                                  options:NSKeyValueObservingOptionNew context:NULL];
        
        NSProgress * masterProgress = ((AppDelegate *)[[UIApplication sharedApplication]
                                                       delegate]).masterProgress;
        
        masterProgress.completedUnitCount = 0;
        masterProgress.totalUnitCount = [detailStory.totalCommentCount intValue];
        
        [masterProgress addChild:self.loadingProgress withPendingUnitCount:
         [detailStory.totalCommentCount intValue]];
    }
}

- (void)reloadContent:(id)sender {
    
    [self loadContent];
}

- (void)nightModeEvent:(NSNotification*)notification {
    [self updateNightMode];
}

- (void)updateNightMode {
    
    if(!_defaultSeparatorColor) {
        _defaultSeparatorColor = self.tableView.separatorColor;
    }
    
    if([[AppConfig sharedConfig] nightModeEnabled]) {
        
        self.navigationController.navigationBar.barTintColor = kNightDefaultColor;
        self.tabBarController.tabBar.barTintColor = kNightDefaultColor;
        
        self.refreshControl.backgroundColor = kNightDefaultColor;
        self.view.backgroundColor = kNightDefaultColor;
        self.tableView.backgroundColor = kNightDefaultColor;
        
        self.tableView.separatorColor = UIColorFromRGB(0x555555);
        
        self.navigationController.navigationBar.titleTextAttributes =
            @{ NSForegroundColorAttributeName: [UIColor whiteColor] };
        
    } else {
        
        self.navigationController.navigationBar.barTintColor = nil;
        self.tabBarController.tabBar.barTintColor = nil;
        
        self.refreshControl.backgroundColor = UIColorFromRGB(0xffffff);
        self.view.backgroundColor = UIColorFromRGB(0xffffff);
        self.tableView.backgroundColor = UIColorFromRGB(0xffffff);
        
        self.tableView.separatorColor = _defaultSeparatorColor;
        
        self.navigationController.navigationBar.titleTextAttributes =
            @{ NSForegroundColorAttributeName: [UIColor blackColor] };
    }
    
    [self.tableView reloadData];
}

- (void)expandCollapseCommentForRow:(NSIndexPath *)indexPath {
    
    Comment * comment = _detailItem.flatVisibleDisplayComments[indexPath.row];
    
    NSArray * expandedCommentArray = [_detailItem.flatDisplayComments filteredArrayUsingPredicate:
        [NSPredicate predicateWithFormat:@"sizeStatus == %lu", CommentSizeStatusExpanded]];
    
    if([expandedCommentArray count] > 0) {
        Comment * expandedComment = [expandedCommentArray firstObject];
        expandedComment.sizeStatus = CommentSizeStatusNormal;
        
        // Job done, don't expand again
        if(comment == expandedComment) {
            [self.tableView beginUpdates];
            [self.tableView endUpdates];
            
            return;
        }
    }
    
    comment.sizeStatus = CommentSizeStatusExpanded;
    
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}

#pragma mark - Property Override Methods
- (void)setLoadStatus:(StoryDetailViewControllerLoadStatus)loadStatus {
    _loadStatus = loadStatus;
    
//    NSLog(@"StoryDetailViewControllerLoadStatus: %lu", loadStatus);
    
    if(_loadStatus == StoryDetailViewControllerLoadStatusLoaded) {
        NSLog(@"StoryDetailViewControllerLoadStatus: StoryDetailViewControllerLoadStatusLoaded");
    }
    
    if(_loadStatus == StoryDetailViewControllerLoadStatusLoaded ||
       _loadStatus == StoryDetailViewControllerLoadStatusLoadingCommentsFirstCommentLoaded) {
        
        self.tableView.scrollEnabled = YES;

    } else {
        self.tableView.scrollEnabled = NO;
    }
}

#pragma mark - CommentCellDelegate Methods
- (void)commentCell:(CommentCell*)cell didTapLink:(NSURL*)link {
    
    if([link isHNInternalLink]) {
        
        if([link isHNInternalItemLink]) {
            NSNumber * identifier = [link identifierForHNInternalItemLink];
            if(identifier) {
                [self performSegueWithIdentifier:@"showDetail" sender:identifier]; return;
            }
            
        } else if([link isHNInternalUserLink]) {
            NSString * username = [link usernameForHNInternalUserLink];
            if(username) {
                [self performSegueWithIdentifier:@"showUser" sender:username]; return;
            }
        }
    } // Catches two else cases implicitly
    
    NSLog(@"%@", link);
    [self performSegueWithIdentifier:@"showWeb" sender:link];
}

- (void)commentCell:(CommentCell*)cell didLongPressLink:(NSURL *)link {
    [CommentCell handleLongPressForLink:link inComment:cell.comment inController:self];
}

- (void)commentCell:(CommentCell*)cell didTapActionWithType:(NSNumber*)type {
    [CommentCell handleActionForComment:cell.comment withType:type inController:self];
}

#pragma mark - KVO Callback Methods
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {
    
    NSNumber * fractionCompleted = change[NSKeyValueChangeNewKey];
    
    [ProgressBarView sharedProgressBarView].progress = [fractionCompleted floatValue];
    
    if([fractionCompleted floatValue] > 0.0f && _loadStatus == StoryDetailViewControllerLoadStatusLoadingStory) {
        
        if([self.detailItem.comments count] >= 1) {
            if(self.loadStatus != StoryDetailViewControllerLoadStatusLoadingCommentsFirstCommentLoaded) {
                self.loadStatus = StoryDetailViewControllerLoadStatusLoadingCommentsFirstCommentLoaded;
                [self.tableView reloadData];
            }
            
        } else {
            if(self.loadStatus != StoryDetailViewControllerLoadStatusLoadingComments) {
                self.loadStatus = StoryDetailViewControllerLoadStatusLoadingComments;
                [self.tableView reloadData];
            }
        }
    }
    
    if([fractionCompleted floatValue] == 1.0f) {
        
        self.loadStatus = StoryDetailViewControllerLoadStatusLoaded;
        [self.tableView reloadData];
        
        [self.loadingProgress removeObserver:self
                                  forKeyPath:@"fractionCompleted"];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            Story * detailStory = (Story*)_detailItem;
            [detailStory finishLoadingCommentsForStory];
        });
        
        if(self.detailComment) {
            NSLog(@"snap to specified comment");
            
            NSArray * loadedTargetCommentArray = [self.detailItem.flatDisplayComments filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:
                                                                              @"commentId == %@", self.detailComment.commentId]];
            if([loadedTargetCommentArray count] > 0) {
                Comment * targetComment = [loadedTargetCommentArray firstObject];
                NSInteger targetCommentIndex = [self.detailItem.flatDisplayComments indexOfObject:targetComment];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    targetComment.sizeStatus = CommentSizeStatusExpanded;
                    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:targetCommentIndex inSection:1]]
                                          withRowAnimation:UITableViewRowAnimationAutomatic];
                    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:targetCommentIndex inSection:1]
                                          atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
                });
            }
        }
        
        NSString *title = [NSString stringWithFormat:@"Last update: %@", [self.refreshDateFormatter stringFromDate:[NSDate date]]];
        if([[AppConfig sharedConfig] nightModeEnabled]) {
            self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:
                                                   @{ NSForegroundColorAttributeName: [UIColor whiteColor] }];
        } else {
            self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:
                                                   @{ NSForegroundColorAttributeName: [UIColor grayColor] }];
        }
        [self.refreshControl endRefreshing];
    }
}

#pragma mark - StoryCellDelegate Methods
- (void)storyCellDidDisplayActionDrawer:(StoryCell*)cell {
    NSLog(@"storyCellDidDisplayActionDrawer");
}

- (void)storyCell:(StoryCell*)cell didTapActionWithType:(NSNumber*)type {
    [StoryCell handleActionForStory:cell.story withType:type inController:self];
}

- (void)storyCell:(StoryCell*)cell didTapLink:(NSURL*)link {
    
    if([link isHNInternalLink]) {
        
        if([link isHNInternalItemLink]) {
            NSNumber * identifier = [link identifierForHNInternalItemLink];
            if(identifier) {
                [self performSegueWithIdentifier:@"showDetail" sender:identifier]; return;
            }
            
        } else if([link isHNInternalUserLink]) {
            NSString * username = [link usernameForHNInternalUserLink];
            if(username) {
                [self performSegueWithIdentifier:@"showUser" sender:username]; return;
            }
        }
    } // Catches two else cases implicitly
    
    [self performSegueWithIdentifier:@"showWeb" sender:link];
}

- (void)storyCellDidTapCommentsArea:(StoryCell*)cell {
    NSLog(@"storyCellDidTapCommentsArea:");
}

@end
