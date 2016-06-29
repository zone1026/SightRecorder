//
//  ChatHistorySightCollectionViewCell.h
//  SightRecorder
//
//  Created by 黄 on 16/6/28.
//  Copyright © 2016年 黄. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ChatHistorySightCollectionViewCell : UICollectionViewCell

@property (nonatomic) BOOL selectedSight;

- (void)updateSightPath:(NSString *)path withSize:(CGSize)size;

- (void)selectedSight:(BOOL)selected;

@end
