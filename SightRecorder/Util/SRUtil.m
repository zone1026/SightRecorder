//
//  SRUtil.m
//  SightRecorder
//
//  Created by 黄 on 16/6/28.
//  Copyright © 2016年 黄. All rights reserved.
//

#import "SRUtil.h"
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>

@implementation SRUtil
/*
 AVAuthorizationStatusNotDetermined = 0,// 未进行授权选择
 
 AVAuthorizationStatusRestricted,　　　　// 未授权，且用户无法更新，如家长控制情况下
 
 AVAuthorizationStatusDenied,　　　　　　 // 用户拒绝App使用
 
 AVAuthorizationStatusAuthorized,　　　　// 已授权，可使用
 */
+ (BOOL)checkMediaVideoSupported
{
    BOOL isCameraAvailable = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
    BOOL doesCameraSupportTakingPhotos = [self doesCameraSupportTakingPhotos];
    
    if (isCameraAvailable && doesCameraSupportTakingPhotos) {
        AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        //如果被限制或者未打开
        if (AVAuthorizationStatusRestricted == authStatus || AVAuthorizationStatusDenied == authStatus) {
            return NO;
        }
        return YES;
    }
    return NO;
}

#pragma mark camera utility

+ (BOOL)isCameraAvailable{
    return [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
}

+ (BOOL)isRearCameraAvailable{
    return [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear];
}

+ (BOOL)isFrontCameraAvailable {
    return [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront];
}

+ (BOOL)doesCameraSupportTakingPhotos {
    return [self cameraSupportsMedia:(__bridge NSString *)kUTTypeImage sourceType:UIImagePickerControllerSourceTypeCamera];
}

+ (BOOL)isPhotoLibraryAvailable{
    return [UIImagePickerController isSourceTypeAvailable:
            UIImagePickerControllerSourceTypePhotoLibrary];
}

+ (BOOL)canUserPickVideosFromPhotoLibrary{
    return [self
            cameraSupportsMedia:(__bridge NSString *)kUTTypeMovie sourceType:UIImagePickerControllerSourceTypePhotoLibrary];
}

+ (BOOL)canUserPickPhotosFromPhotoLibrary{
    return [self
            cameraSupportsMedia:(__bridge NSString *)kUTTypeImage sourceType:UIImagePickerControllerSourceTypePhotoLibrary];
}

+ (BOOL)cameraSupportsMedia:(NSString *)paramMediaType sourceType:(UIImagePickerControllerSourceType)paramSourceType{
    __block BOOL result = NO;
    if ([paramMediaType length] == 0) {
        return NO;
    }
    NSArray *availableMediaTypes = [UIImagePickerController availableMediaTypesForSourceType:paramSourceType];
    [availableMediaTypes enumerateObjectsUsingBlock: ^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *mediaType = (NSString *)obj;
        if ([mediaType isEqualToString:paramMediaType]){
            result = YES;
            *stop= YES;
        }
    }];
    return result;
}

#pragma mark - time 

+ (IMTimeStamp)getNowTimeStamp
{
    NSDate *date = [NSDate date];
    
    IMTimeStamp seconds = [date timeIntervalSince1970];
    return seconds;
}

#pragma mark - path

+ (NSString *)getVideoCachePath:(NSString *)name
{
    return [NSString stringWithFormat:@"%@%@", [self getVideoCacheDir:YES], name];
}

+ (NSString *)getVideoCacheDir:(BOOL)create
{
    NSString *cacheDir = [NSString stringWithFormat:@"%@/Documents/cache/videos/", NSHomeDirectory()];
    if (create && ![[NSFileManager defaultManager] fileExistsAtPath: cacheDir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:cacheDir withIntermediateDirectories:YES attributes:nil error:nil];
        NSError *error = nil;
        NSURL* URL= [NSURL fileURLWithPath: cacheDir];
        BOOL success = [URL setResourceValue: [NSNumber numberWithBool: YES]
                                      forKey: NSURLIsExcludedFromBackupKey error: &error];
        if(!success){
            NSLog(@"Error excluding %@ from backup %@", [URL lastPathComponent], error);
        }
    }
    
    return cacheDir;
}

+ (NSString *)getDocumentCacheDir:(NSString *)dir
{
    NSString *cacheDir = [NSString stringWithFormat:@"%@/Documents/cache/%@", NSHomeDirectory(), dir];
    NSFileManager *fileManger = [NSFileManager defaultManager];
    if (![fileManger fileExistsAtPath:cacheDir])
    {
        [fileManger createDirectoryAtPath:cacheDir withIntermediateDirectories:YES attributes:nil error:nil];
        NSError *error = nil;
        NSURL* URL= [NSURL fileURLWithPath: cacheDir];
        BOOL success = [URL setResourceValue: [NSNumber numberWithBool: YES]
                                      forKey: NSURLIsExcludedFromBackupKey error: &error];
        if(!success){
            NSLog(@"Error excluding %@ from backup %@", [URL lastPathComponent], error);
        }
    }
    return cacheDir;
}

#pragma mark - storyboard

+ (id)embedController:(NSString *)identifier inStoryboard:(NSString *)name toContainerController:(UIViewController *)containerController withContainerView:(UIView *)containerView
{
    UIViewController *viewConroller = [self getViewController:identifier inStoryboard:name];
    [containerController addChildViewController:viewConroller];
    [viewConroller didMoveToParentViewController:containerController];
    [containerView addSubview:viewConroller.view];
    return viewConroller;
}

+ (id)getViewController:(NSString *)identifier inStoryboard:(NSString *)name
{
    UIStoryboard *storyBoard=[UIStoryboard storyboardWithName:name bundle:nil];
    return [storyBoard instantiateViewControllerWithIdentifier:identifier];
}

#pragma shotsImage

+ (UIImage *)getVideoScreenShotsImage:(NSString *)videoURL{
    
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:videoURL] options:nil];
    
    AVAssetImageGenerator *gen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    
    gen.appliesPreferredTrackTransform = YES;// 截图的时候调整到正确的方向
    
    CMTime time = CMTimeMakeWithSeconds(0.0, 60);// 0.0为截取视频0.0秒处的图片，60为每秒60帧
    
    NSError *error = nil;
    
    CMTime actualTime;
    
    CGImageRef image = [gen copyCGImageAtTime:time actualTime:&actualTime error:&error];
    
    UIImage *thumb = [[UIImage alloc] initWithCGImage:image];
    
    CGImageRelease(image);
    
    return thumb;
}

+ (UIAlertController *)alertViewMessage:(NSString *)msg disappearAfter:(NSTimeInterval)ti withViewController:(UIViewController *)vc
{
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:nil message:msg preferredStyle:UIAlertControllerStyleAlert];
    if (ti > 0) {
        [self performSelector:@selector(dimissAlert:) withObject:alertView afterDelay:ti];
    }
    else
    {
        UIAlertAction *defult = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
        [alertView addAction:defult];
    }
    
    [vc presentViewController:alertView animated:YES completion:nil];
    return alertView;
}

+ (void) dimissAlert:(UIAlertController *)alert {
    if(alert)     {
        [alert dismissViewControllerAnimated:YES completion:nil];
    }
}

@end
