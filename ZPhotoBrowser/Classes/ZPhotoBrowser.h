//
//  ZPhotoBrowser.h
//  Pods
//
//  Created by zhujiayong on 15/11/11.
//  Copyright © 2015年 朱家永. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZImageModel.h"

typedef void(^LongPress)(UIImage *image);
typedef void(^DisappearBlock)(BOOL disappear);

@interface ZPhotoBrowser : UIView

/**
 *  图片信息,ImageModel or UIImage
 */
@property (nonatomic, strong) NSArray *photos;

/**
 *  当前页码
 */
@property (nonatomic, assign) NSInteger currentIndex;

/**
 *  小图是否是不同的排列样式，影响消失的动画
 */
@property (nonatomic, assign) BOOL isDifferentFormat;

/**
 *  横坐标的间隔，默认2.5
 */
@property (nonatomic, assign) CGFloat spacingHorizontal;

/**
 *  纵坐标的间隔，默认2.5
 */
@property (nonatomic, assign) CGFloat spacingVertical;

- (void)showInRect:(CGRect)rect;

@property (nonatomic,copy) LongPress longPress;
@property (nonatomic,copy) DisappearBlock disappear;

- (void)setLongPress:(LongPress)longPress;
- (void)showInRect:(CGRect)rect WithView:(UIView *)view;
- (void)disMiss;

@end
