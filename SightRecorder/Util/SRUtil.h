//
//  SRUtil.h
//  SightRecorder
//
//  Created by 黄 on 16/6/28.
//  Copyright © 2016年 黄. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef long long IMTimeStamp;

@interface SRUtil : NSObject

+ (BOOL)checkMediaVideoSupported;

+ (IMTimeStamp)getNowTimeStamp;

+ (NSString *)getVideoCachePath:(NSString *)name;

+ (NSString *)getDocumentCacheDir:(NSString *)dir;

+ (id)embedController:(NSString *)identifier inStoryboard:(NSString *)name toContainerController:(UIViewController *)containerController withContainerView:(UIView *)containerView;

+ (UIImage *)getVideoScreenShotsImage:(NSString *)videoURL;

+ (UIAlertController *)alertViewMessage:(NSString *)msg disappearAfter:(NSTimeInterval)ti withViewController:(UIViewController *)vc;

@end
