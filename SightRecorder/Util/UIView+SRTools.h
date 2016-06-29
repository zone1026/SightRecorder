//
//  UIView+SRTools.h
//  SightRecorder
//
//  Created by 黄 on 16/6/29.
//  Copyright © 2016年 黄. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (SRTools)

- (void)makeCornerRadius:(CGFloat)radius borderColor:(UIColor*)bColor borderWidth:(CGFloat)bWidth;

- (void)makeSharpCorner:(UIImage *)maskImg;

@end
