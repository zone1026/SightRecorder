//
//  FullScreenPlayVideoViewController.m
//  SightRecorder
//
//  Created by 黄 on 16/6/29.
//  Copyright © 2016年 黄. All rights reserved.
//

#import "FullScreenPlayVideoViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface FullScreenPlayVideoViewController ()

@property (weak, nonatomic) IBOutlet UIView *viewSight;
@property (weak, nonatomic) IBOutlet UILabel *lblTips;

@property (strong, nonatomic) NSURL *videoFileURL;
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;
@property (strong, nonatomic) AVPlayerItem *playerItem;

@end

@implementation FullScreenPlayVideoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    
    self.lblTips.hidden = NO;
    [self.playerItem seekToTime:kCMTimeZero];
    [self.player play];
}

#pragma mark - other

- (void)updateVideoFileURL:(NSURL *)videoFileURL
{
    self.videoFileURL = videoFileURL;
    [self showSight];
}

- (void)showSight
{
    self.view.hidden = NO;
    
    self.navigationController.navigationBarHidden = YES;
    [self initPlayLayer];
    
    [self registerNotficationMessage];
    [self.playerItem seekToTime:kCMTimeZero];
    [self.player play];
}
- (void)initPlayLayer
{
    self.lblTips.hidden = YES;
    
    if (!_videoFileURL) {
        return;
    }
    
    AVAsset *asset = [AVURLAsset URLAssetWithURL:_videoFileURL options:nil];
    self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
    
    if (self.player) {
        [self.player seekToTime:kCMTimeZero];
        [self.player setActionAtItemEnd:AVPlayerActionAtItemEndNone];
        [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
        [self.player setVolume:1.0f];
        return;
    }
    self.player = [[AVPlayer alloc] init];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    [self.player setVolume:1.0f];
    
    [self.player seekToTime:kCMTimeZero];
    [self.player setActionAtItemEnd:AVPlayerActionAtItemEndNone];
    [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
    
    CGRect rect = self.viewSight.frame;
    self.playerLayer.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, rect.size.height);
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.viewSight.layer addSublayer:self.playerLayer];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (self.player) {
        [self.player pause];
    }
    self.navigationController.navigationBarHidden = NO;
    [self removeNotificationMessage];
    if (self.player) {
        [self.player replaceCurrentItemWithPlayerItem:nil];
    }
    
    self.view.hidden = YES;
    return;
}

@end
