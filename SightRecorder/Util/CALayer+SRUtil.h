//
//  CALayer+SRUtil.h
//  SightRecorder
//
//  Created by 黄 on 16/6/29.
//  Copyright © 2016年 黄. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

static const CGFloat COMMON_UI_ROUND_CORNER_BIG_RADIUS = 5;
static const CGFloat COMMON_UI_ROUND_CORNER_SMALL_RADIUS = 2;

@interface CALayer (SRUtil)

- (void)setBorder:(CGFloat)border withColor:(UIColor *)color withCorner:(CGFloat)cornerRadius;

@end
