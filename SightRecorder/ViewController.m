//
//  ViewController.m
//  SightRecorder
//
//  Created by 黄 on 16/6/28.
//  Copyright © 2016年 黄. All rights reserved.
//

#import "ViewController.h"
#import "SRUtil.h"
#import "ChatSightViewController.h"
#import "ChatDataProxy.h"
#import "IMPlaySightOperation.h"
#import "UIView+SRTools.h"
#import "FullScreenPlayVideoViewController.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIButton *btnSight;
- (IBAction)btnSightTouchUpInside:(UIButton *)sender;
@property (weak, nonatomic) IBOutlet UIView *viewContent;
@property (weak, nonatomic) IBOutlet UILabel *lblStime;

@property (nonatomic, retain) ChatSightViewController *sightViewController;

@property (nonatomic, strong) IMPlaySightOperation *sightOperation;

@property (nonatomic, retain) FullScreenPlayVideoViewController *bigScreenPlaySightViewController;

@property (nonatomic, retain) UITapGestureRecognizer *tapContent;

@property (nonatomic, retain) NSString *playVideoPath;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _tapContent = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewContentTapped:)];
    [self.viewContent addGestureRecognizer:_tapContent];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self registerMessageNotification];
    [super viewWillAppear:animated];
    if (nil == self.sightViewController) {
        self.sightViewController = [SRUtil embedController:@"ChatSightViewController" inStoryboard:@"Main" toContainerController:self withContainerView:self.view];
        self.sightViewController.view.hidden = YES;
    }
    
    UIImage *maskImg = [UIImage imageNamed:@"chatBg"];
    [self.viewContent makeSharpCorner:maskImg];
    
    self.viewContent.hidden = YES;
    self.lblStime.hidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self removeMessageNotification];
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - meessage notification

- (void)registerMessageNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleVideoRecordFinshNotification:) name:NOTI_CHAT_VIDEO_RECORD_FINSH object:nil];
}

- (void)removeMessageNotification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTI_CHAT_VIDEO_RECORD_FINSH object:nil];
}

- (void)handleVideoRecordFinshNotification:(NSNotification *)notification
{
    if (!notification.object) {
        self.viewContent.hidden = NO;
        self.lblStime.hidden = NO;
        NSDictionary *videoDict = notification.userInfo;
        _playVideoPath = [videoDict objectForKey:KEY_CHAT_VIDEO_RECORD_VIDEOPATH];
        NSInteger stime = [[videoDict objectForKey:KEY_CHAT_VIDEO_RECORD_STIME] integerValue];
        self.lblStime.text = [NSString stringWithFormat:@"视频时长：%lds",(long)stime];
        [self addSightPlay:_playVideoPath];
    }
}


#pragma mark - event
- (IBAction)btnSightTouchUpInside:(UIButton *)sender {
    
    if ([SRUtil checkMediaVideoSupported]) {
        [self showSightViewController];
    }
    else
    {
        [SRUtil alertViewMessage:@"检测到无法使用您的相机录制视频" disappearAfter:0.0f withViewController:self];
    }
}

- (void)viewContentTapped:(UITapGestureRecognizer *)sender
{
    [self bigScreenPlaySight:_playVideoPath];
}

#pragma mark - sight

- (void)showSightViewController
{
    self.sightViewController.view.hidden = NO;
    [self.sightViewController showViewContent];
}

- (void)addSightPlay:(NSString *)videoPath
{
    if (videoPath && ![videoPath isEqualToString:@""]) {
        
        if ([self checkFileExistsAtPath:videoPath]) {
            CGSize size = self.viewContent.frame.size;
            self.sightOperation = [[IMPlaySightOperation alloc] initVideoFileURL:[NSURL fileURLWithPath:videoPath] withFrame:CGRectMake(0, 0, size.width, size.height) withView:self.viewContent];
            
            [self.sightOperation playSight];
        }
        else
        {
            NSLog(@"need download");
        }
    }
    else
    {
        NSLog(@"video Path is null");
    }
}

- (BOOL)checkFileExistsAtPath:(NSString *)fileURL
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL exist = [fileManager fileExistsAtPath:fileURL];
    return exist;
}

- (void)bigScreenPlaySight:(NSString *)filePath
{
    if (nil == self.bigScreenPlaySightViewController) {
        self.bigScreenPlaySightViewController = [SRUtil embedController:@"FullScreenPlayVideoViewController" inStoryboard:@"Main" toContainerController:self withContainerView:self.view];
    }
    [self.bigScreenPlaySightViewController updateVideoFileURL:[NSURL fileURLWithPath:filePath]];
}

@end
