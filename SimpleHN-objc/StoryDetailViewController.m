//
//  DetailViewController.m
//  SimpleHN-objc
//
//  Created by James Eunson on 26/09/2015.
//  Copyright © 2015 JEON. All rights reserved.
//

#import "StoryDetailViewController.h"
#import "Story.h"
#import "Comment.h"
#import "UserViewController.h"
#import "SuProgress.h"
#import "ActionDrawerButton.h"
#import "RegexKitLite.h"

#define kStoryCellReuseIdentifier @"kStoryCellReuseIdentifier"
#define kCommentCellReuseIdentifier @"kCommentCellReuseIdentifier"

@import WebKit;

@interface StoryDetailViewController ()

@property (nonatomic, strong) UISegmentedControl * contentSelectSegmentedControl;
@property (nonatomic, strong) SFSafariViewController * webViewController;

//@property (nonatomic, strong) NSIndexPath * expandedCellIndexPath;
@property (nonatomic, strong) NSProgress * loadingProgress;

- (void)reloadContent:(id)sender;
- (void)didSelectContentSegment:(id)sender;

- (void)commentCreated:(NSNotification*)notification;
- (void)commentCollapsedChanged:(NSNotification*)notification;
- (void)commentCollapsedComplete:(NSNotification*)notification;

- (void)expandCollapseCommentForRow:(NSIndexPath *)indexPath;

@end

@implementation StoryDetailViewController

#pragma mark - Managing the detail item

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)awakeFromNib {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(commentCreated:)
                                                 name:kCommentCreated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(commentCollapsedChanged:)
                                                 name:kCommentCollapsedChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(commentCollapsedChanged:)
                                                 name:kCommentCollapsedComplete object:nil];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if(self) {
        NSLog(@"StoryDetailViewController, initWithCoder");
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    if(self) {
        NSLog(@"StoryDetailViewController, init");
    }
    return self;
}

- (void)loadView {
    [super loadView];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero
                                                  style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;

    [self.tableView registerClass:[StoryCell class]
           forCellReuseIdentifier:kStoryCellReuseIdentifier];
    
    [self.tableView registerClass:[CommentCell class]
           forCellReuseIdentifier:kCommentCellReuseIdentifier];
    
//    self.tableView.rowHeight = UITableViewAutomaticDimension;
//    self.tableView.estimatedRowHeight = 88.0f; // set to whatever your "average" cell height is
    
    [self.view addSubview:_tableView];
    
    NSDictionary * bindings = NSDictionaryOfVariableBindings(_tableView);
    [self.view addConstraints:[NSLayoutConstraint jb_constraintsWithVisualFormat:
                               @"V:|[_tableView]|;H:|[_tableView]|" options:0 metrics:nil views:bindings]];
}

- (void)setDetailItem:(id)newDetailItem {
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        
        if(_webViewController) {
            [_webViewController.view removeFromSuperview];
            _webViewController = nil;
        }
        
        [self.tableView reloadData];
        
        // Update the view.
        [self configureView];
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
         self.tableView.contentInset = UIEdgeInsetsMake(self.navigationController
                                                        .navigationBar.frame.size.height, 0, 0, 0);
    } completion:nil];
    
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}
- (void)configureView {
    
    // Update the user interface for the detail item.
    if (self.detailItem) {
        
        Story * detailStory = (Story*)_detailItem;
        self.title = detailStory.title;
        
        if([detailStory.flatDisplayComments count] == 0) {
            [detailStory loadCommentsForStory];
            
            self.loadingProgress = [NSProgress progressWithTotalUnitCount:
                                    [detailStory.totalCommentCount intValue]];
            
            NSProgress * masterProgress = ((AppDelegate *)[[UIApplication sharedApplication]
                                                           delegate]).masterProgress;
            
            masterProgress.completedUnitCount = 0;
            masterProgress.totalUnitCount = [detailStory.totalCommentCount intValue];
            
            [masterProgress addChild:self.loadingProgress withPendingUnitCount:
                [detailStory.totalCommentCount intValue]];
        }
        
        if(!detailStory.url) {
            self.contentSelectSegmentedControl.enabled = NO;
        } else {
            self.contentSelectSegmentedControl.enabled = YES;
        }
        
        if(self.detailItem.url) {
            BOOL enterReaderModeAutomatically = [[AppConfig sharedConfig] storyAutomaticallyShowReader];
            
            self.webViewController = [[SFSafariViewController alloc] initWithURL:self.detailItem.url
                                                         entersReaderIfAvailable:enterReaderModeAutomatically];
            _webViewController.delegate = self;
            [self addChildViewController:_webViewController];
            
            UIView * webView = self.webViewController.view;
            webView.frame = CGRectMake(0,
                                       self.navigationController.navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height,
                                       self.view.frame.size.width,
                                       self.view.frame.size.height - (self.navigationController.navigationBar.frame.size.height + self.tabBarController.tabBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height));
            webView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        }
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
    self.navigationItem.leftItemsSupplementBackButton = YES;
    
    self.contentSelectSegmentedControl = [[UISegmentedControl alloc] initWithItems:@[ @"Comments", @"Story" ]];
    _contentSelectSegmentedControl.selectedSegmentIndex = 0;
    [_contentSelectSegmentedControl addTarget:self action:@selector(didSelectContentSegment:)
                             forControlEvents:UIControlEventValueChanged];
    
    UIBarButtonItem * item = [[UIBarButtonItem alloc] initWithCustomView:_contentSelectSegmentedControl];
    self.navigationItem.rightBarButtonItem = item;
}

#pragma mark - UITableViewDataSource Methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if(section == 0) {
        return 1;
        
    } else {
        return [_detailItem.flatDisplayComments count];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    if(indexPath.section == 0) {
        StoryCell *cell = [tableView dequeueReusableCellWithIdentifier:
                           kStoryCellReuseIdentifier forIndexPath:indexPath];
        
        cell.story = self.detailItem;
        cell.expanded = YES;
        
        cell.storyCellDelegate = self;
        
        return cell;
        
    } else {
        
        Comment * comment = _detailItem.flatDisplayComments[indexPath.row];
        
        CommentCell * cell = [tableView dequeueReusableCellWithIdentifier:kCommentCellReuseIdentifier
                                                             forIndexPath:indexPath];
        cell.comment = comment;
//        if(_expandedCellIndexPath && [indexPath isEqual:_expandedCellIndexPath]) {
//            cell.expanded = YES;
//            
//        } else {
//            cell.expanded = NO;
//        }
        
        cell.commentCellDelegate = self;
        
        return cell;
    }
}

//- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
//    
//    Comment * comment = _detailItem.flatDisplayComments[indexPath.row];
//    if(comment.collapsed && comment.parentComment) {
//        return 0;
//        
//    } else {
//        return UITableViewAutomaticDimension;
//    }
//}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    return 88.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    
    if(indexPath.section == 0) {
        return UITableViewAutomaticDimension;

    } else {
        
        Comment * comment = _detailItem.flatDisplayComments[indexPath.row];        
        return [CommentCell heightForCommentCell:comment width:tableView.frame.size.width];
    }
}

#pragma mark - UITableViewDelegate Methods
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if(indexPath.section == 0 && indexPath.row == 0) {
        self.contentSelectSegmentedControl.selectedSegmentIndex = 1;
        [self didSelectContentSegment:self.contentSelectSegmentedControl];
        
    } else {
        [self expandCollapseCommentForRow:indexPath];
    }
}

#pragma mark - Private Methods
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if([[segue identifier] isEqualToString:@"showUser"]) {
        NSLog(@"prepareForSegue, showUser");
        
        __block UserViewController *controller = (UserViewController *)
            [[segue destinationViewController] topViewController];
        
        if(sender && [sender isKindOfClass:[NSString class]]) {
            controller.author = sender;
            
        } else if(sender && [sender isKindOfClass:[User class]]) {
            controller.user = sender;
        }
        
        controller.navigationItem.leftBarButtonItem =
            self.splitViewController.displayModeButtonItem;
        controller.navigationItem.leftItemsSupplementBackButton = YES;
        
    } else if([[segue identifier] isEqualToString:@"showDetail"]) {
        
        NSNumber * storyIdentifier = (NSNumber*)sender;
        
        StoryDetailViewController *controller = (StoryDetailViewController *)
            [[segue destinationViewController] topViewController];
        
        [Story createStoryFromItemIdentifier:storyIdentifier completion:^(Story *story) {
            controller.detailItem = story;
        }];
        
        controller.navigationItem.leftBarButtonItem =
            self.splitViewController.displayModeButtonItem;
        controller.navigationItem.leftItemsSupplementBackButton = YES;
    }
}

- (void)didSelectContentSegment:(id)sender {
    
    if(_contentSelectSegmentedControl.selectedSegmentIndex == 0) {
        
        if(_webViewController) {
            [_webViewController.view removeFromSuperview];
        }
        
    } else {
        
        if(_webViewController) {
            [self.view addSubview:self.webViewController.view];
        }
    }
}

- (void)commentCreated:(NSNotification*)notification {
    [self.tableView reloadData];
    
    if(self.loadingProgress.completedUnitCount < self.loadingProgress.totalUnitCount) {
        self.loadingProgress.completedUnitCount++;
    }
    
//    NSLog(@"commentCreated: self.loadingProgress.completedUnitCount %lld of %lld",
//          self.loadingProgress.completedUnitCount, self.loadingProgress.totalUnitCount);
}

- (void)commentCollapsedChanged:(NSNotification*)notification {
    
    NSLog(@"commentCollapsedChanged for comment with id: %@",
          ((Comment*)notification.object).commentId);
    
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}

- (void)commentCollapsedComplete:(NSNotification*)notification {
    
    NSLog(@"commentCollapsedComplete");
    
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}

- (void)reloadContent:(id)sender {
    NSLog(@"reloadContent:");
}

- (void)expandCollapseCommentForRow:(NSIndexPath *)indexPath {
    
    Comment * comment = _detailItem.flatDisplayComments[indexPath.row];
    
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

#pragma mark - CommentCellDelegate Methods
- (void)commentCell:(CommentCell*)cell didTapLink:(NSURL*)link {
    
    NSString * internalLinkRegex = @"https?:\\/\\/news.ycombinator.com\\/item\\?id=([0-9]+)";
    
    NSError * error = nil;
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:internalLinkRegex options:NSRegularExpressionCaseInsensitive error:&error];
    
    NSArray* matches = [regex matchesInString:[link absoluteString] options:0 range:NSMakeRange(0, [[link absoluteString] length])];
    if([matches count] > 0) {
        
        @try {
            NSNumber * identifier = @([[[[link absoluteString] componentsSeparatedByString:@"?id="] lastObject] intValue]);
            [self performSegueWithIdentifier:@"showDetail" sender:identifier];
        }
        @catch (NSException *exception) {
            NSLog(@"ERROR: Could not extract identifier from %@", [link absoluteString]);
        }
        
    } else {
        
        SFSafariViewController * controller = [[SFSafariViewController alloc]
                                               initWithURL:link];
        [self.navigationController pushViewController:controller animated:YES];
    }
}

- (void)commentCell:(CommentCell *)cell didTapTextView:(UITextView *)textView {
    
    NSInteger indexOfRow = [_detailItem.flatDisplayComments indexOfObject:cell.comment];
    if(indexOfRow != NSNotFound) {
        
        NSIndexPath * indexPath = [NSIndexPath indexPathForRow:indexOfRow inSection:1];
        [self expandCollapseCommentForRow:indexPath];
    }
}

- (void)commentCell:(CommentCell*)cell didTapActionWithType:(NSNumber*)type {
    ActionDrawerViewButtonType actionType = [type intValue];

    if(actionType == ActionDrawerViewButtonTypeUser) {
        NSLog(@"ActionDrawerViewButtonTypeUser");
        
        [self performSegueWithIdentifier:@"showUser"
                                  sender:cell.comment.author];
        
    } else if(actionType == ActionDrawerViewButtonTypeMore) {
        
        NSString * title = [NSString stringWithFormat:@"Comment from %@", cell.comment.author];
        
        UIAlertController * controller = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        [controller addAction:[UIAlertAction actionWithTitle:@"Share" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
        }]];
        [controller addAction:[UIAlertAction actionWithTitle:@"Open in Safari" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
        }]];
        [controller addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:controller animated:YES completion:nil];
    }
}

#pragma mark - SFSafariViewControllerDelegate Methods
- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller {
    self.contentSelectSegmentedControl.selectedSegmentIndex = 0;
    
    if(_webViewController) {
        [_webViewController.view removeFromSuperview];
    }
}

#pragma mark - StoryCellDelegate Methods
- (void)storyCellDidDisplayActionDrawer:(StoryCell*)cell {
    NSLog(@"storyCellDidDisplayActionDrawer");
}
- (void)storyCell:(StoryCell*)cell didTapActionWithType:(NSNumber*)type {
    [StoryCell handleActionForStory:cell.story withType:type inController:self];
}

@end
