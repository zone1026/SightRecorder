//
//  ChatHistorySightCollectionViewCell.m
//  SightRecorder
//
//  Created by 黄 on 16/6/28.
//  Copyright © 2016年 黄. All rights reserved.
//

#import "ChatHistorySightCollectionViewCell.h"
#import "CALayer+SRUtil.h"
#import "IMPlaySightOperation.h"
#import "ChatDataProxy.h"

@interface ChatHistorySightCollectionViewCell ()
@property (weak, nonatomic) IBOutlet UIImageView *imgAddSight;
@property (weak, nonatomic) IBOutlet UILabel *lblTips;

@property (weak, nonatomic) IBOutlet UIView *viewSight;
@property (weak, nonatomic) IBOutlet UIImageView *imgSight;

@property (nonatomic, retain) IMPlaySightOperation *sightOperation;

@property (nonatomic, retain) NSString *filePath;

@property (nonatomic) CGSize sightSize;

@end

@implementation ChatHistorySightCollectionViewCell

- (void)awakeFromNib
{
    [self.viewSight.layer setBorder:0 withColor:[UIColor clearColor] withCorner:COMMON_UI_ROUND_CORNER_BIG_RADIUS];
    [self.imgSight.layer setBorder:0 withColor:[UIColor clearColor] withCorner:COMMON_UI_ROUND_CORNER_BIG_RADIUS];
    self.lblTips.hidden = YES;
}

- (void)prepareForReuse
{
    _selectedSight = NO;
    if (self.sightOperation) {
        [self.sightOperation releaseVideoPlayer];
        self.sightOperation = nil;
    }
    
    [self.viewSight.layer setBorder:0 withColor:[UIColor clearColor] withCorner:COMMON_UI_ROUND_CORNER_BIG_RADIUS];
    self.lblTips.hidden = YES;
}

- (void)updateSightPath:(NSString *)path withSize:(CGSize)size
{
    _filePath = path;
    _sightSize = size;
    self.imgAddSight.hidden = NO;
    self.imgSight.hidden = YES;
    if ([self checkFileExistsAtPath:path]) {
        
        self.imgAddSight.hidden = YES;
        self.imgSight.hidden = NO;
        self.imgSight.image = [[ChatDataProxy sharedProxy] getSightScreenShotsImage:path];
    }
}

- (BOOL)checkFileExistsAtPath:(NSString *)fileURL
{
    if (nil == fileURL || [fileURL isEqualToString:@"gotoRecordSight"]) {
        return NO;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL exist = [fileManager fileExistsAtPath:fileURL];
    return exist;
}

- (void)selectedSight:(BOOL)selected
{
    _selectedSight = selected;
    
    if (selected) {
        [self.viewSight.layer setBorder:2 withColor:[UIColor whiteColor] withCorner:COMMON_UI_ROUND_CORNER_BIG_RADIUS];
        [self playSelectedSight];
        self.lblTips.hidden = NO;
    }
    else
    {
        [self.viewSight.layer setBorder:0 withColor:[UIColor clearColor] withCorner:COMMON_UI_ROUND_CORNER_BIG_RADIUS];
        if (self.sightOperation) {
            [self.sightOperation pauseSight];
            [self.sightOperation releaseVideoPlayer];
        }
        self.sightOperation = nil;
        self.viewSight.hidden = YES;
        self.imgSight.hidden = NO;
        self.lblTips.hidden = YES;
    }
}

- (void)playSelectedSight
{
    self.viewSight.hidden = NO;
    if (nil == self.sightOperation) {
        self.sightOperation = [[IMPlaySightOperation alloc] initVideoFileURL:[NSURL fileURLWithPath:_filePath] withFrame:CGRectMake(1, 1, _sightSize.width - 2, _sightSize.height - 2) withView:self.viewSight];
    }
    [self.sightOperation playSight];
    self.imgSight.hidden = YES;
}

@end
