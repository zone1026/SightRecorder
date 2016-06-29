//
//  IMVideoRecorder.m
//  SightRecorder
//
//  Created by 黄 on 16/6/28.
//  Copyright © 2016年 黄. All rights reserved.
//

#import "IMVideoRecorder.h"
#import "SRUtil.h"
#import "ChatDataProxy.h"

// 简单说明
//a、AVCaptureDevice。这里代表抽象的硬件设备。
//
//b、AVCaptureInput。这里代表输入设备（可以是它的子类），它配置抽象硬件设备的ports。
//
//c、AVCaptureOutput。它代表输出数据，管理着输出到一个movie或者图像。
//
//d、AVCaptureSession。它是input和output的桥梁。它协调着intput到output的数据传输。


#define COUNT_DUR_TIMER_INTERVAL 0.05

@interface IMVideoRecorder ()

@property (strong, nonatomic) NSTimer *countDurTimer;//视频录制计时器
@property (assign, nonatomic) CGFloat currentVideoDur;//持续时间
@property (assign, nonatomic) NSURL *currentFileURL;
@property (assign ,nonatomic) CGFloat totalVideoDur;

@property (strong, nonatomic) NSMutableArray *videoFileDataArray;

@property (assign, nonatomic) BOOL isFrontCameraSupported;
@property (assign, nonatomic) BOOL isCameraSupported;
@property (assign, nonatomic) BOOL isTorchSupported;
@property (assign, nonatomic) BOOL isTorchOn;
@property (assign, nonatomic) BOOL isUsingFrontCamera;
@property (nonatomic, assign) BOOL isNeedMergeVideo;//是否需要合并视频，即是否支持多段视频的录制

@property (nonatomic, assign) VideoState videoState;//录制的视频状态

//是否需要输出视频，比如：时间太短、取消录制等情况 不需要输出
//@property (nonatomic) BOOL needOutPutFile;

@property (nonatomic) RecordOptState recordOptState;

@property (nonatomic, retain) NSString *videoSaveFilePath;

@property (nonatomic) CurrentRecordRegion currentRecordRegion;//当前所处的录制区域

@end

@implementation IMVideoRecorder

- (id)init
{
    self = [super init];
    if (self) {
        [self initalize];
    }
    
    return self;
}

- (void)initalize
{
    [self initCapture];
    
    _videoState = VideoStateFree;
    _recordOptState = RecordOptStateFree;
    _currentRecordRegion = CurrentRecordRegionFree;
    
    self.videoFileDataArray = [NSMutableArray array];
    self.totalVideoDur = 0.0f;
}

- (void)releaseCaptureData
{
    if (self.captureSession) {
        [self.captureSession stopRunning];
        self.captureSession = nil;
    }
    
    if (self.movieFileOutput) {
        self.movieFileOutput = nil;
    }
    
    if (self.videoDeviceInput) {
        self.videoDeviceInput = nil;
    }
    
    if (self.preViewLayer) {
        [self.preViewLayer removeFromSuperlayer];
        self.preViewLayer = nil;
    }
    
    [self stopCountDurTimer];
    
    self.currentFileURL = nil;
    
    _videoState = VideoStateFree;
}

- (void)initCapture
{
    self.captureSession = [[AVCaptureSession alloc] init];
    
    AVCaptureDevice *frontCamera = nil;
    AVCaptureDevice *backCamera = nil;
    
    NSArray *cameras = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *camera in cameras) {
        if (AVCaptureDevicePositionFront == camera.position) {//前置摄像头
            frontCamera = camera;
        }
        else if (AVCaptureDevicePositionBack == camera.position)
        {
            backCamera = camera;
        }
    }
    
    if (!backCamera) {
        self.isCameraSupported = NO;
        return;
    }
    else
    {
        self.isCameraSupported = YES;
        
        if ([backCamera hasTorch]) {
            self.isTorchSupported = YES;
        }
        else
        {
            self.isTorchSupported = NO;
        }
    }
    
    if (!frontCamera) {
        self.isFrontCameraSupported = NO;
    }
    else
    {
        self.isFrontCameraSupported = YES;
    }
    
    
    [backCamera lockForConfiguration:nil];
    if ([backCamera isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
        [backCamera setExposureMode:AVCaptureExposureModeContinuousAutoExposure];//曝光量调节
    }
    
    if ([backCamera isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {//焦点CGPoint
        [backCamera setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
    }
    
    [backCamera unlockForConfiguration];
    
    [self.captureSession beginConfiguration];
    //input device
    self.videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:backCamera error:nil];
    AVCaptureDeviceInput *audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio] error:nil];
    if ([self.captureSession canAddInput:self.videoDeviceInput]) {
        [self.captureSession addInput:self.videoDeviceInput];
    }
    if ([self.captureSession canAddInput:audioDeviceInput]) {
        [self.captureSession addInput:audioDeviceInput];
    }
    
    //output device
    self.movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    if ([self.captureSession canAddOutput:self.movieFileOutput]) {
        [self.captureSession addOutput:self.movieFileOutput];
    }
    
    //preset
    if ([self.captureSession canSetSessionPreset:AVCaptureSessionPreset640x480]) {
        self.captureSession.sessionPreset = AVCaptureSessionPreset640x480;//AVCaptureSessionPresetLow
    }
    
    //preview layer
    self.preViewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    self.preViewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    [self.captureSession commitConfiguration];
    [self.captureSession startRunning];//开始运行
}

- (void)startCountDurTimer
{
    self.countDurTimer = [NSTimer scheduledTimerWithTimeInterval:COUNT_DUR_TIMER_INTERVAL target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
}

- (void)onTimer:(NSTimer *)timer
{
    if (self.delegate && [self.delegate conformsToProtocol:@protocol(IMVideoRecorderDelegate)] && [self.delegate respondsToSelector:@selector(didRecordingToOutPutFileAtURL:duration:recordedVideosTotalDur:)]) {
        [self.delegate didRecordingToOutPutFileAtURL:self.currentFileURL duration:self.currentVideoDur recordedVideosTotalDur:self.totalVideoDur];
    }
    
    if (self.totalVideoDur + self.currentVideoDur >= MAX_VIDEO_DUR) {
        
        [self stopCurrentVideoRecording];
    }
    else
    {
        self.currentVideoDur += COUNT_DUR_TIMER_INTERVAL;
    }
}

- (void)stopCountDurTimer
{
    _videoState = VideoStateFree;
    
    if (self.countDurTimer) {
        [self.countDurTimer invalidate];
        self.countDurTimer = nil;
    }
}

/*
 * 合成并导出视频
 */
- (void)mergeAndExportVideoAtFileURLs:(NSArray *)fileURLArray
{
    _videoState = VideoStateWillStartMerge;
    
    NSError *error = nil;
    
    //渲染尺寸
    CGSize renderSize = CGSizeMake(0, 0);
    
    NSMutableArray *layerInstructionArray = [NSMutableArray array];
    
    //用来合成视频
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
    
    CMTime totalDuration = kCMTimeZero;
    
    //先取assetTrack 也为了取renderSize
    NSMutableArray *assetTrackArray = [NSMutableArray array];
    NSMutableArray *assetArray = [NSMutableArray array];
    
    for (NSURL *fileURL in fileURLArray) {
        
        //AVAsset：素材库里的素材
        AVAsset *asset = [AVAsset assetWithURL:fileURL];
        
        if (!asset) {
            continue;
        }
        
        [assetArray addObject:asset];
        
        //素材的轨道
        AVAssetTrack *assetTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];//返回一个数组AVAssetTracks资产
        [assetTrackArray addObject:assetTrack];
        
        renderSize.width = MAX(renderSize.width, assetTrack.naturalSize.height);
        renderSize.height = MAX(renderSize.height, assetTrack.naturalSize.width);
    }
    
    CGFloat renderW = 320;
    
    for (NSInteger i = 0; i < [assetArray count] && i < assetTrackArray.count; i++) {
        
        AVAsset *asset = [assetArray objectAtIndex:i];
        AVAssetTrack *assetTrack = [assetTrackArray objectAtIndex:i];
        
        //文件中的音频轨道，里面可以插入各种对应的素材
        AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        
        NSArray*dataSourceArray= [asset tracksWithMediaType:AVMediaTypeAudio];//获取声道，即麦克风相关信息
        [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:((dataSourceArray.count > 0)?[dataSourceArray objectAtIndex:0]:nil) atTime:totalDuration error:nil];
        
        //工程文件中的轨道，有音频轨，里面可以插入各种对应的素材
        AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:assetTrack atTime:totalDuration error:&error];
        
        //视频轨道中的一个视频，可以缩放、旋转等
        AVMutableVideoCompositionLayerInstruction *layerInstrucition = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
        
        totalDuration = CMTimeAdd(totalDuration, asset.duration);
        
        CGFloat rate = renderW / MIN(assetTrack.naturalSize.width, assetTrack.naturalSize.height);
        
        CGAffineTransform layerTransform = CGAffineTransformMake(assetTrack.preferredTransform.a, assetTrack.preferredTransform.b, assetTrack.preferredTransform.c, assetTrack.preferredTransform.d, assetTrack.preferredTransform.tx * rate, assetTrack.preferredTransform.ty * rate);
        layerTransform = CGAffineTransformConcat(layerTransform, CGAffineTransformMake(1, 0, 0, 1, 0, -(assetTrack.naturalSize.width - assetTrack.naturalSize.height) / 2.0));//向上移动取中部影相
        layerTransform = CGAffineTransformScale(layerTransform, rate, rate);//放缩，解决前后摄像结果大小不对称
        
        [layerInstrucition setTransform:layerTransform atTime:kCMTimeZero];
        [layerInstrucition setOpacity:0.0 atTime:totalDuration];
        
        //data
        [layerInstructionArray addObject:layerInstrucition];
    }
    
    //get save path
    NSURL *mergeFileURL = [NSURL fileURLWithPath:[self getVideoMergeFilePathString]];
    
    //export
    AVMutableVideoCompositionInstruction *mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, totalDuration);
    mainInstruction.layerInstructions = layerInstructionArray;
    AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];
    mainCompositionInst.instructions = @[mainInstruction];
    mainCompositionInst.frameDuration = CMTimeMake(1, 100);
    mainCompositionInst.renderSize = CGSizeMake(renderW, renderW * 0.75);
    //资源导出
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetMediumQuality];
    exporter.videoComposition = mainCompositionInst;
    exporter.outputURL = mergeFileURL;
    exporter.outputFileType = AVFileTypeMPEG4;//视频格式MP4
    exporter.shouldOptimizeForNetworkUse = YES;
    
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            
            _videoState = VideoStateDidStartMerge;
            
            if (self.delegate && [self.delegate conformsToProtocol:@protocol(IMVideoRecorderDelegate)] && [self.delegate respondsToSelector:@selector(didFinishMergingVideosToOutPutFileAtURL:)]) {
                NSInteger kb = [self getFileSize:[mergeFileURL absoluteString]];
                NSString *kbStr = [NSString stringWithFormat:@"%ld kb", (long)kb];
                NSLog(@"视频大小 kb == > %@",kbStr);
                NSLog(@"本段视频的时间: %f", _currentVideoDur);
                NSLog(@"录制视频完成: %@", mergeFileURL);
                [self.delegate didFinishMergingVideosToOutPutFileAtURL:mergeFileURL];
            }
            
            [self removeMovFile];
            
            [[ChatDataProxy sharedProxy] addNewHistorySight:[mergeFileURL absoluteString]];
            
        });
    }];
}

- (AVCaptureDevice *)getCameraDevice:(BOOL)isFront
{
    NSArray *cameras = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    AVCaptureDevice *frontCamera;
    AVCaptureDevice *backCamera;
    
    for (AVCaptureDevice *camera in cameras) {
        if (AVCaptureDevicePositionFront == camera.position) {
            frontCamera = camera;
        }
        else if (AVCaptureDevicePositionBack == camera.position)
        {
            backCamera = camera;
        }
    }
    
    if (isFront) {
        return frontCamera;
    }
    
    return backCamera;
}

//Coordinates坐标点 转换为Interest坐标点
- (CGPoint)convertToPointOfInterestFromViewCoordinates:(CGPoint)viewCoordinates
{
    CGPoint pointOfInterest = CGPointMake(0.5f, 0.5f);
    CGSize frameSize = self.preViewLayer.bounds.size;
    
    //需要按照项目实际情况修改
    AVCaptureVideoPreviewLayer *videoPreviewLayer = self.preViewLayer;
    
    if ([[videoPreviewLayer videoGravity] isEqualToString:AVLayerVideoGravityResize]) {
        pointOfInterest = CGPointMake(viewCoordinates.y / frameSize.height, 1.0f - (viewCoordinates.x / frameSize.width));
    }
    else
    {
        CGRect cleanAperture;
        
        for (AVCaptureInputPort *port in [self.videoDeviceInput ports])
        {//需要按照项目实际情况修改，必须是正在使用的videoInput
            if (AVMediaTypeVideo == [port mediaType]) {
                cleanAperture = CMVideoFormatDescriptionGetCleanAperture([port formatDescription], YES);
                CGSize apertureSize = cleanAperture.size;
                CGPoint point = viewCoordinates;
                
                CGFloat apertureRatio = apertureSize.height / apertureSize.width;
                CGFloat viewRatio = frameSize.width / frameSize.height;
                CGFloat xc = 0.5f;
                CGFloat yc = 0.5f;
                
                if ([[videoPreviewLayer videoGravity] isEqualToString:AVLayerVideoGravityResizeAspect]) {
                    if (viewRatio > apertureRatio) {
                        CGFloat y2 = frameSize.height;
                        CGFloat x2 = frameSize.height * apertureRatio;
                        CGFloat x1 = frameSize.width;
                        CGFloat blackBar = (x1 - x2) / 2;
                        
                        if (point.x >= blackBar && point.x <= blackBar + x2)
                        {
                            xc = point.y / y2;
                            yc = 1.0f - ((point.x - blackBar) / x2);
                        }
                    }
                    else
                    {
                        CGFloat y2 = frameSize.width / apertureRatio;
                        CGFloat y1 = frameSize.height;
                        CGFloat x2 = frameSize.width;
                        CGFloat blackBar = (y1 - y2) / 2;
                        if (point.y >= blackBar && point.y <= blackBar + y2)
                        {
                            xc = (point.y - blackBar) / y2;
                            yc = 1.0f - (point.x / x2);
                        }
                    }
                }
                else if ([[videoPreviewLayer videoGravity] isEqualToString:AVLayerVideoGravityResizeAspectFill])
                {
                    if (viewRatio > apertureRatio) {
                        CGFloat y2 = apertureSize.width * (frameSize.width / apertureSize.height);
                        xc = (point.y + (y2 - frameSize.height) / 2.0f) / y2;
                        yc = (frameSize.width - point.x) / frameSize.width;
                    }
                    else
                    {
                        CGFloat x2 = apertureSize.height * (frameSize.height / apertureSize.width);
                        yc = 1.0f - ((point.x + ((x2 - frameSize.width) / 2)) / x2);
                        xc = point.y / frameSize.height;
                    }
                }
                pointOfInterest = CGPointMake(xc, yc);
                break;
            }
        }
    }
    
    return pointOfInterest;
}

//对焦
- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        AVCaptureDevice *device = [self.videoDeviceInput device];
        NSError *error = nil;
        
        if ([device lockForConfiguration:&error]) {
            if ([device isFocusPointOfInterestSupported]) {
                [device setFocusPointOfInterest:point];
            }
            
            if ([device isFocusModeSupported:focusMode]) {
                [device setFocusMode:focusMode];
            }
            
            if ([device isExposurePointOfInterestSupported]) {
                [device setExposurePointOfInterest:point];
            }
            
            if ([device isExposureModeSupported:exposureMode]) {
                [device setExposureMode:exposureMode];
            }
            
            [device setSubjectAreaChangeMonitoringEnabled:monitorSubjectAreaChange];
            [device unlockForConfiguration];
        }
        else
        {
            NSLog(@"对焦错误:%@", error);
        }
    });
}

#pragma mark - Method

- (void)focusInPoint:(CGPoint)touchPoint
{
    CGPoint devicePoint = [self convertToPointOfInterestFromViewCoordinates:touchPoint];
    [self focusWithMode:AVCaptureFocusModeAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:devicePoint monitorSubjectAreaChange:YES];
}

//手电筒开关
- (void)openTorch:(BOOL)open
{
    self.isTorchOn = open;
    
    if (!self.isTorchSupported) {
        return;
    }
    
    AVCaptureTorchMode torchMode;
    if (open) {
        torchMode = AVCaptureTorchModeOn;
    }
    else
    {
        torchMode = AVCaptureTorchModeOff;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        [device lockForConfiguration:nil];
        [device setTorchMode:torchMode];
        [device unlockForConfiguration];
    });
}

- (void)switchCamera
{
    if (!_isFrontCameraSupported || !_isCameraSupported || !_videoDeviceInput) {
        return;
    }
    
    if (_isTorchOn) {
        [self openTorch:NO];
    }
    
    [self.captureSession beginConfiguration];
    
    [self.captureSession removeInput:self.videoDeviceInput];
    
    self.isUsingFrontCamera = !self.isUsingFrontCamera;
    
    AVCaptureDevice *device = [self getCameraDevice:_isUsingFrontCamera];
    [device lockForConfiguration:nil];
    
    if ([device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
        [device setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
    }
    [device unlockForConfiguration];
    
    self.videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    if ([self.captureSession canAddInput:self.videoDeviceInput]) {
        [self.captureSession addInput:self.videoDeviceInput];
    }
    [self.captureSession commitConfiguration];
}

- (BOOL)isTorchSupported
{
    return _isTorchSupported;
}

- (BOOL)isFrontCameraSupported
{
    return _isFrontCameraSupported;
}

- (BOOL)isCameraSupported
{
    return _isFrontCameraSupported;
}

- (void)switchNeedMergeVideo:(BOOL)needMerge
{
    _isNeedMergeVideo = needMerge;
}

- (void)updateRecordState:(RecordOptState)optState
{
    _recordOptState = optState;
}

- (void)updateRecordRegion:(CurrentRecordRegion)recordRegion
{
    _currentRecordRegion = recordRegion;
}

- (CurrentRecordRegion)getCurrentRecordRegion
{
    return _currentRecordRegion;
}

- (void)mergeVideoFiles
{
    [self mergeAndExportVideoAtFileURLs:[NSArray arrayWithObjects:self.currentFileURL, nil]];
}

//总时长
- (CGFloat)getTotalVideoDuration
{
    return _totalVideoDur;
}

//现在录了多少视频
- (NSInteger)getVideoCount
{
    return [_videoFileDataArray count];
}

- (void)startRecordingToOutputFileURL
{
    _videoState = VideoStateWillStartRecord;
    _recordOptState = RecordOptStateBegin;
    
    //根据设备输出获得连接
    AVCaptureConnection *captureConnection = [self.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
    //根据连接取得设备输出的数据
    if (![self.movieFileOutput isRecording]) {
        //预览图层和视频方向保持一致
        captureConnection.videoOrientation = [self.preViewLayer connection].videoOrientation;
        [self.movieFileOutput startRecordingToOutputFileURL:[NSURL fileURLWithPath:[self getVideoSaveFilePathString]] recordingDelegate:self];
    }
    else
    {
        [self stopCurrentVideoRecording];
    }
}

- (void)stopCurrentVideoRecording
{
    [self stopCountDurTimer];
    
    _videoState = VideoStateWillEndRecord;
    
    [self.movieFileOutput stopRecording];//停止录制
}

- (void)changeDeviceVideoZoomFactor
{
    AVCaptureDevice *backCamera = [self getCameraDevice:NO];
    
    CGFloat current = 1.0;
    
    if (1.0 == backCamera.videoZoomFactor) {
        current = 2.0f;
        if (current > backCamera.activeFormat.videoMaxZoomFactor) {
            current = backCamera.activeFormat.videoMaxZoomFactor;
        }
    }
    
    NSError *error = nil;
    if ([backCamera lockForConfiguration:&error]) {
        [backCamera rampToVideoZoomFactor:current withRate:10];
        [backCamera unlockForConfiguration];
    }
    else
    {
        NSLog(@"锁定设备过程error，错误信息：%@",error.localizedDescription);
    }
}

#pragma mark - AVCaptureFileOutputRecordingDelegate

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{
    _videoState = VideoStateDidStartRecord;
    
    self.videoSaveFilePath = [fileURL absoluteString];
    
    self.currentFileURL = fileURL;
    
    self.currentVideoDur = 0.0f;
    
    self.totalVideoDur = 0.0f;
    
    [self startCountDurTimer];
    
    if (self.delegate && [self.delegate conformsToProtocol:@protocol(IMVideoRecorderDelegate)] && [self.delegate respondsToSelector:@selector(didStartRecordingToOutPutFileAtURL:)]) {
        [self.delegate didStartRecordingToOutPutFileAtURL:fileURL];
    }
    
    if (RecordOptStateEnd == _recordOptState) {
        [self stopCurrentVideoRecording];
    }
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    _videoState = VideoStateDidEndRecord;
    
    self.totalVideoDur += _currentVideoDur;

    if (self.delegate && [self.delegate conformsToProtocol:@protocol(IMVideoRecorderDelegate)] && [self.delegate respondsToSelector:@selector(didFinishRecordingToOutPutFileAtURL:duration:totalDur:error:)]) {
        [self.delegate didFinishRecordingToOutPutFileAtURL:outputFileURL duration:_currentVideoDur totalDur:_totalVideoDur error:error];
    }
    
    if (CurrentRecordRegionRecord == [self getCurrentRecordRegion]) {
        if (self.totalVideoDur < MIN_VIDEO_DUR) {//录制时间太短
            [self removeMovFile];
            _videoState = VideoStateFree;
        }
    }
    else
    {
        [self removeMovFile];
        _videoState = VideoStateFree;
    }
}

#pragma mark - other opt
- (void)resetVideoData
{
    if (!_isNeedMergeVideo) {//不需要合并视频
        self.totalVideoDur = 0.0f;
        if (self.videoFileDataArray && self.videoFileDataArray.count > 0) {
            [self.videoFileDataArray removeAllObjects];
        }
    }
}

//最后合成为 mp4
- (NSString *)getVideoMergeFilePathString
{
    NSString *nowTimeStr = [NSString stringWithFormat:@"%lld",[SRUtil getNowTimeStamp]];
    NSString *videoName = [NSString stringWithFormat:@"%@.mp4",nowTimeStr];
    NSString *path = [SRUtil getVideoCachePath:videoName];
    
    return path;
}

//录制保存的时候要保存为 mov
- (NSString *)getVideoSaveFilePathString
{
    NSString *nowTimeStr = [NSString stringWithFormat:@"%lld",[SRUtil getNowTimeStamp]];
    NSString *videoName = [NSString stringWithFormat:@"%@.mov",nowTimeStr];
    NSString *path = [SRUtil getVideoCachePath:videoName];
    
    return path;
}

- (NSInteger) getFileSize:(NSString*) path
{
    path = [path stringByReplacingOccurrencesOfString:@"file://" withString:@""];
    NSFileManager * filemanager = [NSFileManager defaultManager];
    if([filemanager fileExistsAtPath:path]){
        NSDictionary * attributes = [filemanager attributesOfItemAtPath:path error:nil];
        NSNumber *theFileSize;
        if ( (theFileSize = [attributes objectForKey:NSFileSize]) )
            return  [theFileSize intValue]/1024;
        else
            return -1;
    }
    else
    {
        return -1;
    }
}

- (VideoState)getVideoState
{
    return _videoState;
}

//移除 mov 格式的视频文件
- (void)removeMovFile
{
    if (self.videoSaveFilePath) {
        NSString *path = self.videoSaveFilePath;
        path = [path stringByReplacingOccurrencesOfString:@"file://" withString:@""];
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            
            NSInteger kb = [self getFileSize:path];
            NSLog(@"video size is %ld",(long)kb);
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSError *error;
                [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
                if (error) {
                    NSLog(@"file remove error: %@",error);
                }
            });
        }
    }
    else
    {
        NSLog(@"error");
    }
}

@end
