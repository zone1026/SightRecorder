//
//  ChatDataProxy.m
//  SightRecorder
//
//  Created by 黄 on 16/6/29.
//  Copyright © 2016年 黄. All rights reserved.
//

#import "ChatDataProxy.h"
#import "SRUtil.h"

#define INTERVAL_ONE_DAY (24*60*60)

@interface ChatDataProxy ()

@property (nonatomic, retain) NSMutableDictionary *dictHistorySightImage;
@property (nonatomic, retain) NSMutableArray *historySightArr;

@end

@implementation ChatDataProxy

static ChatDataProxy *chatDataProxy = nil;

+ (ChatDataProxy *)sharedProxy
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        chatDataProxy = [[self alloc] init];
    });
    return chatDataProxy;
}

- (UIImage *)getSightScreenShotsImage:(NSString *)filePath
{
    if (nil == self.dictHistorySightImage) {
        self.dictHistorySightImage = [NSMutableDictionary dictionary];
    }
    
    NSString *key = filePath.lastPathComponent;
    UIImage *sightImg = [self.dictHistorySightImage objectForKey:key];
    if (nil == sightImg) {
        sightImg = [SRUtil getVideoScreenShotsImage:filePath];
        [self.dictHistorySightImage setObject:sightImg forKey:key];
    }
    
    return sightImg;
}

- (NSMutableArray *)getHistorySightData
{
    if (nil == _historySightArr) {
        _historySightArr = [NSMutableArray array];
    }
    
    if (0 == self.historySightArr.count) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *path = [SRUtil getDocumentCacheDir:@"videoHistory/"];
        NSArray *fileArr = [fileManager contentsOfDirectoryAtPath:path error:nil];
        if (fileArr) {
            IMTimeStamp nowTime = [SRUtil getNowTimeStamp];
            for (NSInteger i = 0; i < fileArr.count; i++) {
                NSString *fileName = [fileArr objectAtIndex:i];
                if (fileName && [[fileName pathExtension] isEqualToString:@"mp4"]) {
                    NSArray *tempArr = [fileName componentsSeparatedByString:@"."];
                    long long recodTime = [[tempArr firstObject] longLongValue];
                    long long interval = nowTime - recodTime;
                    long long overdueTime = SIGHT_OVERDUE_TIME_DAY * INTERVAL_ONE_DAY;//过期时间
                    if (interval <=  overdueTime) {
                        fileName = [path stringByAppendingString:fileName];
                        
                        [self.historySightArr insertObject:fileName atIndex:0];
                    }
                }
            }
        }
        
        [self.historySightArr addObject:@"gotoRecordSight"];
    }
    
    return _historySightArr;
}

- (void)addNewHistorySight:(NSString *)filePath
{
    filePath = [filePath stringByReplacingOccurrencesOfString:@"file://" withString:@""];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSString *sightHistoryPath = [[SRUtil getDocumentCacheDir:@"videoHistory/"] stringByAppendingString:filePath.lastPathComponent];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:filePath])
        {
            [[NSFileManager defaultManager] createDirectoryAtPath:[SRUtil getDocumentCacheDir:@"videoHistory/"]withIntermediateDirectories:YES attributes:nil error:nil];
        }
        
        NSError *error = nil;
        [[NSFileManager defaultManager] copyItemAtPath:filePath toPath:sightHistoryPath error:&error];
        if (error) {
            NSLog(@"error is : %@",error);
        }
        else
        {
            if (nil == _historySightArr)
            {
                _historySightArr = [NSMutableArray array];
            }
            
            [_historySightArr insertObject:sightHistoryPath atIndex:0];
        }
    });
}

@end
