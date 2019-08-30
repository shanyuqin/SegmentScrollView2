//
//  TopView.h
//  SegmentScrollView
//
//  Created by shanyuqin on 2019/8/29.
//  Copyright © 2019 ShanYuQin. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TopView : UIView

@property (nonatomic, strong) UIView * headerContentView;
@property (nonatomic, strong) UIView * menuContentView;


- (void)updateLayout:(CGFloat)headerViewHeight menuViewHeight:(CGFloat)menuViewHeight;
@end

NS_ASSUME_NONNULL_END
