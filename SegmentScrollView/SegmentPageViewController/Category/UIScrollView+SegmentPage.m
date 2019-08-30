//
//  UIScrollView+SegmentPage.m
//  SegmentScrollView
//
//  Created by shanyuqin on 2019/8/19.
//  Copyright © 2019 ShanYuQin. All rights reserved.
//

#import "UIScrollView+SegmentPage.h"
#import <objc/runtime.h>

static const char segPage_isCanScroll;
static const char segPage_lastOffsetY;

@implementation UIScrollView (SegmentPage)

- (CGFloat)segPage_lastOffsetY {
    return [objc_getAssociatedObject(self, &segPage_lastOffsetY) floatValue];
}

- (void)setSegPage_lastOffsetY:(CGFloat)segPage_lastOffsetY {
    objc_setAssociatedObject(self, &segPage_lastOffsetY, @(segPage_lastOffsetY), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


- (void)scrollToSuitable:(UIView *)view {
    if (self.contentSize.width <= self.bounds.size.width) {
        return;
    }
    CGFloat x = MIN(MAX(view.center.x - CGRectGetMidX(self.frame), 0.0), self.contentSize.width - self.bounds.size.width);
    [self setContentOffset:CGPointMake(x, 0) animated:YES];
}

@end
