//
//  ContentLoadingView.m
//  SimpleHN-objc
//
//  Created by James Eunson on 17/11/2015.
//  Copyright © 2015 JEON. All rights reserved.
//

#import "ContentLoadingView.h"
//#import "UIFont+SSTextSize.h"

// UIStackView means I don't even have to write a
// layoutSubviews method!

@interface ContentLoadingView ()

@property (nonatomic, strong) UIStackView * stackView;
@property (nonatomic, strong) UILabel * loadingLabel;

- (void)nightModeEvent:(NSNotification*)notification;

@end

@implementation ContentLoadingView

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init {
    self = [super init];
    if(self) {
        
        self.backgroundColor = [UIColor whiteColor];
        
        self.stackView = [[UIStackView alloc] init];
        
        _stackView.axis = UILayoutConstraintAxisHorizontal;
        _stackView.alignment = UIStackViewAlignmentCenter;
        _stackView.translatesAutoresizingMaskIntoConstraints = NO;
        _stackView.spacing = 8.0f;
        
        self.loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:
                            UIActivityIndicatorViewStyleGray];
        [_loadingView startAnimating];        
        [_loadingView sizeToFit];
        
        if([[AppConfig sharedConfig] nightModeEnabled]) {
            _loadingView.color = [UIColor whiteColor];
        } else {
            _loadingView.color = [UIColor grayColor];
        }
        
        [self.stackView addArrangedSubview:_loadingView];
        
        self.loadingLabel = [LabelHelper labelWithFont:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]];
        
        _loadingLabel.textColor = RGBCOLOR(102, 102, 102);
        _loadingLabel.text = @"Loading...";
        _loadingLabel.numberOfLines = 1;
        [_loadingLabel sizeToFit];
        
        [self.stackView addArrangedSubview:_loadingLabel];
        
        [self addSubview:_stackView];
        
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_stackView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_stackView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
        
        @weakify(self);
        [self addColorChangedBlock:^{
            @strongify(self);
            
            self.loadingLabel.textColor = RGBCOLOR(102, 102, 102);
            self.loadingLabel.nightTextColor = UIColorFromRGB(0x999999);
            
            self.backgroundColor = [UIColor whiteColor];
            self.nightBackgroundColor = kNightDefaultColor;
        }];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(nightModeEvent:)
                                                     name:DKNightVersionNightFallingNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(nightModeEvent:)
                                                     name:DKNightVersionDawnComingNotification object:nil];
    }
    return self;
}

- (void)nightModeEvent:(NSNotification*)notification {
    if([[AppConfig sharedConfig] nightModeEnabled]) {
        _loadingView.color = [UIColor whiteColor];
    } else {
        _loadingView.color = [UIColor grayColor];
    }
}

@end
