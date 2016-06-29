//
//  ChatSightViewController.m
//  SightRecorder
//
//  Created by 黄 on 16/6/28.
//  Copyright © 2016年 黄. All rights reserved.
//

#import "ChatSightViewController.h"
#import "IMVideoRecorder.h"
#import "ChatHistorySightCollectionViewCell.h"
#import "ChatDataProxy.h"
#import "UIView+SRTools.h"
#import "CALayer+SRUtil.h"
#import "SRUtil.h"

#define FOCUS_CURSOR_WIDTH 60
#define PROGRESS_PREVIEW_HEIGHT 4

typedef NS_ENUM(NSInteger, ChatSightViewControllerTipsType)
{
    ChatSightViewControllerTipsTypeFree = 0,//空闲的状态
    ChatSightViewControllerTipsTypeStartRecord,
    ChatSightViewControllerTipsTypeCancel,
    ChatSightViewControllerTipsTypeTimeShort,
};

@interface ChatSightViewController () <IMVideoRecorderDelegate, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UIView *viewContent;
@property (weak, nonatomic) IBOutlet UIView *viewSightContent;
@property (weak, nonatomic) IBOutlet UIImageView *imgShoot;
@property (weak, nonatomic) IBOutlet UILabel *lblZoomInTips;
@property (weak, nonatomic) IBOutlet UIButton *btnClose;
@property (weak, nonatomic) IBOutlet UIButton *btnHistory;

@property (weak, nonatomic) IBOutlet UIView *viewHistory;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionViewSight;
@property (weak, nonatomic) IBOutlet UIButton *btnHistoryViewClose;
@property (weak, nonatomic) IBOutlet UIButton *btnEdit;
- (IBAction)btnEditTouchUpInside:(UIButton *)sender;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintViewContentBottom;

- (IBAction)btnHistoryTouchUpInside:(UIButton *)sender;
- (IBAction)btnCloseTouchUpInside:(UIButton *)sender;

@property (nonatomic, strong) IMVideoRecorder *recorder;

@property (nonatomic, retain) UIView* progressPreView; //进度条
@property (strong,nonatomic)  UIImageView *focusCursor; //聚焦光标

@property (nonatomic) BOOL isCanRecord;//是否可以开始录制,动画播放完之后，才可以录制视频

@property (nonatomic, retain) UILabel *lblTips;

@property (nonatomic) ChatSightViewControllerTipsType currentTipsType;

@property (nonatomic) CGFloat sightViewBottomY;//小视频录制界面的底边Y轴坐标点

//单击
@property (nonatomic, retain) UITapGestureRecognizer *tapGestureSight;
//双击
@property (nonatomic, retain) UITapGestureRecognizer *douleTapGestureSight;

@property (nonatomic, retain) NSMutableArray *historySightArr;

@property (nonatomic) CGSize collectionViewCellSize;

@property (nonatomic) BOOL needUpdateViewHistory;

@property (nonatomic, retain) ChatHistorySightCollectionViewCell *selectedHistorySightCell;

@end

@implementation ChatSightViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.btnEdit.hidden = YES;
    
    CGFloat collectionViewCellWith = ([UIScreen mainScreen].bounds.size.width - 320) / 3 + 95;
    CGFloat collectionViewCellHeight = collectionViewCellWith * 75 / 95;
    _collectionViewCellSize = CGSizeMake(collectionViewCellWith, collectionViewCellHeight);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.constraintViewContentBottom.constant = - ([UIScreen mainScreen].bounds.size.height);
    
    CGRect rect = self.viewSightContent.frame;
    _sightViewBottomY = rect.size.height + rect.origin.y;
    self.historySightArr = [[ChatDataProxy sharedProxy] getHistorySightData];
    _needUpdateViewHistory = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    self.selectedHistorySightCell = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - other

- (void)showViewContent
{
    [self initSightSettingsData];
    
    [UIView animateWithDuration:0.3f animations:^{
        self.viewContent.frame = CGRectMake(0.0f, self.view.frame.size.height - self.viewContent.frame.size.height, self.view.frame.size.width, self.viewContent.frame.size.height);
        self.constraintViewContentBottom.constant = 0;
        
    } completion:^(BOOL finished) {
        [self performSelector:@selector(showViewContentCompletion) withObject:nil afterDelay:0.5f];
    }];
}

//打开录制小视频之前，做一些设置
- (void)initSightSettingsData
{
    self.viewHistory.hidden = YES;
    
    self.imgShoot.hidden = YES;
    
    self.lblTips.hidden = YES;
    
    _isCanRecord = NO;
    
    _currentTipsType = ChatSightViewControllerTipsTypeFree;
    
    self.lblZoomInTips.alpha = 1.0f;
}

- (void)showViewContentCompletion
{
    [self initRecorder];
    [self addGenstureRecognizer];
    [self addProgressPreView];
    
    [self setFocusCursorWithPoint:self.focusCursor.center];
    [self hiddenZoomInTips];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(showViewContentCompletion) object:nil];
}

- (void)hiddenViewContent
{
    [UIView animateWithDuration:0.3f animations:^{
        self.viewContent.frame = CGRectMake(0.0f, self.view.frame.size.height, self.view.frame.size.width, self.viewContent.frame.size.height);
        self.constraintViewContentBottom.constant = - ([UIScreen mainScreen].bounds.size.height);
    } completion:^(BOOL finished) {
        self.view.hidden = YES;
        [self.recorder releaseCaptureData];
        self.recorder = nil;
        self.focusCursor.image = nil;
        self.focusCursor = nil;
    }];
}

- (void)initRecorder
{
    if (!self.recorder) {
        CGRect rect = self.viewSightContent.frame;
        
        self.recorder = [[IMVideoRecorder alloc] init];
        [self.recorder switchNeedMergeVideo:NO];
        self.recorder.delegate = self;
        self.recorder.preViewLayer.frame = CGRectMake(0, 0, rect.size.width, rect.size.height);
        [self.viewSightContent.layer insertSublayer:self.recorder.preViewLayer below:self.self.lblZoomInTips.layer];
    }
    
    if (!self.focusCursor) {
        CGSize size = self.viewSightContent.frame.size;
        self.focusCursor = [[UIImageView alloc]initWithFrame:CGRectMake((size.width - FOCUS_CURSOR_WIDTH)/2, (size.height - FOCUS_CURSOR_WIDTH)/2, FOCUS_CURSOR_WIDTH, FOCUS_CURSOR_WIDTH)];
        [self.focusCursor setImage:[UIImage imageNamed:@"sight_positioning_box"]];
        self.focusCursor.alpha = 0;
        [self.viewSightContent addSubview:self.focusCursor];
    }
}

//定位框动画
-(void)setFocusCursorWithPoint:(CGPoint)point
{
    self.focusCursor.center = point;
    self.focusCursor.transform = CGAffineTransformMakeScale(1.5, 1.5);
    self.focusCursor.alpha = 1.0;
    [UIView animateWithDuration:0.5 animations:^{
        self.focusCursor.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        self.focusCursor.alpha = 0;
    }];
}

//双击放大 效果
-(void)hiddenZoomInTips
{
    self.lblZoomInTips.alpha = 1.0;
    [UIView animateWithDuration:1.2 animations:^{
        self.lblZoomInTips.transform = CGAffineTransformIdentity;
        self.lblZoomInTips.alpha = 0;
    } completion:^(BOOL finished) {
        _isCanRecord = YES;
        self.imgShoot.hidden = NO;
    }];
}

- (void)addGenstureRecognizer
{
    if (nil == self.tapGestureSight) {
        self.tapGestureSight = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapScreen:)];
        self.tapGestureSight.numberOfTapsRequired = 1;
        self.tapGestureSight.delaysTouchesBegan = YES;
        [self.viewSightContent addGestureRecognizer:self.tapGestureSight];
    }
    if (nil == self.douleTapGestureSight) {
        self.douleTapGestureSight = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(changeFocus:)];
        self.douleTapGestureSight.numberOfTapsRequired = 2;
        self.douleTapGestureSight.delaysTouchesBegan = YES;
        [self.viewSightContent addGestureRecognizer:self.douleTapGestureSight];
    }
    [self.tapGestureSight requireGestureRecognizerToFail:self.douleTapGestureSight];//requireGestureRecognizerToFail的作用是每次只生效一个手势
}

- (void)tapScreen:(UITapGestureRecognizer *)tapGesture
{
    CGPoint point = [tapGesture locationInView:self.viewSightContent];
    [self setFocusCursorWithPoint:point];
    [self.recorder focusInPoint:point];
}

//拉近/远镜头(焦距)
- (void)changeFocus:(UITapGestureRecognizer *)tapGesture
{
    if (self.recorder) {
        [self.recorder changeDeviceVideoZoomFactor];
    }
}

//进度条
- (void)addProgressPreView
{
    CGRect rect = self.viewSightContent.frame;
    self.progressPreView = [[UIView alloc]initWithFrame:CGRectMake(0, rect.size.height + rect.origin.y, 0, PROGRESS_PREVIEW_HEIGHT)];
    self.progressPreView.backgroundColor = [UIColor greenColor];
    [self.progressPreView makeCornerRadius:2 borderColor:nil borderWidth:0];
    [self.viewContent addSubview:self.progressPreView];
    
}

//视频录制时 添加的提示
- (void)addTipsLabel:(ChatSightViewControllerTipsType)type
{
    if (_currentTipsType == type) {
        return;
    }
    else
    {
        _currentTipsType = type;
        [self hiddenLblTips];
    }
    
    
    NSString *desc = nil;
    UIColor *textColor = nil;
    UIColor *bgColor = nil;
    
    if (ChatSightViewControllerTipsTypeStartRecord == type) {//上移取消
        desc = @"上移取消";
        textColor = [UIColor colorWithRed:7.0f/255.0f green:140.0f/255.0f blue:0.0f/255.0f alpha:1.0f];
    }
    else if (ChatSightViewControllerTipsTypeTimeShort == type)//时间太短，手指不要放开
    {
        desc = @"手指不要放开";
        textColor = [UIColor whiteColor];
        bgColor = [UIColor colorWithRed:228.0f/255.0f green:74.0f/255.0f blue:5.0f/255.0f alpha:1.0f];
    }
    else if (ChatSightViewControllerTipsTypeCancel == type)
    {
        desc = @"松手取消";
        textColor = [UIColor whiteColor];
        bgColor = [UIColor colorWithRed:228.0f/255.0f green:74.0f/255.0f blue:5.0f/255.0f alpha:1.0f];
    }
    
    CGSize size = self.viewSightContent.frame.size;
    CGFloat lblW = [self sizeWithDesc:desc].width + 12;
    
    self.lblTips = [[UILabel alloc] initWithFrame:CGRectMake((size.width - lblW)/2, size.height - 30 - 12 , lblW, 30)];
    if (nil == bgColor) {
        bgColor = [UIColor clearColor];
    }
    self.lblTips.backgroundColor = bgColor;
    
    if (nil == textColor) {
        textColor = [UIColor whiteColor];
    }
    self.lblTips.textColor = textColor;
    
    self.lblTips.textAlignment = NSTextAlignmentCenter;
    self.lblTips.text = desc;
    self.lblTips.font = [UIFont systemFontOfSize:14];
    self.lblTips.clipsToBounds = YES;
    [self.lblTips.layer setCornerRadius:COMMON_UI_ROUND_CORNER_BIG_RADIUS];
    [self.viewSightContent addSubview:self.lblTips];
}

- (void)hiddenLblTips
{
    [self.lblTips removeFromSuperview];
    self.lblTips = nil;
}

//返回字符串所占用的尺寸.
-(CGSize)sizeWithDesc:(NSString *)desc
{
    UIFont *font = [UIFont systemFontOfSize:14];
    NSDictionary *attribute = [NSDictionary dictionaryWithObjectsAndKeys:font,NSFontAttributeName, nil];
    CGSize labelsize = [desc boundingRectWithSize:CGSizeMake(200, 100)
                                          options: NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                       attributes:attribute
                                          context:nil].size;
    return labelsize;
}

- (IBAction)btnHistoryTouchUpInside:(UIButton *)sender {
    
    if (_needUpdateViewHistory)
    {
        self.historySightArr = [[ChatDataProxy sharedProxy] getHistorySightData];
        [self.collectionViewSight reloadData];
        _needUpdateViewHistory = NO;
    }
    
    self.viewHistory.hidden = NO;
    
    [UIView animateWithDuration:0.3f animations:^{
        self.viewContent.frame = CGRectMake(0.0f, self.view.frame.size.height, self.view.frame.size.width, self.viewContent.frame.size.height);
        self.constraintViewContentBottom.constant = - ([UIScreen mainScreen].bounds.size.height);
    } completion:^(BOOL finished) {
        [self.recorder releaseCaptureData];
        self.recorder = nil;
        self.focusCursor.image = nil;
        self.focusCursor = nil;
    }];
}

- (IBAction)btnCloseTouchUpInside:(UIButton *)sender {
    
    if (self.selectedHistorySightCell) {
        [self.selectedHistorySightCell selectedSight:NO];
    }
    
    [self hiddenViewContent];
}

- (IBAction)btnEditTouchUpInside:(UIButton *)sender {
}

- (void)sendHistorySight:(NSString *)videoPath
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *cahceVideoPath = [SRUtil getVideoCachePath:videoPath.lastPathComponent];
        NSError *error = nil;
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:cahceVideoPath]) {
            
        }
        else
        {
            [[NSFileManager defaultManager] copyItemAtPath:videoPath toPath:cahceVideoPath error:&error];
        }
        
        if (error) {
            NSLog(@"copy video file error %@",error);
        }
        else
        {
            self.imgShoot.hidden = NO;
            self.btnClose.hidden = NO;
            self.btnHistory.hidden = NO;
            
            NSDictionary *opts = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO]
                                                             forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
            
            AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:cahceVideoPath] options:opts];
            
            NSInteger stime = urlAsset.duration.value/urlAsset.duration.timescale;
            
            NSMutableDictionary *videoDict = [NSMutableDictionary dictionary];
            [videoDict setObject:cahceVideoPath forKey:KEY_CHAT_VIDEO_RECORD_VIDEOPATH];
            [videoDict setObject:@(stime) forKey:KEY_CHAT_VIDEO_RECORD_STIME];
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTI_CHAT_VIDEO_RECORD_FINSH object:nil userInfo:videoDict];
            
            [self hiddenViewContent];
            
            if (self.selectedHistorySightCell) {
                [self.selectedHistorySightCell selectedSight:NO];
            }
        }
    });
}

#pragma mark - IMVideoRecorderDelegate

- (void)didStartRecordingToOutPutFileAtURL:(NSURL *)fileURL
{
    //    NSLog(@"正在录制视频: %@", fileURL);
}

- (void)didFinishRecordingToOutPutFileAtURL:(NSURL *)outputFileURL duration:(CGFloat)videoDuration totalDur:(CGFloat)totalDur error:(NSError *)error
{
    CGRect rect = self.viewSightContent.frame;
    [self.progressPreView setFrame:CGRectMake(0, rect.size.height + rect.origin.y, 0, PROGRESS_PREVIEW_HEIGHT)];
    
    if ([self.recorder getTotalVideoDuration] < MIN_VIDEO_DUR) {
        if (ChatSightViewControllerTipsTypeStartRecord == _currentTipsType) {
            [self addTipsLabel:ChatSightViewControllerTipsTypeTimeShort];
        }
        
        self.imgShoot.hidden = NO;
        self.btnClose.hidden = NO;
        self.btnHistory.hidden = NO;
        return;
    }
    else
    {
        if (error) {
            NSLog(@"录制视频错误:%@", error);
        } else {
            if (CurrentRecordRegionRecord == [self.recorder getCurrentRecordRegion])
            {
                [self.recorder mergeVideoFiles];
            }
            else if (CurrentRecordRegionCancelRecord == [self.recorder getCurrentRecordRegion])
            {
                if ([self.recorder getTotalVideoDuration] >= MAX_VIDEO_DUR)
                {
                    [self hiddenViewContent];
                }
                else
                {
                    self.imgShoot.hidden = NO;
                    self.btnClose.hidden = NO;
                    self.btnHistory.hidden = NO;
                    self.lblTips.hidden = YES;
                }
            }
        }
    }
}

- (void)didRecordingToOutPutFileAtURL:(NSURL *)outputFileURL duration:(CGFloat)videoDuration recordedVideosTotalDur:(CGFloat)totalDur
{
    CGRect rect = self.viewSightContent.frame;
    CGFloat progressWidth = videoDuration /MAX_VIDEO_DUR * rect.size.width;
    [self.progressPreView setFrame:CGRectMake(progressWidth/2, rect.size.height + rect.origin.y, rect.size.width - progressWidth, PROGRESS_PREVIEW_HEIGHT)];
}

- (void)didFinishMergingVideosToOutPutFileAtURL:(NSURL *)outputFileURL
{
    self.imgShoot.hidden = NO;
    self.btnClose.hidden = NO;
    self.btnHistory.hidden = NO;
    
    NSString *videoPath = [outputFileURL absoluteString];
    videoPath = [videoPath stringByReplacingOccurrencesOfString:@"file://" withString:@""];
    NSInteger stime = [self.recorder getTotalVideoDuration];
    
    NSMutableDictionary *videoDict = [NSMutableDictionary dictionary];
    [videoDict setObject:videoPath forKey:KEY_CHAT_VIDEO_RECORD_VIDEOPATH];
    [videoDict setObject:@(stime) forKey:KEY_CHAT_VIDEO_RECORD_STIME];
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTI_CHAT_VIDEO_RECORD_FINSH object:nil userInfo:videoDict];
    
    [self hiddenViewContent];
    
    _needUpdateViewHistory = YES;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (self.historySightArr) {
        return self.historySightArr.count;
    }
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ChatHistorySightCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"sightCell" forIndexPath:indexPath];
    [cell updateSightPath:[self.historySightArr objectAtIndex:indexPath.row] withSize:_collectionViewCellSize];
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView *view;
    
    if ([kind isEqualToString:UICollectionElementKindSectionHeader])
    {
        view = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"sightHeaderReusableView" forIndexPath:indexPath];
    }
    else if ([kind isEqualToString:UICollectionElementKindSectionFooter])
    {
        view = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"sightFooterReusableView" forIndexPath:indexPath];
        UILabel *lblTip = [view viewWithTag:1];
        lblTip.text = [NSString stringWithFormat:@"最近 %ld 天拍摄的小视频",(long)SIGHT_OVERDUE_TIME_DAY];
    }
    
    return view;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *filePath = [self.historySightArr objectAtIndex:indexPath.row];
    if (filePath) {
        if ([filePath isEqualToString:@"gotoRecordSight"]) {
            self.viewHistory.hidden = YES;
            [self showViewContent];
        }
        else
        {
            ChatHistorySightCollectionViewCell *cell = (ChatHistorySightCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
            
            if (cell.selectedSight) {
                [self sendHistorySight:filePath];
            }
            else
            {
                [cell selectedSight:YES];
            }
            
            self.selectedHistorySightCell = cell;
        }
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *filePath = [self.historySightArr objectAtIndex:indexPath.row];
    if (filePath) {
        if (![filePath isEqualToString:@"gotoRecordSight"])
        {
            ChatHistorySightCollectionViewCell *cell = (ChatHistorySightCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
            
            [cell selectedSight:NO];
        }
    }
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return _collectionViewCellSize;
}

#pragma mark - Touch Event

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:self.viewContent];
    if (CGRectContainsPoint(self.imgShoot.frame, touchPoint)) {
        if (_isCanRecord) {
            
            CGRect rect = self.viewSightContent.frame;
            [self.progressPreView setFrame:CGRectMake(0, rect.size.height + rect.origin.y, rect.size.width, PROGRESS_PREVIEW_HEIGHT)];
            [self.recorder startRecordingToOutputFileURL];
            self.imgShoot.hidden = YES;
            self.btnClose.hidden = YES;
            self.btnHistory.hidden = YES;
            self.lblTips.hidden = NO;
            [self addTipsLabel:ChatSightViewControllerTipsTypeStartRecord];
            
            [self.recorder updateRecordRegion:CurrentRecordRegionRecord];
            self.progressPreView.backgroundColor = [UIColor greenColor];
        }
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (self.recorder) {
        
        [self.recorder updateRecordState:RecordOptStateEnd];
        
        if (VideoStateDidStartRecord == [self.recorder getVideoState]) {
            if (CurrentRecordRegionRecord == [self.recorder getCurrentRecordRegion]) {
                [self.recorder stopCurrentVideoRecording];
            }
            else if (CurrentRecordRegionCancelRecord == [self.recorder getCurrentRecordRegion])
            {
                [self.recorder stopCurrentVideoRecording];
                self.imgShoot.hidden = NO;
                self.btnClose.hidden = NO;
                self.btnHistory.hidden = NO;
                self.lblTips.hidden = YES;
                CGRect rect = self.viewSightContent.frame;
                [self.progressPreView setFrame:CGRectMake(0, rect.size.height + rect.origin.y, 0, PROGRESS_PREVIEW_HEIGHT)];
            }
        }
        
        return;
    }
    
    self.imgShoot.hidden = NO;
    self.btnClose.hidden = NO;
    self.btnHistory.hidden = NO;
    self.lblTips.hidden = YES;
    CGRect rect = self.viewSightContent.frame;
    [self.progressPreView setFrame:CGRectMake(0, rect.size.height + rect.origin.y, 0, PROGRESS_PREVIEW_HEIGHT)];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:self.viewContent];
    if (self.recorder && VideoStateDidStartRecord == [self.recorder getVideoState]) {
        if (touchPoint.y > _sightViewBottomY) {//在录制区域
            
            if (CurrentRecordRegionRecord == [self.recorder getCurrentRecordRegion]) {
                return;
            }
            [self.recorder updateRecordRegion:CurrentRecordRegionRecord];
            [self addTipsLabel:ChatSightViewControllerTipsTypeStartRecord];
            self.progressPreView.backgroundColor = [UIColor greenColor];
        }
        else //在取消区域
        {
            if (CurrentRecordRegionCancelRecord == [self.recorder getCurrentRecordRegion]) {
                return;
            }
            
            [self.recorder updateRecordRegion:CurrentRecordRegionCancelRecord];
            
            [self addTipsLabel:ChatSightViewControllerTipsTypeCancel];
            self.progressPreView.backgroundColor = [UIColor colorWithRed:228.0f/255.0f green:74.0f/255.0f blue:5.0f/255.0f alpha:1.0f];
        }
    }
}

@end
