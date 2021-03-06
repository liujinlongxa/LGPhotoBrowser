//
//  LGPickerViewController.m
//  LGPhotoBrowser
//
//  Created by ligang on 15/10/27.
//  Copyright (c) 2015年 L&G. All rights reserved.

#import "LGPhotoPickerViewController.h"
#import "LGPhotoPickerConfiguration.h"
#import "LGPhoto.h"

@interface LGPhotoPickerViewController ()

@property (nonatomic , strong) LGPhotoPickerGroupViewController *groupVc;

//是否发送原图，1 原图 0 压缩过图
@property (nonatomic, assign) BOOL isOriginal;

@property (nonatomic, strong) LGPhotoPickerConfiguration *configuration;

@end

@implementation LGPhotoPickerViewController

- (instancetype)initWithConfiguration:(LGPhotoPickerConfiguration *)configuration{
    self = [super init];
    if (self) {
        _configuration = configuration;
    }
    return self;
}

#pragma mark - Life cycle
- (void)viewDidLoad {
    
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self addNotification];
    [self createNavigationController];
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.groupVc.delegate = nil;
}

#pragma mark - init Action
- (void) createNavigationController{
    _groupVc = [[LGPhotoPickerGroupViewController alloc] initWithConfiguration:self.configuration];

    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:_groupVc];
    
    nav.view.frame = self.view.bounds;
    [self addChildViewController:nav];
    [self.view addSubview:nav.view];
}

- (void)setSelectPickers:(NSArray *)selectPickers{
    _selectPickers = selectPickers;
    self.groupVc.selectAsstes = [selectPickers mutableCopy];
}

- (void) addNotification{
    // 监听异步done通知
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(done:) name:PICKER_TAKE_DONE object:nil];
}

#pragma mark - 监听点击Done按钮
- (void)done:(NSNotification *)note{
    NSArray *selectArray =  note.userInfo[@"selectAssets"];
    self.isOriginal = [note.userInfo[@"isOriginal"] boolValue];
    if ([self.delegate respondsToSelector:@selector(pickerViewControllerDoneAsstes:isOriginal:)]) {
        [self.delegate pickerViewControllerDoneAsstes:selectArray  isOriginal:self.isOriginal];
    } else if (self.callBack) {
        self.callBack(selectArray);
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)setDelegate:(id<LGPhotoPickerViewControllerDelegate>)delegate{
    _delegate = delegate;
    self.groupVc.delegate = delegate;
}
@end
