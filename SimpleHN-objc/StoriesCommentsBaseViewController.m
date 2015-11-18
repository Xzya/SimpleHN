//
//  StoriesCommentsBaseViewController.m
//  SimpleHN-objc
//
//  Created by James Eunson on 17/11/2015.
//  Copyright © 2015 JEON. All rights reserved.
//

#import "StoriesCommentsBaseViewController.h"

@import SafariServices;

@implementation StoriesCommentsBaseViewController

- (void)awakeFromNib {
    
    _currentVisibleItemMax = 20;
    _shouldDisplayLoadMoreCell = NO;
    
    _loadMoreStartYPosition = -1;
    _loadMoreCompleteYPosition = -1;
    _lastContentOffset = -1;
    _loadMoreOnReleasePending = NO;
    
    self.visibleItems = [[NSMutableArray alloc] init];
    
    self.itemsLoadStatus = [[NSMutableDictionary alloc] init];
    self.itemsLookup = [[NSMutableDictionary alloc] init];
}

- (void)loadView {
    [super loadView];
    
    self.tableView = [[UITableView alloc] initWithFrame:
                      CGRectZero style:UITableViewStylePlain];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    [self.tableView registerClass:[StoryCell class]
           forCellReuseIdentifier:kStoryCellReuseIdentifier];
    [self.tableView registerClass:[StoryLoadMoreCell class]
           forCellReuseIdentifier:kStoryLoadMoreCellReuseIdentifier];
    [self.tableView registerClass:[CommentCell class]
           forCellReuseIdentifier:kCommentCellReuseIdentifier];
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 88.0f; // set to whatever your "average" cell height is
    
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.tableView.contentInset = UIEdgeInsetsMake(self.navigationController.navigationBar.frame.size.height +
                                                   [UIApplication sharedApplication].statusBarFrame.size.height, 0,
                                                   self.tabBarController.tabBar.frame.size.height, 0);
    [self.view addSubview:_tableView];
    
    self.loadingView = [[ContentLoadingView alloc] init];
    _loadingView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_loadingView];
    
    NSDictionary * bindings = NSDictionaryOfVariableBindings(_loadingView, _tableView);
    [self.view addConstraints:[NSLayoutConstraint jb_constraintsWithVisualFormat:
                               @"H:|[_loadingView]|;V:|[_loadingView]|" options:0 metrics:nil views:bindings]];
    [self.view addConstraints:[NSLayoutConstraint jb_constraintsWithVisualFormat:
                               @"H:|[_tableView]|;V:|[_tableView]|" options:0 metrics:nil views:bindings]];
}

#pragma mark - UITableViewDataSource Methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    //    NSInteger itemsCount = MIN(_currentVisibleStoryMax, [self.user.submitted count]);
    //    if(itemsCount > 0) {
    //        itemsCount = itemsCount + 1;
    //    }
    //    return itemsCount;
    
    NSInteger itemsCount = [_visibleItems count];
    if(itemsCount > 0 && _shouldDisplayLoadMoreCell) {
        itemsCount = itemsCount + 1;
    }
    return itemsCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if(indexPath.row == [_visibleItems count] && [_visibleItems count] > 0
       && _shouldDisplayLoadMoreCell) {
        
        StoryLoadMoreCell *cell = [tableView dequeueReusableCellWithIdentifier:
                                   kStoryLoadMoreCellReuseIdentifier forIndexPath:indexPath];
        return cell;
        
    } else {
        
        id item = [self itemForIndexPath:indexPath];
        if([item isKindOfClass:[Story class]]) {
            
            StoryCell *cell = [tableView dequeueReusableCellWithIdentifier:
                               kStoryCellReuseIdentifier forIndexPath:indexPath];
            cell.story = item;
            
            if(_expandedCellIndexPath && [indexPath isEqual:_expandedCellIndexPath]) {
                cell.expanded = YES;
                
            } else {
                cell.expanded = NO;
            }
            
            cell.delegate = self;
            return cell;
            
        } else {
            
            CommentCell * cell = [tableView dequeueReusableCellWithIdentifier:kCommentCellReuseIdentifier
                                                                 forIndexPath:indexPath];
            cell.comment = item;
            if(_expandedCellIndexPath && [indexPath isEqual:_expandedCellIndexPath]) {
                cell.expanded = YES;
                
            } else {
                cell.expanded = NO;
            }
            
            cell.delegate = self;
            
            return cell;
        }
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if(indexPath.row == self.currentVisibleItemMax) {
        _loadMoreStartYPosition = cell.frame.origin.y;
        _loadMoreCompleteYPosition = cell.frame.origin.y + cell.frame.size.height;
    }
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
    
    if(indexPath.row == self.currentVisibleItemMax) {
        _loadMoreStartYPosition = -1;
        _loadMoreCompleteYPosition = -1;
    }
}

#pragma mark - UIScrollViewDelegate Methods
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if(scrollView == self.tableView) {
        
        // If there isn't more content to display, no reason to run any of this
        if(!_shouldDisplayLoadMoreCell) {
            return;
        }
        // If the loading cell has yet to appear on screen,
        // no reason to continue and waste resources
        if(_loadMoreStartYPosition == -1 || _loadMoreCompleteYPosition == -1) {
            return;
        }
        // If a load is currently in progress, ignore
        if(_loadingProgress.completedUnitCount != _loadingProgress.totalUnitCount) {
            return;
        }
        
        // contentOffset.y adjusted to match cell.frame.origin.y, taking into
        // account screen height and inset from navigation bar b/c of translucency
        CGFloat adjustedYPosition = (scrollView.contentOffset.y + scrollView.frame.size.height) -
        44.0f - self.tableView.contentInset.top;
        
        BOOL scrollingDown = NO;
        if(adjustedYPosition > _lastContentOffset) {
            scrollingDown = YES;
        }
        
        StoryLoadMoreCell * loadMoreCell = [self.tableView cellForRowAtIndexPath:
                                            [NSIndexPath indexPathForRow:self.currentVisibleItemMax inSection:0]];
        
        // Ensure that transition starts only when contentOffset is
        // within the 44pt size of the loading cell, and when the user
        // is scrolling down
        
        if( adjustedYPosition > _loadMoreStartYPosition &&
           adjustedYPosition < _loadMoreCompleteYPosition &&
           scrollingDown ) {
            
            if(loadMoreCell.state != StoryLoadMoreCellStateTransitionStart) {
                loadMoreCell.state = StoryLoadMoreCellStateTransitionStart;
            }
            
        } else if(adjustedYPosition > _loadMoreCompleteYPosition) {
            
            if(loadMoreCell.state != StoryLoadMoreCellStateTransitionComplete) {
                loadMoreCell.state = StoryLoadMoreCellStateTransitionComplete;
                
                _loadMoreOnReleasePending = YES;
            }
            
        } else {
            
            if(_loadMoreOnReleasePending) {
                
                [self loadMoreItems];
                loadMoreCell.state = StoryLoadMoreCellStateLoading;
                
                // Ensure the loading operation only occurs once
                // as scrollViewDidScroll is called frequently
                _loadMoreOnReleasePending = NO;
                
                // All these values are now no longer relevant
                // If left in place, loads will happen in the content y offset
                // the load cell was previously in, which is undesirable
                _loadMoreStartYPosition = -1;
                _loadMoreCompleteYPosition = -1;
                _lastContentOffset = -1;
                
            } else if(loadMoreCell.state != StoryLoadMoreCellStateNormal) {
                loadMoreCell.state = StoryLoadMoreCellStateNormal;
            }
        }
        
        _lastContentOffset = adjustedYPosition;
    }
}

- (id)itemForIndexPath:(NSIndexPath *)indexPath {
    
    NSNumber *identifier = _visibleItems[indexPath.row];
    if([[_itemsLookup allKeys] containsObject:identifier]) {
        return _itemsLookup[identifier];
    } else {
        return nil;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        
        Story * story = [self itemForIndexPath:
                         [self.tableView indexPathForSelectedRow]];
        
        StoryDetailViewController *controller = (StoryDetailViewController *)
        [[segue destinationViewController] topViewController];
        [controller setDetailItem:story];
        
        controller.navigationItem.leftBarButtonItem =
        self.splitViewController.displayModeButtonItem;
        controller.navigationItem.leftItemsSupplementBackButton = YES;
    }
}

// Stub method, to be overridden in subclass
- (void)loadMoreItems {
    NSLog(@"StoriesCommentsBaseViewController, loadMoreItems called");
    
    // Reset to original state
    StoryLoadMoreCell * loadMoreCell = [self.tableView cellForRowAtIndexPath:
                                        [NSIndexPath indexPathForRow:self.currentVisibleItemMax inSection:0]];
    loadMoreCell.state = StoryLoadMoreCellStateNormal;
}

#pragma mark - Property Override Methods
- (void)setShouldDisplayLoadMoreCell:(BOOL)shouldDisplayLoadMoreCell {
    _shouldDisplayLoadMoreCell = shouldDisplayLoadMoreCell;
    
    [self.tableView reloadData];
}

#pragma mark - StoryCellDelegate Methods
- (void)storyCellDidDisplayActionDrawer:(StoryCell*)cell {
    NSLog(@"storyCellDidDisplayActionDrawer:");
    
    if(_expandedCellIndexPath) {
        StoryCell * expandedCell = [self.tableView cellForRowAtIndexPath:
                                    _expandedCellIndexPath];
        expandedCell.expanded = NO;
    }
    
    self.expandedCellIndexPath = [self.tableView indexPathForCell:cell];
    
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}
- (void)storyCell:(StoryCell*)cell didTapActionWithType:(NSNumber*)type {
    [StoryCell handleActionForStory:cell.story withType:type inController:self];
}

#pragma mark - CommentCellDelegate Methods
- (void)commentCell:(CommentCell*)cell didTapLink:(CommentLink*)link {
    SFSafariViewController * controller = [[SFSafariViewController alloc]
                                           initWithURL:link.url];
    [self.navigationController pushViewController:controller animated:YES];
}
- (void)commentCell:(CommentCell*)cell didTapActionWithType:(NSNumber*)type {
    [CommentCell handleActionForComment:cell.comment withType:type inController:self];
}

@end
