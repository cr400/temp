//
//  LSMasterViewController.m
//  LiveShow
//
//  Created by admin on 16/8/6.
//  Copyright © 2016年 admin. All rights reserved.
//

/**
 *      ******用户主页*****
 */

#import "LSMasterViewController.h"
#import "NFBrowseImageViewController.h"
#import "LSBaseArticleTableViewCell.h"
#import "LSUserHomeModel.h"
#import "LSFilmArticleServices.h"
#import "LSPersonPageVM.h"
#import "ImproveInfoViewController.h"
#import "LSUserCenterServices.h"
#import "LSPersonInfoView.h"
#import "UIButton+LSFillColor.h"
#import "LSUserTimeAsixModel.h"
#import "LSArticleModel.h"
#import "LSFilmListDetailModel.h"
#import "NFUserFeedVideoPlayListController.h"
#import "LSFollowedViewCtr.h"
#import "NFFollowBaseView.h"
#import "LSNumberConverterTool.h"
#import "LSFullViewController.h"
#import "LSCahceImage.h"
#import "NFUserFeedShortCommentController.h"
#import "NFUserFeedShortVideoController.h"
#import "NFUserFeedArticleController.h"
#import "NFUserFeedFilmListController.h"
#import "NFUserLikeCountController.h"
#import "LSNumberConverterTool.h"
#import "NFFansViewCtr.h"
#import "NFSwipeTableView.h"
#import "NFSliderBarView.h"
#import "NFMasterVideoTableView.h"
#import "NFMasterVideoPlayListTableView.h"
#import "NFMasterLikeTableView.h"
#import "NFHomeTableView.h"
#import "NFUserFeedVideoPlayListVideoModel.h"
#import "NFUserFeedVideosViewModel.h"
#import "NFUserFeedLikeViewModel.h"
#import "LSNumberConverterTool.h"
#import "NFStatisticRouterGroupConfig.h"
@interface LSMasterViewController ()<UIGestureRecognizerDelegate, QMUIImagePreviewViewDelegate,SwipeTableViewDelegate,SwipeTableViewDataSource,LSMasterVCProtocol>

@property (nonatomic, strong) LSPersonInfoView                  *headerView;

@property (nonatomic, strong) SwipeTableView                  *tableView;

@property (nonatomic, assign) NSInteger                         pageSize;
@property (nonatomic, assign) NSInteger                         pageNo;

@property (nonatomic, strong) LSPersonPageVM                    *viewModel;

@property (nonatomic, assign) CGFloat                           offsetY;/**<当前的偏移 */

@property (nonatomic, assign) BOOL                              followHeFlag;

@property (nonatomic, assign) BOOL                              disappearFlag;/**<手势侧滑的问题*/
@property (nonatomic, assign) BOOL                              didAppearFlag;/**<手势侧滑的问题*/

@property (nonatomic, strong) NFSliderBarView                   *sliderBarView;

@property(nonatomic, strong) QMUIImagePreviewViewController *imagePreviewViewController;

@property (nonatomic, copy) NSArray                              *tablesArray;

@property (nonatomic, assign) BOOL                              isScrolling;

@property (nonatomic, strong)  NFMasterVideoTableView       *tableView1;
@property (nonatomic, strong)  NFMasterVideoPlayListTableView *tableView2;

@property (nonatomic, assign) BOOL autoScroll;

@property (nonatomic, strong)  NFStatisticRouterGroupConfig *grouprouterConfig;

@property (nonatomic, assign) NSInteger                     currentIndex;

@end

@implementation LSMasterViewController
- (NFStatisticRouterGroupConfig *)grouprouterConfig{
    
    if (_grouprouterConfig) {
        return _grouprouterConfig;
    }
    
    NSArray *ids = [NSArray arrayWithObjects:
                    @"D1",
                    @"D2",
                    @"D3",
                    nil];
    _grouprouterConfig = [NFStatisticRouterGroupConfig initWithPageIDs:ids];
    return _grouprouterConfig;
}

-(LSPersonPageVM *)viewModel{
    if (!_viewModel) {
        _viewModel = [[LSPersonPageVM alloc] init];
        _viewModel.dataModel = [[LSUserHomeModel alloc] init];
    }
    return _viewModel;
}

- (SwipeTableView *)tableView{
    if (_tableView) {
        return _tableView;
    }
    _tableView = [[SwipeTableView alloc] initWithFrame:CGRectMake(0, NavigationContentTop, kScreenWidth, kScreenHeight-NavigationContentTop)];
    _tableView.backgroundColor = [UIColor whiteColor];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    return _tableView;
}

- (NSArray *)currentSliderBarItems{
 
    
    return  [NSArray arrayWithObjects:
             [NSString stringWithFormat:@"视频 %@",[LSNumberConverterTool operateNumberToStringAll:@(self.viewModel.wemedia_cnt)]],
             [NSString stringWithFormat:@"播单 %@",[LSNumberConverterTool operateNumberToStringAll:@(self.viewModel.play_list_cnt)]],
             [NSString stringWithFormat:@"喜欢 %@",[LSNumberConverterTool operateNumberToStringAll:@(self.viewModel.like_cnt)]],
             nil];
}

- (NFSliderBarView *)sliderBarView {
    if (_sliderBarView) {
        return _sliderBarView;
    }
    _sliderBarView = [[NFSliderBarView alloc]initWithItems:[self currentSliderBarItems]];
    _sliderBarView.size = CGSizeMake(kScreenWidth, 52);
    _sliderBarView.backgroundColor = UIColorWhite;
    _sliderBarView.selectedSegmentIndex = self.tableView.currentItemIndex;
    [_sliderBarView addTarget:self action:@selector(changeSwipeViewIndex:) forControlEvents:UIControlEventValueChanged];
    @weakify(self);
    _sliderBarView.indexWillChangeBlock = ^BOOL(NSInteger toIndex) {
        @strongify(self);
        LSLog(@"isScrollingInAnimation=%d",self.isScrolling);
        if (self.tableView.contentView.isTracking ||
            self.isScrolling) {
            return NO;
        }
        return YES;
    };
    return _sliderBarView;
}

- (LSPersonInfoView *)headerView{
    
    if (_headerView) {
        return _headerView;
    }
    _headerView = [[LSPersonInfoView alloc] init];
    return _headerView;
}

- (void)viewWillAppear:(BOOL)animated{

    [super viewWillAppear:animated];
    self.disappearFlag = NO;
    [self updateAlpha];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    self.didAppearFlag = YES;

    [self getOtherInfoCanIgnore:NO];
    [self pageviewStartWithName:@"个人主页"];
    
    [self.grouprouterConfig configAppearWithIndex:self.currentIndex];

    [self scrollNormal];
}

- (void)getOtherInfoCanIgnore:(BOOL)canIgnore{
 
    @weakify(self);
    
    LSBaseTableView *currentTableView = (LSBaseTableView *)self.tableView.currentItemView;
    LSLog(@"isRefresh:%d",currentTableView.isHeaderRefreshing);
    if ([currentTableView isKindOfClass:[LSBaseTableView class]] && canIgnore) {
        if (currentTableView.isHeaderRefreshing) {
            [[self.viewModel getOthersInfoCommand] execute:@(self.userID)];
        }
    }else{
        [[self.viewModel getOthersInfoCommand] execute:@(self.userID)];
    }
    
    [[self.viewModel getFansFollowCommand:1 follow:1 userID:self.userID byLikeCount:1] execute:nil];
    if (!self.master) {
        @strongify(self);
        //判断是否可以关注
        NSString *token = ((AppDelegate *)[[UIApplication sharedApplication] delegate]).token;
        if (token) {
            [[self.viewModel checkFollowStatusCommand] execute:@(self.userID)];
        }
    }
    [[self.viewModel userOriginCountSignalWithUserID:self.userID] subscribeNext:^(id x) {
        @strongify(self);
        [self.sliderBarView updateTitles:[self currentSliderBarItems]];
        if (self.tableView.currentItemIndex == 0 && self.viewModel.wemedia_cnt == 0  && !self.autoScroll) {
            [self.tableView scrollToItemAtIndex:2 animated:NO];
            [self.sliderBarView updateWithContentOffsetX:self.tableView.contentView.contentOffset.x];
        }
        self.autoScroll = YES;
    }];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: DECLARE_COLOR(68, 74, 89, 1), NSFontAttributeName: DECLARE_MediumFont(17)};
    
    [self setNavigationBarTintStyleWithClear:NO];
    
    self.disappearFlag = YES;
    [self pageviewEndWithName:@"个人主页"];
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    self.didAppearFlag = NO;
    
    [self.grouprouterConfig groupDisappear];
}

-(void)dealloc{
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)updateRightItem{
    
    //判断是否是主人模式
    if (LSAPPDELEGATE.userID.integerValue == self.userID) {
        self.master = YES;
        [self addNavigtionRightItemWithTitle:@"编辑" selector:@selector(rightHandle)];
    }
    else{
        
        @weakify(self);
        self.master = NO;
        
        NFFollowBaseView  *textImageView = [[NFFollowBaseView alloc] init];
        textImageView.state = self.followHeFlag;
        CGSize size = [textImageView sizeThatFits:CGSizeMake(0, 0)];
        textImageView.frame =CGRectMake(0, 0, size.width, size.height);
        textImageView.clickBlock = ^{
            @strongify(self);
            [self rightHandle];
        };
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:textImageView];
    }
}



- (void)configSwipeController{

    NFMasterVideoTableView *tableView = [NFMasterVideoTableView groupTableWithRefreshType:LSBaseTableRefreshTypeAutoNormalFooter frame:self.tableView.bounds];
    tableView.backgroundColor = [UIColor whiteColor];
    NFUserFeedVideosViewModel *viewModel = [[NFUserFeedVideosViewModel alloc] init];
    viewModel.user_id = self.userID;
    
    NFMasterVideoPlayListTableView *tableView2 = [NFMasterVideoPlayListTableView groupTableWithRefreshType:LSBaseTableRefreshTypeAutoNormalFooter frame:self.tableView.bounds];
    tableView2.backgroundColor = [UIColor whiteColor];
    NFUserFeedVideoPlayListVideoModel *viewModel2 = [[NFUserFeedVideoPlayListVideoModel alloc] init];
    viewModel2.user_id = self.userID;
    
    NFMasterLikeTableView *tableView3 = [NFMasterLikeTableView groupTableWithRefreshType:LSBaseTableRefreshTypeAutoNormalFooter frame:self.tableView.bounds];
    tableView3.backgroundColor = [UIColor whiteColor];
    NFUserFeedLikeViewModel *viewModel3 = [[NFUserFeedLikeViewModel alloc] init];
    viewModel3.user_id = self.userID;
    
    [tableView bindViewModel:viewModel];
    [tableView2 bindViewModel:viewModel2];
    [tableView3 bindViewModel:viewModel3];
    
    self.tableView1 = tableView;
    self.tableView2 = tableView2;
    
    LSLog(@"[viewModel:%p],[viewModel2:%p],[viewModel3:%p]",viewModel,viewModel2,viewModel3);
    LSLog(@"[tableView:%p],[tableView2:%p],[tableView3:%p]",tableView,tableView2,tableView3);


    self.tablesArray  =  @[tableView,tableView2,tableView3];
    self.tableView.swipeHeaderBar = self.sliderBarView;
    [self.view addSubview:self.tableView];
    
    //回调
    @weakify(self);
    tableView.toVideoDetail = ^(LSWeMediaModel *model) {
        @strongify(self);
        [self  toWeMediaController:model];
    };
    tableView2.toPlayListDetail = ^(NFVideoPlayListModel *model) {
        @strongify(self);
        [self toPlayListController:model];
    };
    tableView3.toVideoDetail = ^(LSWeMediaModel *model) {
        @strongify(self);
        [self  toWeMediaController:model];
    };
    tableView3.toPlayListDetail = ^(NFVideoPlayListModel *model) {
        @strongify(self);
        [self toPlayListController:model];
    };
    viewModel.headerRefreshBeforeBlock = ^{
        @strongify(self);
        [self getOtherInfoCanIgnore:YES];
    };
    viewModel2.headerRefreshBeforeBlock = ^{
        @strongify(self);
        [self getOtherInfoCanIgnore:YES];
    };
    viewModel3.headerRefreshBeforeBlock = ^{
        @strongify(self);
        [self getOtherInfoCanIgnore:YES];
    };
    
    [RACObserve(tableView, contentOffset) subscribeNext:^(id x) {
        @strongify(self);
        [self updateAlpha];
    }];
    
    [RACObserve(tableView2, contentOffset) subscribeNext:^(id x) {
        @strongify(self);
        [self updateAlpha];
    }];
    
    [RACObserve(tableView3, contentOffset) subscribeNext:^(id x) {
        @strongify(self);
        [self updateAlpha];
    }];
    
    [RACObserve(self.sliderBarView,  selectedSegmentIndex)
     subscribeNext:^(id x) {
        @strongify(self);
        if (self.currentIndex == self.sliderBarView.selectedSegmentIndex) {
            return ;
        }
         self.currentIndex = self.sliderBarView.selectedSegmentIndex;
         [self reportPageClick];
    }];
}

- (void)configParamars{

    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
        self.edgesForExtendedLayout = UIRectEdgeAll;
    }
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.extendedLayoutIncludesOpaqueBars = YES;
    
    [self hairLine:YES];
    
    self.viewModel.userID = self.userID;
    self.viewModel.vcDelegate = self;
    [self bindViewModel:self.viewModel];
}

- (void)setupCallBack{

    @weakify(self);
   self.headerView.backgroundColor = [UIColor whiteColor];
    //隐藏一些控件
    //如果有新的粉丝 小红点
    if (self.master) {
        [[RACObserve(self.viewModel, dataModel.updateFans) ignore:nil] subscribeNext:^(NSNumber *followCount) {
            @strongify(self);
            self.headerView.fansRedDotNum = followCount;
        }];
    }

    [[RACObserve(self.viewModel, fans) ignore:nil] subscribeNext:^(NSNumber *fans) {
        @strongify(self);

        NSLog(@"cell 粉丝------> fans %@", fans);
        self.headerView.fansNum = fans;
    }];

    [[RACObserve(self.viewModel, follow) ignore:nil] subscribeNext:^(NSNumber *followed) {
        @strongify(self);
        self.headerView.focusNum = followed;
    }];
    
    [[RACObserve(self.viewModel, byLikeCount) ignore:nil] subscribeNext:^(NSNumber *likeNum) {
        @strongify(self);
        self.headerView.likeNum = likeNum;
    }];

    [[RACObserve(self.viewModel.dataModel, userInfo) ignore:nil] subscribeNext:^(LSBaseUserInfoModel *model) {
        @strongify(self);
        self.tableView1.userInfo = model;
        self.tableView2.userInfo = model;
        if (self.tableView.currentItemIndex == 0) {
            [self.tableView1 reloadData];
        }else if (self.tableView.currentItemIndex == 1){
            [self.tableView2 reloadData];
        }
        
        
        [self.headerView updateModel:model];
        [self updateHeader];

        //设置标题
        [self setNavigationItem:model.username];

        [self updateAlpha];
    }];


    self.headerView.fansBlock = ^{
        @strongify(self);
        [LSMobClick logEventName:nil withID:NFStatisticsPersonPageFans extra:nil];
        [self fansHandleWithFans:YES];
    };

    self.headerView.focusBlock = ^{
        @strongify(self);
        [LSMobClick logEventName:nil withID:NFStatisticsPersonPagefocus extra:nil];
        [self fansHandleWithFans:NO];
    };
    
    self.headerView.likeBlock = ^{
        @strongify(self);
        [LSMobClick logEventName:nil withID:NFStatisticsPersonPageGetLike extra:nil];
        [NFUserLikeCountController showWithLikeCount:self.headerView.likeNum.integerValue userID:self.userID];
    };
    
    //文章
    self.headerView.filmCommentBlock = ^{
        @strongify(self);
        NFUserFeedArticleController *controlelr = [[NFUserFeedArticleController alloc] init];
        controlelr.personViewModel = self.viewModel;
        controlelr.userID = self.userID;
        controlelr.nickname = self.viewModel.dataModel.userInfo.username;
        controlelr.type = LSResourceTypeArticle;
        controlelr.userInfo = self.viewModel.dataModel.userInfo;
        [self.navigationController pushViewController:controlelr animated:YES];
        
    };
    
    //片单
    self.headerView.filmlistBlock = ^{
        @strongify(self);
        NFUserFeedFilmListController *controlelr = [[NFUserFeedFilmListController alloc] init];
        controlelr.type = LSResourceTypeFilmList;
        controlelr.personViewModel = self.viewModel;
        controlelr.userID = self.userID;
        controlelr.userInfo = self.viewModel.dataModel.userInfo;
        controlelr.nickname = self.viewModel.dataModel.userInfo.username;
        [self.navigationController pushViewController:controlelr animated:YES];
    };
    
    //短视频
    self.headerView.shortVideoBlock = ^{
        @strongify(self);
        NFUserFeedShortVideoController *controlelr = [[NFUserFeedShortVideoController alloc] init];
        controlelr.personViewModel = self.viewModel;
        controlelr.type = LSResourceTypeVideo;
        controlelr.userID = self.userID;
        controlelr.userInfo = self.viewModel.dataModel.userInfo;
        controlelr.nickname = self.viewModel.dataModel.userInfo.username;
        [self.navigationController pushViewController:controlelr animated:YES];
    };
    
    //短评
    self.headerView.shortCommentBlock = ^{
        @strongify(self);
        NFUserFeedShortCommentController *controlelr = [[NFUserFeedShortCommentController alloc] init];
        controlelr.personViewModel = self.viewModel;
        controlelr.userID = self.userID;
        controlelr.type = LSResourceTypeShortComment;
        controlelr.userInfo = self.viewModel.dataModel.userInfo;
        controlelr.nickname = self.viewModel.dataModel.userInfo.username;
        [self.navigationController pushViewController:controlelr animated:YES];
    };
    
    self.headerView.videoPlayListsCommentBlock = ^{
        @strongify(self);
        NFUserFeedVideoPlayListController *controlelr = [[NFUserFeedVideoPlayListController alloc] init];
        controlelr.userID = self.userID;
        [self.navigationController pushViewController:controlelr animated:YES];
    };
    
    self.headerView.iconImageBlock = ^{
        @strongify(self);
        [self.imagePreviewViewController startPreviewFading];
    };
    
    [self updateHeader];
}

- (void)updateHeader{
    LSLog(@"updateHeader");

    CGSize headerSize = [self.headerView sizeThatFits:CGSizeZero];
    if (headerSize.height != self.headerView.height) {
        
        self.headerView.frame = CGRectMake(0, 0, kScreenWidth, headerSize.height);
        UIView *headerView = [[UIView alloc] initWithFrame:self.headerView.bounds];
        [headerView addSubview:self.headerView];
        self.tableView.swipeHeaderView = headerView;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.autoScroll  = NO;
    self.currentIndex = 0;
    // Do any additional setup after loading the view.
    [LSMobClick logEventName:nil withID:NFStatisticsClickPersonalMyWorksVideoClickKey extra:nil];
    
    //url传递过来的参数
    if (self.params && [self.params isKindOfClass:[NSDictionary class]]) {
        NSNumber *userID = self.params[@"user_id"];
        if ([userID isKindOfClass:[NSNumber class]]) {
            self.userID = userID.integerValue;
        }
        else if ([userID isKindOfClass:[NSString class]]){
            NSString *temp = (NSString *)userID;
            self.userID = temp.integerValue;
        }
        if (LSAPPDELEGATE.userID.integerValue == self.userID) {
            self.master = YES;
        }
        else{
            self.master = NO;
        }
    }
    
    [self configParamars];
    [self configSwipeController];
    [self setupCallBack];
    [self updateRightItem];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark---查看短评图片
#pragma mark----查看图片
- (void)browseImageWithIndex:(NSInteger)index withImageArray:(NSArray *)imageArray
{
//    NFBrowseImageViewController *VC = [[NFBrowseImageViewController alloc] init];
//    VC.scrollIndex = index;
//    VC.imageArray = imageArray;
//    VC.routerConfig.entranceID = @"B1_1";
//    [self.navigationController pushViewController:VC animated:YES];
    
    QMUIModalPresentationViewController *modalController = [[QMUIModalPresentationViewController alloc]init];
    modalController.contentViewMargins = UIEdgeInsetsMake(0, 0, 0, 0 );
    modalController.dimmingView.backgroundColor = UIColorClear;
    modalController.maximumContentViewWidth = DEVICE_WIDTH;
    @weakify(self);
    modalController.layoutBlock = ^(CGRect containerBounds, CGFloat keyboardHeight, CGRect contentViewDefaultFrame) {
        @strongify(self);
        keyboardHeight = 0;
        
    };
    modalController.modal = YES;
    NFBrowseImageViewController *detailController = [[NFBrowseImageViewController alloc] init];
    detailController.scrollIndex = index;
    detailController.imageArray = imageArray;
    detailController.routerConfig.entranceID = @"B1_1";
    modalController.contentViewController = detailController;
    [modalController showWithAnimated:YES completion:nil];
    
    
    detailController.disMissBlock = ^{
        @strongify(self);
        [modalController hideWithAnimated:YES completion:nil];
    };
    
}


#pragma mark - SaveImage
    /// 保存图片
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo{
    NSLog(@"image = %@, error = %zd, contextInfo = %@", image, [error code], contextInfo);
    NSString *str = @"";
    if (error)
    {
        if (error.code == -3310){str = @"相册访问权限未开启,请到系统设置开启";}
        else{str = @"图片保存失败";}
    }
    else{str = @"成功保存到相册";}
    
    [LSAlertTool showAlert:str time:1 toView:self.imagePreviewViewController.view];
    
}

#pragma mark - <QMUIImagePreviewViewDelegate>

-(void)longPressInZoomingImageView:(QMUIZoomImageView *)zoomImageView{
    
    UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, DEVICE_WIDTH - 64, 48)];
    contentView.backgroundColor = UIColorWhite;
    QMUIButton *button = [[QMUIButton alloc]initWithFrame:contentView.bounds];
    [button setTitle:@"保存到手机" forState:UIControlStateNormal];
    [button setTitleColor:UIColorHex(#333333) forState:UIControlStateNormal];
    button.titleLabel.font = UIFontMake(16);
    button.titleLabel.textAlignment = NSTextAlignmentCenter;
    
    [contentView addSubview:button];
    
    QMUIModalPresentationViewController *modalViewController = [[QMUIModalPresentationViewController alloc] init];
    modalViewController.contentView = contentView;
    [modalViewController showWithAnimated:YES completion:nil];
    
    @weakify(self);
    [[button rac_signalForControlEvents:UIControlEventTouchUpInside]subscribeNext:^(id x) {
        @strongify(self);
        [modalViewController hideWithAnimated:YES completion:^(BOOL finished) {
            if (finished) {
                UIImage *image = [LSCahceImage getCacheImage:self.viewModel.dataModel.userInfo.avatar];
                UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), (__bridge void *)self);
            }
        }];
    }];
    
}

- (void)singleTouchInZoomingImageView:(QMUIZoomImageView *)zoomImageView location:(CGPoint)location {
        //    self.headImageView.image = zoomImageView.image;
        //    [self.imagePreviewViewController endPreviewToRectInScreen:[self.headImageView convertRect:self.headImageView.bounds toView:nil]];
    [self.imagePreviewViewController endPreviewFading];
    
}

- (NSUInteger)numberOfImagesInImagePreviewView:(QMUIImagePreviewView *)imagePreviewView {
    return 1;
}

- (void)imagePreviewView:(QMUIImagePreviewView *)imagePreviewView renderZoomImageView:(QMUIZoomImageView *)zoomImageView atIndex:(NSUInteger)index {
    [[NSOperationQueue mainQueue]addOperationWithBlock:^{
        [zoomImageView showLoading];
        
    }];
    
    @weakify(self);
    [[YYWebImageManager sharedManager]requestImageWithURL:self.viewModel.dataModel.userInfo.avatar.mj_url options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        
    } transform:^UIImage * _Nullable(UIImage * _Nonnull image, NSURL * _Nonnull url) {
        return image;
        
    } completion:^(UIImage * _Nullable image, NSURL * _Nonnull url, YYWebImageFromType from, YYWebImageStage stage, NSError * _Nullable error) {
        @strongify(self);
        if (image) {
                /// 主线程隐藏加载条, 填充图片
            [[NSOperationQueue mainQueue]addOperationWithBlock:^{
                [zoomImageView hideEmptyView];
                zoomImageView.image = image;
                
            }];
        }
    }];
}

#pragma mark -粉丝 关注
- (void)fansHandleWithFans:(BOOL)fans{
    if (!fans) {
        LSFollowedViewCtr *followedVC = [[LSFollowedViewCtr alloc] init];
        [followedVC setNavigationItem:@"关注"];
        followedVC.fans = fans;
        followedVC.userID = self.userID;
        followedVC.routerConfig.entranceID = @"DA_1";
        [self.navigationController pushViewController:followedVC animated:YES];
    }else{
        NFFansViewCtr *fansController = [[NFFansViewCtr alloc] init];
        [fansController setNavigationItem:@"粉丝"];
        fansController.fans = fans;
        fansController.userID = self.userID;
        fansController.routerConfig.entranceID = @"DA2";
        [self.navigationController pushViewController:fansController animated:YES];
    }
}

- (void)addFollowHandle{
    //这里得判断是否已经关注了
    //判断是否登录了 未登录跳登录
    NSString *token = [LSAPPDELEGATE token];
    if (!token) {
        //跳登录界面
        [self toLogin];
    }
    else{
        RACCommand *tokenCommand = [LSUserCenterServices tokenCheckCommand];
        @weakify(self);
        [tokenCommand.executionSignals.switchToLatest subscribeNext:^(NSDictionary *json) {
            @strongify(self);
            
            if (self.viewModel.followHe && self.followHeFlag) {
                self.followHeFlag = NO;
                [[self.viewModel unfollowWithUserID:self.userID] execute:nil];
            }
            else if (!self.viewModel.followHe && !self.followHeFlag){
                self.followHeFlag = YES;
                
                [[self.viewModel followWithUserID:self.userID] execute:nil];
            }
        }];
        
        [[tokenCommand errors] subscribeNext:^(NSError *error) {
            if ([error.domain isEqualToString:@"ERR_TOKEN_INVALID"] ||
                [error.domain isEqualToString:LSHttpResponseErrorTokenExpiredKey]) {
                //跳登录界面
                [self toLogin];
            }
        }];
        
        [tokenCommand execute:nil];
    }
}

#pragma mark 绑定viewmodel
- (void)bindViewModel:(LSPersonPageVM *)viewModel{
    @weakify(self);
    [RACObserve(viewModel, followHe) subscribeNext:^(NSNumber *followHe) {
        @strongify(self);
        [self updateFollowStatus:[followHe boolValue]];
    }];
}

- (void)updateFollowStatus:(BOOL)followHe{
    if (self.master) {
        return;
    }
    self.followHeFlag = followHe;
    [self updateRightItem];
}

-(void)updateUserInfoHandle{

}

- (void)rightHandle{
    if (!self.didAppearFlag) {
        return;
    }
    
    if (self.master) {
        [self editHandle];
    }
    else{
        [self addFollowHandle];
    }
}

- (void)editHandle{
    [LSMobClick logEventName:nil withID:NFStatisticsPersonPageEdite extra:nil];
    
    ImproveInfoViewController *improveInfoVC = [[ImproveInfoViewController alloc] init];
    improveInfoVC.fromRegister = NO;
    improveInfoVC.userInfo = self.viewModel.dataModel.userInfo;
    
    UIImage *img = [UIImage imageWithColor:[UIColor colorWithWhite:1 alpha:1]];
    [self.navigationController.navigationBar setBackgroundImage:img forBarMetrics:UIBarMetricsDefault];
    
    [self.navigationController pushViewController:improveInfoVC animated:YES];
}

#pragma mark -uiscrollviewdelegate
-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    [self updateAlpha];
}

- (void)updateAlpha{
    if (self.disappearFlag || ![self.tableView.currentItemView isKindOfClass:[UITableView class]]) {
        return;
    }
    
    UITableView *currentTableView = (UITableView *)self.tableView.currentItemView;
    
    CGFloat alpha = currentTableView.contentOffset.y/(NavigationContentTop+88);
    if (alpha > 1) {
        alpha = 1;
    }
    CGFloat navAlpha = 1-alpha;
    
    UILabel *titleLabel = [self navigationTitleLabel];
    titleLabel.alpha = alpha;
    
    UIImage *img = [UIImage imageWithColor:[UIColor colorWithWhite:1 alpha:1]];
    [self.navigationController.navigationBar setBackgroundImage:img forBarMetrics:UIBarMetricsDefault];
    
    //标题
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: LSHexRGBAlpha(0x333333, alpha), NSFontAttributeName: DECLARE_MediumFont(17)};
}

- (void)setNavigationItem:(NSString *)title{
    
    UILabel *titleLabel = [self navigationTitleLabel];
    titleLabel.text = title;
    [titleLabel sizeToFit];
}

- (UILabel *)navigationTitleLabel{

    UILabel *titleLabel = (UILabel *)self.navigationItem.titleView;
    if (!titleLabel) {
        titleLabel = [[UILabel alloc] init];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.textColor = LABEL_TEXT_BLACK_COLOR;
        titleLabel.font = DECLARE_MediumFont(17);
        self.navigationItem.titleView = titleLabel;
    }
    return titleLabel;
}

-(QMUIImagePreviewViewController *)imagePreviewViewController{
    if (!_imagePreviewViewController) {
        _imagePreviewViewController = [[QMUIImagePreviewViewController alloc] init];
        _imagePreviewViewController.backgroundColor = [UIColor colorWithWhite:0 alpha:0.8];
        _imagePreviewViewController.imagePreviewView.delegate = self;
        _imagePreviewViewController.imagePreviewView.currentImageIndex = 0;// 默认查看的图片的 index
        
    }
    return _imagePreviewViewController;
}

#pragma mark - 跳转
- (void)toWeMediaController:(LSWeMediaModel *)model{
    
    [self pushToShortVideo:model handleBlock:^(BaseViewController *viewController) {
        
    }];
}

- (void)toPlayListController:(NFVideoPlayListModel *)model{
    
    [self pushToVideoPlayListsDetail:model handleBlock:^(BaseViewController *viewController) {
        
    }];
}

- (void)toPersonalInfo{
    
}

#pragma mark - swipe
- (NSInteger)numberOfItemsInSwipeTableView:(SwipeTableView *)swipeView{
    
    return self.tablesArray.count;
}

- (UIView *)swipeTableView:(SwipeTableView *)swipeView viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view{
    
    if (index < self.tablesArray.count && self.tablesArray.count >  0) {
        
        LSBaseTableView *tableView =  self.tablesArray[index];
        if (!tableView.viewModel.isLoadedData) {
            if (index == 0) {
                [tableView excuteHeaderRefreshAtOnce];
            }else{
                [tableView excuteHeaderRefreshAtOnce];
            }
        }
        return tableView;
    }
    return nil;
}

-(void)swipeTableViewWillBeginDragging:(SwipeTableView *)swipeView{
    LSLog(@"swipeTableViewWillBeginDragging");
}

- (void)swipeTableViewDidEndDragging:(SwipeTableView *)swipeView willDecelerate:(BOOL)decelerate{
    
    LSLog(@"swipeTableViewDidEndDragging_willDecelerate:%d",decelerate);
}

- (void)swipeTableViewDidEndDecelerating:(SwipeTableView *)swipeView{
    LSLog(@"swipeTableViewDidEndDecelerating");
    self.isScrolling = NO;
    LSLog(@"isScrollingInAnimation=NO");
    
    if (swipeView.currentItemIndex != self.sliderBarView.selectedSegmentIndex) {
        self.sliderBarView.selectedSegmentIndex = swipeView.currentItemIndex;
    }
}

-(void)swipeTableViewDidEndScrollingAnimation:(SwipeTableView *)swipeView{
    LSLog(@"swipeTableViewDidEndScrollingAnimation");
    [self scrollNormal];
    self.isScrolling = NO;
    if (swipeView.currentItemIndex != self.sliderBarView.selectedSegmentIndex) {
        self.sliderBarView.selectedSegmentIndex = swipeView.currentItemIndex;

    }
    LSLog(@"isScrollingInAnimation=NO");
}

-(void)swipeTableViewDidScroll:(SwipeTableView *)swipeView{
    [self.sliderBarView updateWithContentOffsetX:swipeView.contentView.contentOffset.x];
    self.isScrolling = YES;
    LSLog(@"isScrollingInAnimation=YES");
}

- (void)reportPageClick{
    
    NSInteger currentIndex = self.currentIndex;
    LSLog(@"reportPageClick    self.tableView.currentItemIndex   =%zd", currentIndex);
    switch (currentIndex) {
        case 0:
            [LSMobClick logEventName:nil withID:NFStatisticsPersonPageVideo extra:nil];
            break;
        case 1:
            [LSMobClick logEventName:nil withID:NFStatisticsPersonPagePlayList extra:nil];
            break;
        case 2:
            [LSMobClick logEventName:nil withID:NFStatisticsPersonPageLikeList extra:nil];
            break;
        default:
            break;
    }
    [self.grouprouterConfig configAppearWithIndex:currentIndex];
}

- (void)changeSwipeViewIndex:(NFSliderBarView *)sliderBarView{
    
    LSLog(@"isScrollingInAnimation=YES_offset1=%@",NSStringFromCGPoint(self.tableView.contentView.contentOffset));
    if (sliderBarView.selectedSegmentIndex !=  self.tableView.currentItemIndex) {
        [self.tableView scrollToItemAtIndex:sliderBarView.selectedSegmentIndex animated:YES];
        LSLog(@"isScrollingInAnimation=YES_offset2=%@",NSStringFromCGPoint(self.tableView.contentView.contentOffset));
        [self.sliderBarView updateWithContentOffsetX:self.tableView.contentView.contentOffset.x];

    }
    
}

- (void)scrollNormal{
    if (self.tablesArray.count && self.tableView.currentItemIndex < self.tablesArray.count) {
        NFHomeTableView *tableView = self.tablesArray[self.tableView.currentItemIndex];
        tableView.contentOffset = CGPointMake(tableView.contentOffset.x, tableView.contentOffset.y + 1);
        tableView.contentOffset = CGPointMake(tableView.contentOffset.x, tableView.contentOffset.y - 1);
    }
    self.isScrolling = NO;
    LSLog(@"isScrollingInAnimation=NO");
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    for (UITableView *table in self.tablesArray) {
        LSLog(@"table:%@.contentInset = %@",[table class],NSStringFromUIEdgeInsets(table.contentInset));
    }
    LSLog(@"table2:%@.contentInset = %@",[self.tableView.contentView class],NSStringFromUIEdgeInsets(self.tableView.contentView.contentInset));
}

@end
