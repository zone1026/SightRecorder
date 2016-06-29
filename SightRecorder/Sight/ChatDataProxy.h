//
//  ChatDataProxy.h
//  SightRecorder
//
//  Created by 黄 on 16/6/29.
//  Copyright © 2016年 黄. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define NOTI_CHAT_VIDEO_RECORD_FINSH @"noti_chat_video_record_finsh"
#define KEY_CHAT_VIDEO_RECORD_VIDEOPATH @"videoPath"
#define KEY_CHAT_VIDEO_RECORD_STIME @"stime"

#define SIGHT_OVERDUE_TIME_DAY 14

@interface ChatDataProxy : NSObject

+ (ChatDataProxy*)sharedProxy;

/**
 * 获取视频的截图
 */
- (UIImage *)getSightScreenShotsImage:(NSString *)filePath;

/**
 * 获取前14天的小视频文件
 */
- (NSMutableArray *)getHistorySightData;
/**
 * 新录制的一段小视频
 */
- (void)addNewHistorySight:(NSString *)filePath;

@end
