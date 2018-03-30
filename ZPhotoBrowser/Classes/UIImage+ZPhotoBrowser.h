//
//  UIImage+ZPhotoBrowser.h
//  Pods
//
//  Created by zhujiayong on 15/11/11.
//  Copyright © 2015年 朱家永. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ImageIO/ImageIO.h>
#import <AssetsLibrary/ALAsset.h>
#import <AssetsLibrary/ALAssetsLibrary.h>
#import <AssetsLibrary/ALAssetsGroup.h>
#import <AssetsLibrary/ALAssetRepresentation.h>

@interface UIImage (ZPhotoBrowser)

//计算图片的适合大小
+ (CGRect)imageViewFrameWithSize:(CGSize)size;

//加载本地图片
+ (UIImage *)loadImageFromZPhotoBrowserBundleWithName:(NSString *)name;

@end
