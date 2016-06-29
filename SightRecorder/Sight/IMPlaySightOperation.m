//
//  IMPlaySightOperation.m
//  SightRecorder
//
//  Created by 黄 on 16/6/28.
//  Copyright © 2016年 黄. All rights reserved.
//

#import "IMPlaySightOperation.h"
#import <AVFoundation/AVFoundation.h>

@interface IMPlaySightOperation ()

@property (strong, nonatomic) NSURL *videoFileURL;
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;
@property (strong, nonatomic) AVPlayerItem *playerItem;

@end

@implementation IMPlaySightOperation

- (instancetype)initVideoFileURL:(NSURL *)videoFileURL withFrame:(CGRect)frame withView:(UIView *)view
{
    self = [super init];
    if (self) {
        self.videoFileURL = videoFileURL;
        [self registerNotficationMessage];
        [self initPlayLayer:frame withView:view];
    }
    
    return self;
}

- (void)initPlayLayer:(CGRect)rect withView:(UIView *)view
{
    if (!_videoFileURL) {
        return;
    }
    
    AVAsset *asset = [AVURLAsset URLAssetWithURL:_videoFileURL options:nil];
    
    self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
    //    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    self.player = [[AVPlayer alloc] init];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    [self.player setVolume:0.0f];//静音
    
    [self.player seekToTime:kCMTimeZero];
    [self.player setActionAtItemEnd:AVPlayerActionAtItemEndNone];
    [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
    
    self.playerLayer.frame = rect;
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [view.layer addSublayer:self.playerLayer];
}

- (void)playSight
{
    [self.playerItem seekToTime:kCMTimeZero];
    [self.player play];
}

- (void)pauseSight
{
    [self.playerItem seekToTime:kCMTimeZero];
    [self.player pause];
}

- (void)releaseVideoPlayer
{
    [self removeNotificationMessage];
    
    if (self.player) {
        [self.player pause];
        [self.player replaceCurrentItemWithPlayerItem:nil];
    }
    
    if (self.playerLayer) {
        [self.playerLayer removeFromSuperlayer];
    }
    
    self.player = nil;
    self.playerLayer = nil;
    self.playerItem = nil;
    self.videoFileURL = nil;
}

#pragma mark - notification message

- (void)registerNotficationMessage
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(avPlayerItemDidPlayToEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
}

- (void)removeNotificationMessage
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
}

- (void)avPlayerItemDidPlayToEnd:(NSNotification *)notification
{
    if (notification.object != self.playerItem) {
        return;
    }
    
    [self.playerItem seekToTime:kCMTimeZero];
    [self.player play];
}

@end
