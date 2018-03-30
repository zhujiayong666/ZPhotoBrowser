//
//  ZPhotoBrowser.m
//  Pods
//
//  Created by zhujiayong on 15/11/11.
//  Copyright © 2015年 朱家永. All rights reserved.
//

#import "ZPhotoBrowser.h"
#import "SDWebImageManager.h"
#import "UIImage+ZPhotoBrowser.h"

#define ZPhotoBrowser_SCREEN_RECT  [[UIScreen mainScreen] bounds]
#define ZPhotoBrowser_SCREEN_WIDTH ([[UIScreen mainScreen] bounds].size.width)
#define ZPhotoBrowser_SCREEN_HEIGHT ([[UIScreen mainScreen] bounds].size.height)
#define ReuseIdentifier @"ZPhotoBrowserCell"

@interface ZPhotoBrowser() <UIScrollViewDelegate>
{
    CGRect _currentRect;     //当前大图对应的小图在屏幕中位置
    NSInteger _oldIndex;
    CGFloat _oldOffsetX;
    NSMutableDictionary *_cacheDict; // 记录图片是否已有缓存，不能每次都读取磁盘判断，比较耗时
    
    UIWindow *_keyWindow;
    UIWindow *_window;
}

@property (nonatomic, strong) UIScrollView *scrollView;

@property (nonatomic, strong) UIPageControl *pageControl;

@property (nonatomic, strong) NSMutableArray *photosDataSource;

@end

@implementation ZPhotoBrowser

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor blackColor];
        self.frame = ZPhotoBrowser_SCREEN_RECT;
        self.alpha = 0;
        
        self.spacingHorizontal = 2.5;
        self.spacingVertical = 2.5;
        self.photosDataSource = [[NSMutableArray alloc] init];
        _cacheDict = [[NSMutableDictionary alloc] init];
        
        self.scrollView = [[UIScrollView alloc] initWithFrame:ZPhotoBrowser_SCREEN_RECT];
        self.scrollView.delegate = self;
        self.scrollView.pagingEnabled = YES;
        self.scrollView.showsVerticalScrollIndicator = NO;
        self.scrollView.showsHorizontalScrollIndicator = NO;
        [self addSubview:self.scrollView];
        
        self.pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(0, ZPhotoBrowser_SCREEN_HEIGHT - 50, ZPhotoBrowser_SCREEN_WIDTH, 30)];
        [self addSubview:self.pageControl];
        
        // 监听单击
        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
        singleTap.numberOfTouchesRequired = 1;
        [singleTap setNumberOfTapsRequired: 1];
        [self addGestureRecognizer:singleTap];
        
        // 监听双击
        UITapGestureRecognizer *doubleTap =[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
        doubleTap.numberOfTouchesRequired = 1;
        [doubleTap setNumberOfTapsRequired:2];
        [self addGestureRecognizer:doubleTap];
        
         //当双击时，首先调用双击处理
        [singleTap requireGestureRecognizerToFail:doubleTap];
    }
    return self;
}

#pragma mark -
- (void)setCurrentIndex:(NSInteger)currentIndex {
    _currentIndex = currentIndex;
    _oldIndex = _currentIndex;
    self.pageControl.currentPage = _currentIndex;
}

- (void)setPhotos:(NSArray *)photos {
    _photos = photos;

    self.scrollView.contentSize = CGSizeMake(ZPhotoBrowser_SCREEN_WIDTH * photos.count, ZPhotoBrowser_SCREEN_HEIGHT);
    self.pageControl.numberOfPages = photos.count;
    self.pageControl.currentPage = _currentIndex;
    self.pageControl.hidden = photos.count == 1;
    
    for (int i=0; i<photos.count; i++) {
        ZImageModel *model = [photos objectAtIndex:i];

        [self.photosDataSource addObject:[NSNull null]];
        
        UIScrollView *photoScrollView = [[UIScrollView alloc] initWithFrame:ZPhotoBrowser_SCREEN_RECT];
        photoScrollView.userInteractionEnabled = YES;
        photoScrollView.showsVerticalScrollIndicator = NO;
        photoScrollView.showsHorizontalScrollIndicator = NO;
        photoScrollView.center = CGPointMake(ZPhotoBrowser_SCREEN_WIDTH * i + ZPhotoBrowser_SCREEN_WIDTH/2, ZPhotoBrowser_SCREEN_HEIGHT/2);
        photoScrollView.tag = 100+i;
        photoScrollView.backgroundColor = [UIColor clearColor];
        photoScrollView.contentSize = CGSizeMake(ZPhotoBrowser_SCREEN_WIDTH, ZPhotoBrowser_SCREEN_HEIGHT);
        photoScrollView.delegate = self;
        photoScrollView.minimumZoomScale = 1.0;
        photoScrollView.maximumZoomScale = 3.0;
        photoScrollView.zoomScale = 1.0;
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        imageView.center = CGPointMake(ZPhotoBrowser_SCREEN_WIDTH/2, ZPhotoBrowser_SCREEN_HEIGHT/2);
        imageView.userInteractionEnabled = YES;
        [photoScrollView addSubview:imageView];
        
        if ([model isKindOfClass:[ZImageModel class]]) {
            NSString *urlString = model.pic;
            UIImage *image = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:urlString];
            if (image == nil) {
                UIButton *activitView = [[UIButton alloc] initWithFrame:CGRectMake(30, 30, 40, 40)];
                activitView.backgroundColor = [UIColor clearColor];
                [activitView setImage:[UIImage loadImageFromZPhotoBrowserBundleWithName:@"loadingImage_0"] forState:UIControlStateNormal];
                activitView.imageView.animationImages = @[[UIImage loadImageFromZPhotoBrowserBundleWithName:@"loadingImage_0"],[UIImage loadImageFromZPhotoBrowserBundleWithName:@"loadingImage_1"],[UIImage loadImageFromZPhotoBrowserBundleWithName:@"loadingImage_2"], [UIImage loadImageFromZPhotoBrowserBundleWithName:@"loadingImage_3"], [UIImage loadImageFromZPhotoBrowserBundleWithName:@"loadingImage_4"]];
                activitView.imageView.animationDuration = 1.0;
                [activitView.imageView startAnimating];

                [imageView addSubview:activitView];
                [_cacheDict setObject:@(NO) forKey:model.pic];
            }
            else {
                [_cacheDict setObject:@(YES) forKey:model.pic];
            }
        }
        
        [self.scrollView addSubview:photoScrollView];
    }
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView == self.scrollView) {
        _currentIndex = (int)(scrollView.contentOffset.x/ZPhotoBrowser_SCREEN_WIDTH + .5); //四舍五入
        NSInteger currentRow = _currentIndex/3;
        NSInteger oldRow = _oldIndex/3;
        
        // 主要是记录大图对应的小图在屏幕中的位置
        if (scrollView.contentOffset.x < _oldOffsetX) { // 左
            if (currentRow < oldRow) {
                _currentRect = CGRectMake(_currentRect.origin.x + (_currentRect.size.width*2 + self.spacingHorizontal*2), _currentRect.origin.y -  _currentRect.size.height - self.spacingVertical, _currentRect.size.width, _currentRect.size.height);
            } else if (currentRow == oldRow  && _oldIndex != _currentIndex) {
                _currentRect = CGRectMake(_currentRect.origin.x - (_currentRect.size.width + self.spacingHorizontal), _currentRect.origin.y, _currentRect.size.width, _currentRect.size.height);
            }
            
        }
        else if(scrollView.contentOffset.x > _oldOffsetX) { // 右
            if (currentRow > oldRow) {
                _currentRect = CGRectMake(_currentRect.origin.x - (_currentRect.size.width*2 + self.spacingHorizontal), _currentRect.origin.y + ( _currentRect.size.height + self.spacingVertical), _currentRect.size.width, _currentRect.size.height);
                
            }
            else if (currentRow == oldRow && _oldIndex != _currentIndex) {
                _currentRect = CGRectMake(_currentRect.origin.x + (_currentRect.size.width + self.spacingHorizontal), _currentRect.origin.y, _currentRect.size.width, _currentRect.size.height);
            }
        }
        
        _oldIndex = _currentIndex;
        _oldOffsetX = scrollView.contentOffset.x;
        self.pageControl.currentPage = _currentIndex;
    }
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    UIScrollView *photoScrollView = [scrollView viewWithTag:100+_oldIndex];
    if (photoScrollView.zoomScale != 1.0) {
        return;
    }
    // 这里就不判断是左滑还是右滑了
    UIScrollView *lastPhotoScrollView = [self.scrollView viewWithTag:100+_oldIndex - 1];
    UIScrollView *nextPhotoScrollView = [self.scrollView viewWithTag:100+_oldIndex + 1];
    [lastPhotoScrollView setZoomScale:1.0 animated:YES];
    [nextPhotoScrollView setZoomScale:1.0 animated:YES];
}

-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    for (UIView *imageView in scrollView.subviews) {
        if (imageView.subviews.count > 0) { // 正在加载不能缩放
            return nil;
        }
        return imageView;
    }
    return nil;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    UIImageView *imageView = scrollView.subviews.firstObject;
    imageView.frame = [self centeredFrameForScrollView:scrollView andUIView:imageView];
}

#pragma mark - UITapGestureRecognizer
- (void)handleSingleTap:(UITapGestureRecognizer *)tap {
    [self disMiss];
}

-(void)handleDoubleTap:(UIGestureRecognizer *)gesture {
    
    UIScrollView *scrollView = [self.scrollView viewWithTag:100+_currentIndex];
    UIImageView *imageView = scrollView.subviews.firstObject;

    float newScale = 3.0 - [scrollView zoomScale];
    [scrollView setZoomScale:newScale animated:YES];
    imageView.frame = [self centeredFrameForScrollView:scrollView andUIView:imageView];
}

// 重新计算UIImageView的frame
- (CGRect)centeredFrameForScrollView:(UIScrollView *)scroll andUIView:(UIView *)rView {
    CGSize boundsSize = scroll.bounds.size;
    CGRect frameToCenter = rView.frame;

    if (frameToCenter.size.width < boundsSize.width) {
        frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2;
    }
    else {
        frameToCenter.origin.x = 0;
    }

    if (frameToCenter.size.height < boundsSize.height) {
        frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2;
    }
    else {
        frameToCenter.origin.y = 0;
    }
    return frameToCenter;
}

- (void)showInRect:(CGRect)rect {
    _currentRect = rect;
    [self.scrollView setContentOffset:CGPointMake(ZPhotoBrowser_SCREEN_WIDTH*_currentIndex, 0) animated:NO];

    _keyWindow = [[[UIApplication sharedApplication] delegate] window];
    _window = [[UIWindow alloc] initWithFrame:ZPhotoBrowser_SCREEN_RECT];
    _window.windowLevel = UIWindowLevelAlert + 1;
    [_window makeKeyAndVisible];
    [_window addSubview:self];
    
    UIScrollView *photoScrollView = [self.scrollView viewWithTag:100+_currentIndex];
    UIImageView *imageView = photoScrollView.subviews.firstObject;
    imageView.frame = rect;

    [UIView animateWithDuration:.3 animations:^{
        self.alpha = 1.0;
        id obj = _photos[_currentIndex];
        if ([obj isKindOfClass:[ZImageModel class]]) {
            ZImageModel *model = _photos[_currentIndex];
            if (![[_cacheDict objectForKey:model.pic] boolValue]) {
                imageView.frame = CGRectMake(0, 0, 100, 100);
                imageView.center = CGPointMake(ZPhotoBrowser_SCREEN_WIDTH/2, ZPhotoBrowser_SCREEN_HEIGHT/2);
            }
        }
    } completion:^(BOOL finished) {
    }];
    
    id obj = _photos[_currentIndex];
    if ([obj isKindOfClass:[ZImageModel class]]) {
        [self loadImageWithMultiThread]; // 加载图片
    }
    else {
        for (int i=0; i<_photos.count; i++) {
            UIImage *img  = _photos[i];
            [self updateImageWithImage:img andIndex:i];
        }
    }
}

- (void)showInRect:(CGRect)rect WithView:(UIView *)view {
    
    _currentRect = rect;
    [self.scrollView setContentOffset:CGPointMake(ZPhotoBrowser_SCREEN_WIDTH*_currentIndex, 0) animated:NO];
    
    [view addSubview:self];
    
    UIScrollView *photoScrollView = [self.scrollView viewWithTag:100+_currentIndex];
    UIImageView *imageView = photoScrollView.subviews.firstObject;
    imageView.frame = rect;
    
    [UIView animateWithDuration:.3 animations:^{
        self.alpha = 1.0;
        id obj = _photos[_currentIndex];
        if ([obj isKindOfClass:[ZImageModel class]]) {
            ZImageModel *model = _photos[_currentIndex];
            if (![[_cacheDict objectForKey:model.pic] boolValue]) {
                imageView.frame = CGRectMake(0, 0, 100, 100);
                imageView.center = CGPointMake(ZPhotoBrowser_SCREEN_WIDTH/2, ZPhotoBrowser_SCREEN_HEIGHT/2);
            }
        }
    } completion:^(BOOL finished) {
    }];
    
    id obj = _photos[_currentIndex];
    if ([obj isKindOfClass:[ZImageModel class]]) {
        [self loadImageWithMultiThread]; // 加载图片
    }
    else {
        for (int i=0; i<_photos.count; i++) {
            UIImage *img  = _photos[i];
            [self updateImageWithImage:img andIndex:i];
        }
    }
}

- (void)disMiss {

    if (self.disappear) {
        self.disappear(YES);
    }
    UIScrollView *photoScrollView = [self.scrollView viewWithTag:100+_currentIndex];
    UIImageView *imageView = photoScrollView.subviews.firstObject;
    
    if (imageView.subviews.count > 0) {
        UIButton *activitView = imageView.subviews.firstObject;
        [activitView removeFromSuperview];
        activitView = nil;
    }
    [UIView animateWithDuration:.3 animations:^{
        self.alpha = 0;
        photoScrollView.contentSize = CGSizeMake(ZPhotoBrowser_SCREEN_WIDTH, ZPhotoBrowser_SCREEN_HEIGHT);
        imageView.frame = CGRectMake(_currentRect.origin.x, _currentRect.origin.y, _currentRect.size.width, _currentRect.size.height);
        
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
        [_window resignKeyWindow];
        [_window removeFromSuperview];
        _window = nil;
        
        [_keyWindow makeKeyAndVisible];

    }];
}

#pragma mark - 下载、处理图片
-(void)updateImageWithImage:(UIImage *)image andIndex:(NSInteger)index {
    if (!image) {
        return;
    }
    [_photosDataSource replaceObjectAtIndex:index withObject:image];
    UIScrollView *photoScrollView = [self.scrollView viewWithTag:100+index];
    UIImageView *imageView = photoScrollView.subviews.firstObject;
    [imageView setImage:image];
    
    if(imageView.subviews.count > 0) {
        UIButton *activitView = imageView.subviews.firstObject;
        [activitView removeFromSuperview];
        activitView = nil;
    }
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressAction:)];
    [photoScrollView addGestureRecognizer:longPress];
    
    CGRect frame = [UIImage imageViewFrameWithSize:image.size];
    [UIView animateWithDuration:.3 animations:^{
        if (frame.size.height > ZPhotoBrowser_SCREEN_HEIGHT) {
            //长图
            photoScrollView.contentSize = frame.size;
            imageView.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
        }
        else {
            imageView.frame = CGRectMake(0, (ZPhotoBrowser_SCREEN_HEIGHT - frame.size.height)/2, frame.size.width, frame.size.height);
        }
    } completion:^(BOOL finished) {
    }];
}

- (void)loadImage:(NSInteger)index {
    ZImageModel *model = _photos[index];
    NSString *urlString = model.pic;
    UIImage *image = [UIImage new];
    
    if (![[_cacheDict objectForKey:urlString] boolValue]) {
        // 请求网络
        NSURL *url=[NSURL URLWithString:urlString];
        SDWebImageManager * manager =[SDWebImageManager sharedManager];
        [manager loadImageWithURL:url options:0 progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
            if (image) {
                [self updateImageWithImage:image andIndex:index];
            }
        }];
    }
    else {
        image = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:urlString];
        dispatch_queue_t mainQueue= dispatch_get_main_queue();
        dispatch_sync(mainQueue, ^{
            [self updateImageWithImage:image andIndex:index];
        });
    }
}

-(void)loadImageWithMultiThread {
    NSInteger count = _photos.count;
    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    for (int i=0; i<count; ++i) {
        //异步执行队列任务
        dispatch_async(globalQueue, ^{
            [self loadImage:i];
        });
    }
}

- (void)longPressAction:(UILongPressGestureRecognizer *)sender {
    
    if (sender.state == UIGestureRecognizerStateBegan) {
        UIScrollView *photoScrollView = (UIScrollView *)sender.view;
        if (photoScrollView.subviews.count > 0 && [photoScrollView.subviews.firstObject isKindOfClass:[UIImageView class]]) {
            UIImageView *imageView = photoScrollView.subviews.firstObject;
            if (imageView.image) {
                if (self.longPress) {
                    self.longPress(imageView.image);
                }
            }
        }
    }
}

@end
