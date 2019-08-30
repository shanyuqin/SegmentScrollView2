//
//  SegmentPageViewController.m
//  SegmentScrollView
//
//  Created by shanyuqin on 2019/8/19.
//  Copyright © 2019 ShanYuQin. All rights reserved.
//

#import "SegmentPageViewController.h"
#import "UIScrollView+SegmentPage.h"
#import "UIViewController+SegmentPage.h"
#import "ContainView.h"
#import "TopView.h"

@interface SegmentPageViewController ()<UIScrollViewDelegate>

@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, assign) NSInteger originIndex;
@property (nonatomic, strong) UIStackView * contentStackView;
@property (nonatomic, strong) TopView * topView;
@property (nonatomic, assign) CGFloat menuViewPinHeight;
@property (nonatomic, assign) CGFloat headerViewHeight;
@property (nonatomic, assign) CGFloat menuViewHeight;
@property (nonatomic, assign) CGFloat sillValue;
@property (nonatomic, assign) NSInteger childControllerCount;
@property (nonatomic, strong) UIView * headerView;
@property (nonatomic, strong) UIView * menuView;
@property (nonatomic, strong) NSMutableArray<ContainView *> * containViews;
@property (nonatomic, strong) UIScrollView * currentChildScrollView;
@property (nonatomic, strong) NSArray * childScrollViews;
@property (nonatomic, strong) UIViewController<SegmentPageChildViewController> * _Nullable currentViewController;

@property (nonatomic, assign) BOOL isBeginDragging;
@property (nonatomic, assign) CGFloat topViewLastOffset;
@property (nonatomic, assign) CGFloat childScrollOffset;
@property (nonatomic, assign) ScrollDirection childScrollDirection;
@property (nonatomic, assign) BOOL isSpecialState;


@property (nonatomic, strong) NSCache<NSString*, UIViewController<SegmentPageChildViewController>*> * memoryCache;
@property (nonatomic, weak) id<SegmentPageViewControllerDataSource> dataSource;
@property (nonatomic, weak) id<SegmentPageViewControllerDelegate> delegate;

@property (nonatomic, strong) UIScrollView * observerScrollView;

@end

@implementation SegmentPageViewController

#pragma mark - init -

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _dataSource = self;
        _delegate = self;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _dataSource = self;
        _delegate = self;
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _dataSource = self;
        _delegate = self;
    }
    return self;
}

#pragma mark - lifeCycle -

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (@available(iOS 11.0,*)) {
        self.mainScrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }else {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    
    
    [self obtainDataSource];
    [self setupOriginContent];
    [self setupDataSource];
    [self.view layoutIfNeeded];
    if (self.originIndex > 0) {
        [self setSelect:self.originIndex animation:NO];
    }else {
        [self showChildViewContollerAt:self.originIndex];
        [self didDisplayViewControllerAt:self.originIndex];
    }
}

- (void)dealloc {
    [self.observerScrollView removeObserver:self forKeyPath:@"contentOffset"];
}
#pragma mark - private method -

- (void)obtainDataSource {
    self.originIndex = [self originIndexFor:self];
    
    self.headerView = [self headerViewFor:self];
    self.headerViewHeight = [self headerViewHeightFor:self];
    
    self.menuView = [self menuViewFor:self];
    self.menuViewHeight = [self menuViewHeightFor:self];
    self.menuViewPinHeight = [self menuViewPinHeightFor:self];
    
    self.childControllerCount = [self numberOfViewControllersIn:self];
    self.sillValue = self.headerViewHeight - self.menuViewPinHeight;
}

- (void)setupOriginContent {
    
    [self.view addSubview:self.mainScrollView];
    [self.mainScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.top.bottom.trailing.equalTo(self.view);
    }];
    
    
    [self.mainScrollView addSubview:self.contentStackView];
    [self.contentStackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.bottom.top.height.equalTo(self.mainScrollView);
    }];
    
    [self.view addSubview:self.topView];
    [self.topView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.mas_topLayoutGuideTop);
        make.leading.trailing.equalTo(self.view);
    }];
    
    [self updateOriginContent];
    
}

- (void)updateOriginContent {
    [self.topView updateLayout:self.headerViewHeight menuViewHeight:self.menuViewHeight];
}

- (void)clear {
    self.originIndex = 0;

    self.childControllerCount = 0;
    
    self.currentViewController = nil;
    self.currentChildScrollView = nil;
    [self.headerView removeFromSuperview];
    [self.mainScrollView setContentOffset:CGPointZero animated:NO];
    
    for (UIView *view in self.contentStackView.subviews) {
        [view removeFromSuperview];
    }
    [self.containViews removeAllObjects];
    [self.memoryCache removeAllObjects];
    
    for (ContainView * view in self.containViews) {
        [view.viewController clearFromParent];
    }
}


- (void)setupDataSource {
    self.memoryCache.countLimit = self.childControllerCount;
    if (self.headerView) {
        [self.topView.headerContentView addSubview:self.headerView];
        self.headerView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.headerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.trailing.top.bottom.equalTo(self.topView.headerContentView);
        }];
    }
    
    if (self.menuView) {
        [self.topView.menuContentView addSubview:self.menuView];
        self.menuView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.menuView mas_makeConstraints:^(MASConstraintMaker *make) {
           make.leading.trailing.top.bottom.equalTo(self.topView.menuContentView);
        }];
    }
    
    
    for (int i = 0; i < self.childControllerCount; i++) {
        ContainView *containView = [ContainView new];
        
        containView.backgroundColor = [UIColor colorWithRed:(arc4random()%256)/255.0 green:(arc4random()%256)/255.0 blue:(arc4random()%256)/255.0 alpha:1];
        [self.contentStackView addArrangedSubview:containView];
        [containView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.equalTo(self.view.mas_width);
            make.height.equalTo(self.contentStackView.mas_height);
        }];
        [self.containViews addObject:containView];
    }
    
  
    
}

- (void)showChildViewContollerAt:(NSInteger)index {
    if (self.childControllerCount <= 0 ||
        index < 0 ||
        index >= self.childControllerCount ||
        self.containViews.count == 0) {
        return;
    }
    ContainView *containView = self.containViews[index];
    if (!containView.isEmpty) {
        return;
    }
    
    UIViewController<SegmentPageChildViewController> * cachedViewContoller = [self.memoryCache objectForKey:[NSString stringWithFormat:@"%ld",(long)index]];
    UIViewController<SegmentPageChildViewController> * targetViewController = cachedViewContoller != nil ? cachedViewContoller : [self segmentPageController:self viewControllerAt:index];
    
    if (targetViewController == nil) {
        return;
    }
    
    [self segmentPageViewController:self willDisplay:targetViewController forItemAt:index];
    
    
    [targetViewController beginAppearanceTransition:YES animated:NO];
    [self addChildViewController:targetViewController];
    [containView addSubview:targetViewController.view];
    [targetViewController.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.top.bottom.equalTo(containView);
    }];
    [targetViewController.view layoutIfNeeded];
    [targetViewController didMoveToParentViewController:self];
    [targetViewController endAppearanceTransition];
    
    containView.viewController = targetViewController;
    
    UIScrollView *scrollView = targetViewController.childScrollView;
    scrollView.segPage_lastOffsetY = scrollView.contentOffset.y;
    
        
    [self.observerScrollView removeObserver:self forKeyPath:@"contentOffset"];
    [scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
    self.observerScrollView = scrollView;
    
    if (scrollView.contentOffset.y <= self.sillValue) {
        [scrollView setContentOffset:CGPointMake(0, -self.topView.frame.origin.y) animated:NO];
    }else if ([self keepChildScrollViewOffset:self] == NO && fabs(self.topView.frame.origin.y) < self.sillValue) {
        [scrollView setContentOffset:CGPointMake(0, -self.topView.frame.origin.y) animated:NO];
    }
    
    self.childScrollOffset = scrollView.contentOffset.y;
    self.topViewLastOffset = -self.topView.frame.origin.y;
    CGFloat offsetY = scrollView.contentOffset.y;
    self.isSpecialState = [self keepChildScrollViewOffset:self] && offsetY > fabs(self.topView.frame.origin.y);
    
}

- (void)didDisplayViewControllerAt:(NSInteger)index {
    if (self.childControllerCount <= 0 ||
        index < 0 ||
        index >= self.childControllerCount ||
        self.containViews.count == 0) {
        return;
    }
    ContainView * containView = self.containViews[index];
    self.currentViewController = containView.viewController;
    self.currentChildScrollView = self.currentViewController.childScrollView;
    self.currentIndex = index;
    UIViewController<SegmentPageChildViewController> *vc = containView.viewController;
    if (vc) {
        [self segmentPageViewController:self didDisplay:vc forItemAt:index];
    }
}

- (void)removeChildViewControllerAt:(NSInteger)index {
    if (self.childControllerCount <= 0 ||
        index < 0 ||
        index >= self.childControllerCount ||
        self.containViews.count == 0) {
        return;
    }
    
    ContainView *containView = self.containViews[index];
    if (containView.isEmpty || containView.viewController == nil) {
        return;
    }
    [containView.viewController clearFromParent];
    if ([self.memoryCache objectForKey:[NSString stringWithFormat:@"%ld",(long)index]] == nil) {
        [self segmentPageViewController:self willCache:containView.viewController forItemAt:index];
        [self.memoryCache setObject:containView.viewController forKey:[NSString stringWithFormat:@"%ld",(long)index]];
    }

}

- (void)layoutChildViewControlls {
    
    for (int index = 0; index < self.childControllerCount; index++) {
        ContainView *containView = self.containViews[index];
        BOOL isDisplaying = [containView displayingIn:self.view containView:self.mainScrollView];
        if (isDisplaying) {
            [self showChildViewContollerAt:index];
        }else {
            [self removeChildViewControllerAt:index];
        }
    }
}

- (void)mainScrollViewDidEndScroll:(UIScrollView *)scrollView {
    CGFloat scrollViewWidth = scrollView.frame.size.width;
    if (scrollViewWidth <= 0)
        return;
    
    CGFloat offsetX = scrollView.contentOffset.x;
    int index = (int)offsetX/scrollViewWidth;
    [self didDisplayViewControllerAt:index];
    [self segmentPageViewController:self mainScrollViewDidEndScroll:self.mainScrollView];
    
}

- (void)childScrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat offsetY = scrollView.contentOffset.y;
    self.childScrollOffset = offsetY;
    if (self.isSpecialState) {
        self.isSpecialState = offsetY - self.topViewLastOffset;
        CGFloat value = offsetY - scrollView.segPage_lastOffsetY;
        CGFloat offset = MIN(value + self.topViewLastOffset, self.sillValue);
        if (self.childScrollDirection == up) {
            [self.topView mas_updateConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.mas_topLayoutGuideTop).offset(-offset);
            }];
        }else {
            self.topViewLastOffset = -(self.topView.frame.origin.y);
            scrollView.segPage_lastOffsetY = offset;
        }
    }else {
        scrollView.segPage_lastOffsetY = 0;
        CGFloat offset = MIN(offsetY, self.sillValue);
        [self.topView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.mas_topLayoutGuideTop).offset(-offset);
        }];
    }
    BOOL isAdsorption = fabs(self.topView.frame.origin.y) == self.sillValue;
    [self segmentPageViewController:self headerView:self.topView.frame.origin isAdsorption:isAdsorption];
    [self segmentPageViewController:self childScrollViewDidScroll:scrollView];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isKindOfClass:[UIScrollView class]]) {
        
        CGPoint newPoint=[((NSValue *)[change  valueForKey:@"new"]) CGPointValue];
        CGPoint oldPoint=[((NSValue *)[change  valueForKey:@"old"]) CGPointValue];
        

        if (newPoint.y != oldPoint.y) {
            [self childScrollViewDidScroll:(UIScrollView *)object];
        }
    }
}

#pragma mark - public method -

- (void)setSelect:(NSInteger)index animation:(BOOL)animation {
    CGPoint offset = CGPointMake(self.mainScrollView.frame.size.width * index, self.mainScrollView.contentOffset.y);
    [self.mainScrollView setContentOffset:offset animated:animation];
    if (animation == NO) {
        [self mainScrollViewDidEndScroll:self.mainScrollView];
    }
}

- (void)reloadData {
    self.mainScrollView.userInteractionEnabled = NO;
    [self clear];
    [self obtainDataSource];
    [self updateOriginContent];
    [self setupDataSource];
    [self.view layoutIfNeeded];
    if (self.originIndex > 0) {
        [self setSelect:self.originIndex animation:NO];
    }else {
        [self showChildViewContollerAt:self.originIndex];
        [self didDisplayViewControllerAt:self.originIndex];
    }
    self.mainScrollView.userInteractionEnabled = YES;
}

- (void)setChildScrollOffset:(CGFloat)childScrollOffset {
    if (_childScrollOffset > childScrollOffset) {
        self.childScrollDirection = down;
    }else if (_childScrollOffset < childScrollOffset) {
        self.childScrollDirection = up;
    }else {
        self.childScrollDirection = none;
    }
    _childScrollOffset = childScrollOffset;
}

#pragma mark - SegmentPageViewControllerDelegate -
- (void)segmentPageViewController:(SegmentPageViewController *)segmentPageController mainScrollViewDidScroll:(UIScrollView *)scrollView {}

- (void)segmentPageViewController:(SegmentPageViewController *)segmentPageController mainScrollViewDidEndScroll:(UIScrollView *)scrollView {}

- (void)segmentPageViewController:(SegmentPageViewController *)segmentPageController childScrollViewDidScroll:(UIScrollView *)scrollView {}

- (void)segmentPageViewController:(SegmentPageViewController *)segmentPageController willCache:(UIViewController<SegmentPageChildViewController> *)viewController forItemAt:(NSInteger)index {}

- (void)segmentPageViewController:(SegmentPageViewController *)segmentPageController willDisplay:(UIViewController<SegmentPageChildViewController> *)viewController forItemAt:(NSInteger)index {}

- (void)segmentPageViewController:(SegmentPageViewController *)segmentPageController didDisplay:(UIViewController<SegmentPageChildViewController> *)viewController forItemAt:(NSInteger)index {}

- (void)segmentPageViewController:(SegmentPageViewController *)segmentPageController headerView:(CGPoint)offset  isAdsorption:(BOOL)isAdsorption {}

#pragma mark - UIScrollViewDelegate -
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self segmentPageViewController:self mainScrollViewDidScroll:scrollView];
    [self layoutChildViewControlls];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    self.isBeginDragging = YES;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (decelerate == NO) {
        [self mainScrollViewDidEndScroll:scrollView];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (self.isBeginDragging) {
        [self mainScrollViewDidEndScroll:scrollView];
        self.isBeginDragging = NO;
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
   [self mainScrollViewDidEndScroll:scrollView];
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
    if (scrollView == self.mainScrollView) {
        [self.currentChildScrollView setContentOffset:CGPointZero animated:YES];
        return true;
    }
    return NO;
}

#pragma mark - lazy load -

- (UIScrollView *)mainScrollView {
    if (!_mainScrollView) {
        _mainScrollView = [[UIScrollView alloc] init];
        _mainScrollView.delegate = self;
        _mainScrollView.scrollsToTop = YES;
        _mainScrollView.backgroundColor = [UIColor whiteColor];
        _mainScrollView.showsHorizontalScrollIndicator = NO;
        _mainScrollView.showsVerticalScrollIndicator = NO;
        _mainScrollView.translatesAutoresizingMaskIntoConstraints = NO;
        _mainScrollView.pagingEnabled = YES;
        UIGestureRecognizer * popGesture = self.navigationController.interactivePopGestureRecognizer;
//        [A requireGestureRecognizerToFail：B]函数，它可以指定当A手势发生时，即便A已经滿足条件了，也不会立刻触发，会等到指定的手势B确定失败之后才触发
        [_mainScrollView.panGestureRecognizer requireGestureRecognizerToFail:popGesture];
    }
    return _mainScrollView;
}

- (UIStackView *)contentStackView {
    if (!_contentStackView) {
        _contentStackView = [[UIStackView alloc] init];
        _contentStackView.alignment = UIStackViewAlignmentFill;
        _contentStackView.distribution = UIStackViewDistributionFillEqually;
        _contentStackView.axis = UILayoutConstraintAxisHorizontal;
    }
    return _contentStackView;
}

- (NSMutableArray<ContainView *> *)containViews {
    if (!_containViews) {
        _containViews = [NSMutableArray array];
    }
    return _containViews;
}

- (TopView *)topView {
    if (!_topView) {
        _topView = [[TopView alloc] init];
    }
    return _topView;
}
@end
