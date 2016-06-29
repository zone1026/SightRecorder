//
//  CALayer+SRUtil.m
//  SightRecorder
//
//  Created by 黄 on 16/6/29.
//  Copyright © 2016年 黄. All rights reserved.
//

#import "CALayer+SRUtil.h"

@implementation CALayer (SRUtil)

- (void)setBorder:(CGFloat)border withColor:(UIColor *)color withCorner:(CGFloat)cornerRadius {
    if (border > 0) {
        self.borderWidth = border;
    }
    if (color) {
        self.borderColor = [color CGColor];
    }
    if (cornerRadius > 0) {
        [self setCornerRadius:cornerRadius];
    }
}

@end
