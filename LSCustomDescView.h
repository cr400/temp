//
//  LSCustomDescView.h
//  LiveShow
//
//  Created by admin on 16/12/22.
//  Copyright © 2016年 admin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LSCustomDescView : UIView
@property (nonatomic, strong, readonly) YYLabel     *descLab;
@property (nonatomic, strong, readonly) UIButton      *lookAllBtn;/**<查看全部 收起*/

@property (nonatomic, assign) CGFloat   marginX;
@property (nonatomic, assign) CGFloat   marginBottom;

@property (nonatomic, copy) void(^lookAllCallback)(BOOL externFlag);/**<查看全部*/
- (void)updateWithDesc:(NSString *)desc minLine:(NSInteger)minLine extern:(BOOL)externFlag;
@end
