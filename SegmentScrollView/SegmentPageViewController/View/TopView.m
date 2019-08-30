//
//  TopView.m
//  SegmentScrollView
//
//  Created by shanyuqin on 2019/8/29.
//  Copyright © 2019 ShanYuQin. All rights reserved.
//

#import "TopView.h"


@interface TopView()



@end

@implementation TopView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.equalTo(@(0));
        }];
        [self addSubview:self.headerContentView];
        [self.headerContentView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.leading.trailing.equalTo(self);
            make.height.equalTo(@(0));
        }];
        
        [self addSubview:self.menuContentView];
        [self.menuContentView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.headerContentView.mas_bottom);
            make.bottom.leading.trailing.equalTo(self);
            make.height.equalTo(@(0));
        }];
    }
    return self;
}


- (void)updateLayout:(CGFloat)headerViewHeight menuViewHeight:(CGFloat)menuViewHeight {
    [self.headerContentView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@(headerViewHeight));
    }];
    [self.menuContentView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@(menuViewHeight));
    }];
    [self mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@(headerViewHeight + menuViewHeight));
    }];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    if (CGRectContainsPoint(self.menuContentView.frame, point)) {
        return YES;
    }
    UIView<HeaderView> *headerView = self.headerContentView.subviews.firstObject;
    if ([headerView conformsToProtocol:@protocol(HeaderView)] &&
        headerView.userInteractionViews) {
        NSMutableArray * frames = [[NSMutableArray alloc] init];
        for (UIView *view in headerView.userInteractionViews) {
            CGRect frame = [self convertRect:view.frame toView:self];
            
            [frames addObject:[NSValue valueWithCGRect:frame]];
        }
        for (NSValue * value in frames) {
            return CGRectContainsPoint([value CGRectValue], point);;
        }
    }
    return false;
}

- (UIView *)menuContentView {
    if (!_menuContentView) {
        _menuContentView = [UIView new];
    }
    return _menuContentView;
}

- (UIView *)headerContentView {
    if (!_headerContentView) {
        _headerContentView = [UIView new];
    }
    return _headerContentView;
}

@end
