//
//  LSMasterViewController.h
//  LiveShow
//
//  Created by admin on 16/8/6.
//  Copyright © 2016年 admin. All rights reserved.
//

#import "BaseViewController.h"
#import "LSMasterVCProtocol.h"

@interface LSMasterViewController : BaseViewController<LSMasterVCProtocol>
@property (nonatomic, assign) NSInteger         userID;
@property (nonatomic, assign) BOOL              master;

@end
