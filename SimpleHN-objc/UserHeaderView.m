//
//  UserHeaderView.m
//  SimpleHN-objc
//
//  Created by James Eunson on 9/11/2015.
//  Copyright © 2015 JEON. All rights reserved.
//

#import "UserHeaderView.h"
#import "CommentTextView.h"
//#import "KILabel.h"

@interface UserHeaderView ()

@property (nonatomic, strong) UILabel * nameLabel;
@property (nonatomic, strong) UILabel * submissionsLabel;
@property (nonatomic, strong) UILabel * accountCreatedLabel;

@property (nonatomic, strong) UIStackView * mainStackView;

@property (nonatomic, strong) UILabel * karmaLabel;
@property (nonatomic, strong) UILabel * karmaSubtitleLabel;

@property (nonatomic, strong) UIStackView * karmaStackView;

//@property (nonatomic, strong) UITextView * aboutTextView;
@property (nonatomic, strong) TTTAttributedLabel * aboutLabel;

@property (nonatomic, strong) UIToolbar * toolbar;
@property (nonatomic, strong) UISegmentedControl * sectionSegmentedControl;

// List of views on which the intrinsicContentSize.height of this
// view depends
@property (nonatomic, strong) NSArray * heightDependentViews;

- (void)didChangeSegment:(id)sender;
- (void)nightModeEvent:(NSNotification*)notification;


@end

@implementation UserHeaderView

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init {
    self = [super init];
    if(self) {
        
        _visibleData = UserHeaderViewVisibleDataAll;
        
        self.heightDependentViews = @[];
        
        self.mainStackView = [[UIStackView alloc] init];
        
        _mainStackView.axis = UILayoutConstraintAxisVertical;
        _mainStackView.alignment = UIStackViewAlignmentLeading;
        _mainStackView.translatesAutoresizingMaskIntoConstraints = NO;
        
        self.nameLabel = [LabelHelper labelWithFont:
                          [UIFont preferredFontForTextStyle:UIFontTextStyleTitle3]];
        [_mainStackView addArrangedSubview:_nameLabel];
        
        self.submissionsLabel = [LabelHelper labelWithFont:
                          [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1]];
        _submissionsLabel.textColor = [UIColor grayColor];
        [_mainStackView addArrangedSubview:_submissionsLabel];
        
        self.accountCreatedLabel = [LabelHelper labelWithFont:
                          [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1]];
        _accountCreatedLabel.textColor = [UIColor grayColor];
        [_mainStackView addArrangedSubview:_accountCreatedLabel];
        
        [self addSubview:_mainStackView];
        
        self.karmaStackView = [[UIStackView alloc] init];
        
        _karmaStackView.axis = UILayoutConstraintAxisVertical;
        _karmaStackView.alignment = UIStackViewAlignmentLeading;
        _karmaStackView.translatesAutoresizingMaskIntoConstraints = NO;
        
        self.karmaLabel = [LabelHelper labelWithFont:
                          [UIFont preferredFontForTextStyle:UIFontTextStyleTitle3]];
        _karmaLabel.textColor = [UIColor orangeColor];
        _karmaLabel.textAlignment = NSTextAlignmentCenter;
        [_karmaStackView addArrangedSubview:_karmaLabel];
        
        self.karmaSubtitleLabel = [LabelHelper labelWithFont:
                           [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1]];
        _karmaSubtitleLabel.textColor = [UIColor grayColor];
        _karmaSubtitleLabel.text = @"karma";
        _karmaSubtitleLabel.textAlignment = NSTextAlignmentCenter;
        [_karmaStackView addArrangedSubview:_karmaSubtitleLabel];
        
        [self addSubview:_karmaStackView];
        
        self.aboutLabel = [LabelHelper tttLabelWithFont:[LabelHelper adjustedBodyFont]];
        _aboutLabel.delegate = self;
        _aboutLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_aboutLabel];
        
        self.toolbar = [[UIToolbar alloc] init];
        _toolbar.translatesAutoresizingMaskIntoConstraints = NO;
        _toolbar.translucent = YES;
        
        if([[AppConfig sharedConfig] nightModeEnabled]) {
            _toolbar.barTintColor = kNightDefaultColor;
        } else {
            _toolbar.barTintColor = [UIColor whiteColor];
        }
        _toolbar.tintColor = [UIColor orangeColor];
        
        self.sectionSegmentedControl = [[UISegmentedControl alloc] initWithItems:@[ @"All", @"Submissions", @"Comments" ]];
        _sectionSegmentedControl.translatesAutoresizingMaskIntoConstraints = NO;
        _sectionSegmentedControl.selectedSegmentIndex = 0;
        [_sectionSegmentedControl addTarget:self action:
            @selector(didChangeSegment:) forControlEvents:UIControlEventValueChanged];
        
        [_toolbar addSubview:_sectionSegmentedControl];
        
        [self addSubview:_toolbar];
        
        self.heightDependentViews = @[ _nameLabel, _accountCreatedLabel, _submissionsLabel, _aboutLabel ];
        
        NSDictionary * bindings = NSDictionaryOfVariableBindings(_mainStackView, _karmaStackView,
                                                                 _toolbar, _sectionSegmentedControl, _aboutLabel);
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
                              @"V:|-12-[_mainStackView]-12-[_aboutLabel]-12-[_toolbar(44)]-0-|" options:0 metrics:nil views:bindings]];
        
        [self addConstraints:[NSLayoutConstraint jb_constraintsWithVisualFormat:
                              @"H:|-12-[_mainStackView];H:|-0-[_toolbar]-0-|;H:|-12-[_aboutLabel]-|"
                                                                        options:0 metrics:nil views:bindings]];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
                              @"V:|-12-[_karmaStackView]" options:0 metrics:nil views:bindings]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
                              @"H:[_karmaStackView]-12-|" options:0 metrics:nil views:bindings]];
        
        [self.toolbar addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
                              @"V:|-[_sectionSegmentedControl]-|" options:0 metrics:nil views:bindings]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
                              @"H:|-12-[_sectionSegmentedControl]-12-|" options:0 metrics:nil views:bindings]];

        // Stackview is 75% of UserHeaderView width
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_mainStackView attribute:NSLayoutAttributeWidth
                                                         relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeWidth multiplier:0.75 constant:0]];
        @weakify(self);
        [self addColorChangedBlock:^{
            @strongify(self);
            self.normalBackgroundColor = UIColorFromRGB(0xffffff);
            self.nightBackgroundColor = kNightDefaultColor;
            
            self.nameLabel.normalTextColor = [UIColor blackColor];
            self.nameLabel.nightTextColor = UIColorFromRGB(0xffffff);
            
//            self.toolbar.barTintColor = [UIColor whiteColor];
        }];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(nightModeEvent:)
                                                     name:DKNightVersionNightFallingNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(nightModeEvent:)
                                                     name:DKNightVersionDawnComingNotification object:nil];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self invalidateIntrinsicContentSize];
}

- (CGSize)intrinsicContentSize {
    
    [_heightDependentViews makeObjectsPerformSelector:@selector(sizeToFit)];
    
    CGFloat heightForContent = roundf(12.0f + _nameLabel.frame.size.height + _accountCreatedLabel.frame.size.height + _submissionsLabel.frame.size.height + 12.0f + _aboutLabel.frame.size.height + 12.0f + 44.0f);
    return CGSizeMake(UIViewNoIntrinsicMetric, heightForContent);
}

#pragma mark - Private Methods
- (void)nightModeEvent:(NSNotification*)notification {
    NSLog(@"nightModeEvent:");
    
    if([[AppConfig sharedConfig] nightModeEnabled]) {
        _toolbar.barTintColor = kNightDefaultColor;
    } else {
        _toolbar.barTintColor = [UIColor whiteColor];
    }
    
    if(_user.about) {
        
        if([[AppConfig sharedConfig] nightModeEnabled]) {
            self.aboutLabel.text = _user.nightAttributedAboutText;
            self.aboutLabel.linkAttributes = @{ NSForegroundColorAttributeName: [UIColor orangeColor],
                                                NSUnderlineStyleAttributeName: @(1) };
        } else {
            
            self.aboutLabel.text = _user.attributedAboutText;
            self.aboutLabel.linkAttributes = @{ NSForegroundColorAttributeName: RGBCOLOR(0, 0, 238),
                                                NSUnderlineStyleAttributeName: @(1) };
        }
    }
}

#pragma mark - Property Override Methods
- (void)setUser:(User *)user {
    _user = user;
    
    self.nameLabel.text = _user.name;
    self.accountCreatedLabel.text = _user.accountCreatedString;
    self.submissionsLabel.text = _user.submissionsString;
    
    self.karmaLabel.text = [_user.karma stringValue];
    
    if(_user.about) {
        
        if([[AppConfig sharedConfig] nightModeEnabled]) {
            self.aboutLabel.text = _user.nightAttributedAboutText;
            self.aboutLabel.linkAttributes = @{ NSForegroundColorAttributeName: [UIColor orangeColor],
                                                NSUnderlineStyleAttributeName: @(1) };
        } else {
            
            self.aboutLabel.text = _user.attributedAboutText;
            self.aboutLabel.linkAttributes = @{ NSForegroundColorAttributeName: RGBCOLOR(0, 0, 238),
                                                NSUnderlineStyleAttributeName: @(1) };
        }
    }
    
    [self invalidateIntrinsicContentSize];
    [self setNeedsLayout];
}

- (void)didChangeSegment:(id)sender {
    NSLog(@"didChangeSegment:");
    
    self.visibleData = (int)self.sectionSegmentedControl.selectedSegmentIndex;
    
    if([self.delegate respondsToSelector:@selector(userHeaderView:didChangeVisibleData:)]) {
        [self.delegate performSelector:@selector(userHeaderView:didChangeVisibleData:)
                            withObject:self withObject:@(_visibleData)];
    }
}

#pragma mark - UIGestureRecognizerDelegate Methods
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

#pragma mark - TTTAttributedLabelDelegate Methods
- (void)attributedLabel:(TTTAttributedLabel *)label
   didSelectLinkWithURL:(NSURL *)url {
    
    if([[self.user.linksLookup allKeys] containsObject:url.absoluteString]) {
        NSString * substituteURLString = self.user.linksLookup[url.absoluteString];
        url = [NSURL URLWithString:substituteURLString];
    }
    
    if([self.delegate respondsToSelector:@selector(userHeaderView:didTapLink:)]) {
        [self.delegate performSelector:@selector(userHeaderView:didTapLink:)
                            withObject:self withObject:url];
    }
}

@end
