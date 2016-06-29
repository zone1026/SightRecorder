//
//  UIView+SRTools.m
//  SightRecorder
//
//  Created by 黄 on 16/6/29.
//  Copyright © 2016年 黄. All rights reserved.
//

#import "UIView+SRTools.h"

@implementation UIView (SRTools)

- (void)makeCornerRadius:(CGFloat)radius borderColor:(UIColor *)bColor borderWidth:(CGFloat)bWidth
{
    self.layer.borderWidth = bWidth;
    
    if (bColor) {
        self.layer.borderColor = bColor.CGColor;
    }
    
    self.layer.cornerRadius = radius;
    self.layer.masksToBounds = YES;
}

- (void)makeSharpCorner:(UIImage *)maskImg
{
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.fillColor = [UIColor blackColor].CGColor;
    maskLayer.strokeColor = [UIColor clearColor].CGColor;
    maskLayer.frame = self.bounds;
    maskLayer.contentsCenter = CGRectMake(0.5, 0.5, 0.1, 0.1);//只有在被拉伸后才会起作用,比例作单位
    maskLayer.contentsScale = [UIScreen mainScreen].scale;                 //非常关键设置自动拉伸的效果且不变形
    maskLayer.contents = (id)maskImg.CGImage;
    
    self.layer.mask = maskLayer;
}

@end
