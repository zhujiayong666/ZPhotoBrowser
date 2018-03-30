//
//  UIImage+ZPhotoBrowser.m
//  Pods
//
//  Created by zhujiayong on 15/11/11.
//  Copyright © 2015年 朱家永. All rights reserved.
//

#import "UIImage+ZPhotoBrowser.h"
#import "ZPhotoBrowser.h"

@implementation UIImage (ZPhotoBrowser)

+ (CGRect)imageViewFrameWithSize:(CGSize)size {
    
    CGSize boundsSize =  [[UIScreen mainScreen] bounds].size;
    CGFloat boundsWidth = boundsSize.width;
    CGFloat boundsHeight = boundsSize.height;
    
    CGSize imageSize = size;
    CGFloat imageWidth = imageSize.width;
    CGFloat imageHeight = imageSize.height;
    
    CGFloat widthRatio = boundsWidth/imageWidth;
    CGFloat heightRatio = boundsHeight/imageHeight;
    CGFloat minScale = (widthRatio > heightRatio) ? heightRatio : widthRatio;
    
    if (minScale >= 1) {
        minScale = 0.8;
    }
    
    CGRect imageFrame = CGRectMake(0, 0, boundsWidth, imageHeight * boundsWidth / imageWidth);
    
    if ( imageWidth <= imageHeight &&  imageHeight <  boundsHeight ) {
        imageFrame.origin.x = floorf( (boundsWidth - imageFrame.size.width ) / 2.0) * minScale;
        imageFrame.origin.y = floorf( (boundsHeight - imageFrame.size.height ) / 2.0) * minScale;
    }else{
        imageFrame.origin.x = floorf( (boundsWidth - imageFrame.size.width ) / 2.0);
        imageFrame.origin.y = floorf( (boundsHeight - imageFrame.size.height ) / 2.0);
    }
    
    if (imageFrame.size.height > boundsHeight) {
        imageFrame.origin.y = 0;
//        imageFrame.size.height = boundsHeight;
    }
    
    CGRect rect = CGRectMake(0, (boundsHeight-imageFrame.size.height)/2, imageFrame.size.width, imageFrame.size.height);
    return rect;
}

+ (UIImage *)loadImageFromZPhotoBrowserBundleWithName:(NSString *)name {
    NSBundle *libBundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:[ZPhotoBrowser class]] pathForResource:@"ZPhotoBrowser" ofType:@"bundle"]];
    
    NSString *fileName = nil;
    if ([UIScreen mainScreen].scale == 3) {
        fileName = [NSString stringWithFormat:@"/%@@3x", name];
    }
    else {
        fileName = [NSString stringWithFormat:@"/%@@2x", name];
    }
    NSString *file = [libBundle pathForResource:fileName ofType:@"png"];
    UIImage *img = [UIImage imageWithContentsOfFile:file];
    return img;
}

@end
