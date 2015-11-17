//
//  StoryActionDrawerView.h
//  SimpleHN-objc
//
//  Created by James Eunson on 9/11/2015.
//  Copyright © 2015 JEON. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, ActionDrawerViewButtonType) {
    ActionDrawerViewButtonTypeUser,
    ActionDrawerViewButtonTypeFlag,
    ActionDrawerViewButtonTypeLink,
    ActionDrawerViewButtonTypeMore
};

@protocol ActionDrawerViewDelegate;
@interface ActionDrawerView : UIView

@property (nonatomic, strong) NSArray < NSNumber * > * buttonTypes;
@property (nonatomic, assign) __unsafe_unretained
    id<ActionDrawerViewDelegate> delegate;

@end

@protocol ActionDrawerViewDelegate <NSObject>
- (void)actionDrawerView:(ActionDrawerView*)view
        didTapActionWithType:(NSNumber*)type;
@end