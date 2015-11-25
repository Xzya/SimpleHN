//
//  CommentCell.h
//  SimpleHN-objc
//
//  Created by James Eunson on 2/11/2015.
//  Copyright © 2015 JEON. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Comment.h"
#import "KILabel.h"
#import "ActionDrawerView.h"

@protocol CommentCellDelegate;
@interface CommentCell : UITableViewCell <ActionDrawerViewDelegate, UITextViewDelegate, NSLayoutManagerDelegate>

@property (nonatomic, strong) Comment * comment;

@property (nonatomic, strong) UITextView * commentTextView;

// Used when quotes are present in the comment, so we can indent
// the quote views independently of the comment body views
// We only use multiple views in this circumstance, for performance reasons
@property (nonatomic, strong) NSArray <UITextView *>* commentTextViews;

@property (nonatomic, strong) UIView * headerView;
@property (nonatomic, strong) UILabel * authorLabel;
@property (nonatomic, strong) UILabel * dateLabel;

@property (nonatomic, strong) CALayer * headerBorderLayer;
@property (nonatomic, strong) UIView * headerBackgroundView;
//@property (nonatomic, strong) UIImageView * headerIconImageView;
@property (nonatomic, strong) UILabel * headerUpDownLabel;

@property (nonatomic, assign, getter=isExpanded) BOOL expanded;

@property (nonatomic, assign) __unsafe_unretained id<CommentCellDelegate> delegate;

// Assigned to cell when story is updated, value is only retained
// for 1 second or so, while an update animation plays
@property (nonatomic, strong) NSDictionary * storyDiffDict;

// Centralised point where action handling code can be invoked
+ (void)handleActionForComment:(Comment*)comment withType:
    (NSNumber*)type inController:(UIViewController*)controller;

@end

@protocol CommentCellDelegate <NSObject>
- (void)commentCell:(CommentCell*)cell didTapLink:(NSURL*)link;
- (void)commentCell:(CommentCell*)cell didTapActionWithType:(NSNumber*)type;
@end
