//
//  TbRunloopTool.h
//  RunLoopTable
//
//  Created by Tb on 2015/8/21.
//  Copyright © 2015年 Tb. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef BOOL(^TbRunLoopUnit)(void);

@interface TbRunloopTool : NSObject

@property (nonatomic, assign) NSUInteger maximumQueueLength;

+ (instancetype)sharedRunLoopWorkDistribution;

- (void)addTask:(TbRunLoopUnit)unit withKey:(id)key;

- (void)removeAllTasks;

@end

@interface UITableViewCell (TbRunloopTool)

@property (nonatomic, strong) NSIndexPath *currentIndexPath;

@end
