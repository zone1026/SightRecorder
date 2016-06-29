//
//  IMVideoRecorder.h
//  SightRecorder
//
//  Created by 黄 on 16/6/28.
//  Copyright © 2016年 黄. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <AVFoundation/AVFoundation.h>

#define MIN_VIDEO_DUR 1.0f
#define MAX_VIDEO_DUR 8.0f

//此状态表示视频的制作时的各个状态
typedef NS_ENUM(NSInteger, VideoState)
{
    VideoStateFree = 0,
    VideoStateWillStartRecord,
    VideoStateDidStartRecord,
    VideoStateWillEndRecord,
    VideoStateDidEndRecord,
    VideoStateWillStartMerge,
    VideoStateDidStartMerge,
};

//与VideoState不同
//此状态表示用户操作时的状态，比如：已经开始录制、停止录制
typedef NS_ENUM(NSInteger, RecordOptState)
{
    RecordOptStateFree = 0,
    RecordOptStateBegin,
    RecordOptStateEnd,
};

typedef NS_ENUM(NSInteger, CurrentRecordRegion)
{
    CurrentRecordRegionFree = 0,
    CurrentRecordRegionRecord,
    CurrentRecordRegionCancelRecord,
};

@protocol IMVideoRecorderDelegate <NSObject>

@optional
//recorder开始录制一段视频时
- (void)didStartRecordingToOutPutFileAtURL:(NSURL *)fileURL;

//recorder正在录制的过程中
- (void)didRecordingToOutPutFileAtURL:(NSURL *)outputFileURL duration:(CGFloat)videoDuration recordedVideosTotalDur:(CGFloat)totalDur;

//recorder删除了某一段视频
- (void)didRemoveVideoFileAtURL:(NSURL *)fileURL totalDur:(CGFloat)totalDur error:(NSError *)error;

@required
//recorder完成一段视频的录制时
- (void)didFinishRecordingToOutPutFileAtURL:(NSURL *)outputFileURL duration:(CGFloat)videoDuration totalDur:(CGFloat)totalDur error:(NSError *)error;

//recorder完成视频的合成
- (void)didFinishMergingVideosToOutPutFileAtURL:(NSURL *)outputFileURL;

@end

@interface IMVideoRecorder : NSObject <AVCaptureFileOutputRecordingDelegate>//视频文件输出代理

@property (weak, nonatomic) id <IMVideoRecorderDelegate> delegate;

@property (nonatomic, strong) AVCaptureVideoPreviewLayer *preViewLayer;//相机拍摄预览图层
@property (nonatomic, strong) AVCaptureSession *captureSession;//负责输入和输出设置之间的数据传递
@property (nonatomic, strong) AVCaptureMovieFileOutput *movieFileOutput;//视频输出流
@property (strong, nonatomic) AVCaptureDeviceInput *videoDeviceInput;//负责从AVCaptureDevice获得输入数据

/**
 * 视频录制的持续时间
 */
- (CGFloat)getTotalVideoDuration;

/**
 * 停止当前视频的录制
 */
- (void)stopCurrentVideoRecording;

/**
 * 制定录制视屏的路径
 */
- (void)startRecordingToOutputFileURL;

/**
 * 返回录制视频的个数
 */
- (NSInteger)getVideoCount;

/**
 * 转换MP4视频
 */
- (void)mergeVideoFiles;

/**
 * 相机是否可以使用
 */
- (BOOL)isCameraSupported;

/**
 * 前摄像头是否可以使用
 */
- (BOOL)isFrontCameraSupported;

/**
 * 闪光灯是否可用
 */
- (BOOL)isTorchSupported;


- (void)switchCamera;

/**
 * 手电筒开关
 */
- (void)openTorch:(BOOL)open;

/**
 * 对焦
 */
- (void)focusInPoint:(CGPoint)touchPoint;

/**
 * 是否需要合并视频，即是否支持多段视频的录制
 */
- (void)switchNeedMergeVideo:(BOOL)needMerge;

/**
 * 释放相关数据
 */
- (void)releaseCaptureData;

/**
 * 获得视频制作时目前所处的状态
 */
- (VideoState)getVideoState;

/**
 * 双击放大
 */
- (void)changeDeviceVideoZoomFactor;

/**
 * 更新用户操作下的录制状态
 */
- (void)updateRecordState:(RecordOptState)optState;

/**
 * 更新用户当前所处的的录制区域
 */
- (void)updateRecordRegion:(CurrentRecordRegion)recordRegion;
/**
 * 获取用户当前所处的的录制区域
 */
- (CurrentRecordRegion)getCurrentRecordRegion;

@end