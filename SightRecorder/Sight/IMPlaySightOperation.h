//
//  IMPlaySightOperation.h
//  SightRecorder
//
//  Created by 黄 on 16/6/28.
//  Copyright © 2016年 黄. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface IMPlaySightOperation : NSObject

/**
 * 注意：播放视频的URL是fileURLWithPath。格式是：“file://var”
 */
- (instancetype)initVideoFileURL:(NSURL *)videoFileURL withFrame:(CGRect)frame withView:(UIView *)view;

- (void)playSight;

- (void)releaseVideoPlayer;

- (void)pauseSight;

@end
