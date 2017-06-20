//
//  LGPhotoPickerAssetsViewController.m
//  LGPhotoBrowser
//
//  Created by ligang on 15/10/27.
//  Copyright (c) 2015年 L&G. All rights reserved.


#import <AssetsLibrary/AssetsLibrary.h>
#import "LGPhoto.h"
#import "LGPhotoPickerCollectionView.h"
#import "LGPhotoPickerGroup.h"
#import "LGPhotoPickerCollectionViewCell.h"
#import "LGPhotoPickerFooterCollectionReusableView.h"
#import "LGPhotoPickerConfiguration.h"
#import "LGPhotoPickerToolBar.h"

static CGFloat CELL_ROW = 4;
static CGFloat CELL_MARGIN = 2;
static CGFloat CELL_LINE_MARGIN = 2;
static CGFloat TOOLBAR_HEIGHT = 50;

static NSString *const _cellIdentifier = @"cell";
static NSString *const _footerIdentifier = @"FooterView";
static NSString *const _identifier = @"toolBarThumbCollectionViewCell";
@interface LGPhotoPickerAssetsViewController () <LGPhotoPickerCollectionViewDelegate,LGPhotoPickerBrowserViewControllerDataSource,LGPhotoPickerBrowserViewControllerDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate>

// View
// 相片View
@property (nonatomic , strong) LGPhotoPickerCollectionView *collectionView;
// 标记View
@property (nonatomic, weak)   UILabel *makeView;
@property (nonatomic, strong) UIButton *sendBtn;
@property (nonatomic, strong) UIButton *previewBtn;
@property (nonatomic, weak)   LGPhotoPickerToolBar *toolBar;
@property (nonatomic, assign) NSUInteger privateTempMaxCount;
@property (nonatomic, strong) NSMutableArray *assets;
@property (nonatomic, strong) NSMutableArray<__kindof LGPhotoAssets*> *selectAssets;
@property (nonatomic, strong) NSMutableArray *takePhotoImages;
// 1 - 相册浏览器的数据源是 selectAssets， 0 - 相册浏览器的数据源是 assets
@property (nonatomic, assign) BOOL isPreview;
// 是否发送原图
@property (nonatomic, assign) BOOL isOriginal;

@property (nonatomic, strong) LGPhotoPickerConfiguration *configuration;

@end

@implementation LGPhotoPickerAssetsViewController

#pragma mark - circle life

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.bounds = [UIScreen mainScreen].bounds;
    self.view.backgroundColor = [UIColor whiteColor];
    // 获取相册
    [self setupAssets];
    
    [self addNavBarCancelButton];
    // 初始化底部ToorBar
    [self setupToorBar];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.collectionView reloadData];
}

- (void)viewDidDisappear:(BOOL)animated {
    // 赋值给上一个控制器,以便记录上次选择的照片
    if (self.selectedAssetsBlock) {
        self.selectedAssetsBlock(self.selectAssets);
    }
}

- (instancetype)initWithConfiguration:(LGPhotoPickerConfiguration *)configuration {
    if (self = [super init]) {
        _configuration = configuration;
    }
    return self;
}


#pragma mark - Getter and Setter

- (NSMutableArray *)selectAssets{
    if (!_selectAssets) {
        _selectAssets = [NSMutableArray array];
    }
    return _selectAssets;
}

- (NSMutableArray *)takePhotoImages{
    if (!_takePhotoImages) {
        _takePhotoImages = [NSMutableArray array];
    }
    return _takePhotoImages;
}


- (void)setSelectPickerAssets:(NSArray *)selectPickerAssets{
    NSSet *set = [NSSet setWithArray:selectPickerAssets];
    _selectPickerAssets = [set allObjects];
    
    if (!self.assets) {
        self.assets = [NSMutableArray arrayWithArray:selectPickerAssets];
    }else{
        [self.assets addObjectsFromArray:selectPickerAssets];
    }
    
    self.selectAssets = [selectPickerAssets mutableCopy];
    NSInteger count = self.selectAssets.count;
    self.makeView.hidden = !count;
    self.makeView.text = [NSString stringWithFormat:@"%ld",(long)count];
    self.sendBtn.enabled = (count > 0);
    self.previewBtn.enabled = (count > 0);
    
    [self updateToolbar];
}

#pragma mark collectionView
- (LGPhotoPickerCollectionView *)collectionView{
    if (!_collectionView) {
        
        CGFloat cellW = (self.view.frame.size.width - CELL_MARGIN * CELL_ROW + 1) / CELL_ROW;
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.itemSize = CGSizeMake(cellW, cellW);
        layout.minimumInteritemSpacing = 0;
        layout.minimumLineSpacing = CELL_LINE_MARGIN;

        
        LGPhotoPickerCollectionView *collectionView = [[LGPhotoPickerCollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout configuraiton:self.configuration];
        // 时间置顶
        collectionView.translatesAutoresizingMaskIntoConstraints = NO;
        [collectionView registerClass:[LGPhotoPickerCollectionViewCell class] forCellWithReuseIdentifier:_cellIdentifier];
        // 底部的View
        [collectionView registerClass:[LGPhotoPickerFooterCollectionReusableView class]  forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:_footerIdentifier];
        
        collectionView.contentInset = UIEdgeInsetsMake(5, 0,TOOLBAR_HEIGHT, 0);
        collectionView.collectionViewDelegate = self;
        [self.view insertSubview:collectionView belowSubview:self.toolBar];
		collectionView.frame = self.view.bounds;
        _collectionView = collectionView;
    }
    return _collectionView;
}



#pragma mark - 创建右边取消按钮
- (void)addNavBarCancelButton{
	UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
																							target:self
																							action:@selector(cancelBtnTouched)];
	self.navigationItem.rightBarButtonItem = temporaryBarButtonItem;
}

#pragma mark 初始化所有的组
- (void) setupAssets{
    if (!self.assets) {
        self.assets = [NSMutableArray array];
    }
    
    __block NSMutableArray *assetsM = [NSMutableArray array];
    __weak typeof(self) weakSelf = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{

        [[LGPhotoPickerDatas defaultPicker] getGroupPhotosWithGroup:self.assetsGroup finished:^(NSArray *assets) {
            
            [assets enumerateObjectsUsingBlock:^(ALAsset *asset, NSUInteger idx, BOOL *stop) {
                LGPhotoAssets *lgAsset = [[LGPhotoAssets alloc] init];
                lgAsset.asset = asset;
                [assetsM addObject:lgAsset];
            }];
            weakSelf.collectionView.dataArray = assetsM;
            [self.assets setArray:assetsM];
        }];
    });
}

- (void)pickerCollectionViewDidCameraSelect:(LGPhotoPickerCollectionView *)pickerCollectionView{
    
    UIImagePickerController *ctrl = [[UIImagePickerController alloc] init];
    ctrl.delegate = self;
    ctrl.sourceType = UIImagePickerControllerSourceTypeCamera;
    [self presentViewController:ctrl animated:YES completion:nil];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        // 处理
//        UIImage *image = info[@"UIImagePickerControllerOriginalImage"];
        
        // FIX: 应该加入LGPhotoAssets类型，不应该加入UIImage类型
//        [self.assets addObject:image];
//        [self.selectAssets addObject:image];
//        [self.takePhotoImages addObject:image];
        
        NSInteger count = self.selectAssets.count;
        self.makeView.hidden = !count;
        self.makeView.text = [NSString stringWithFormat:@"%ld",(long)count];
        self.sendBtn.enabled = (count > 0);
        self.previewBtn.enabled = (count > 0);
        
        [picker dismissViewControllerAnimated:YES completion:nil];
    }else{
        NSLog(@"请在真机使用!");
    }
}

#pragma mark -初始化底部ToorBar
- (void)setupToorBar {
    
    LGPhotoPickerToolBar *toolBar = [[[UINib nibWithNibName:@"LGPhotoPickerToolBar" bundle:nil] instantiateWithOwner:self options:nil] firstObject];
    CGFloat y = CGRectGetHeight([UIScreen mainScreen].bounds) - TOOLBAR_HEIGHT;
    CGFloat w = CGRectGetWidth([UIScreen mainScreen].bounds);
    toolBar.frame = CGRectMake(0, y, w, TOOLBAR_HEIGHT);
    [self.view addSubview:toolBar];
    self.toolBar = toolBar;

}

#pragma mark - setter

- (void)setAssetsGroup:(LGPhotoPickerGroup *)assetsGroup {
    if (!assetsGroup.groupName.length) return ;
    
    _assetsGroup = assetsGroup;
    
    self.title = assetsGroup.groupName;

}

#pragma mark - LGPhotoPickerCollectionViewDelegate

//cell被点击会调用
- (void) pickerCollectionCellTouchedIndexPath:(NSIndexPath *)indexPath {
    [self setupPhotoBrowserInCasePreview:NO CurrentIndexPath:indexPath];
}

- (void)pickerCollectionViewDidSelected:(LGPhotoPickerCollectionView *)pickerCollectionView selectedAsset:(LGPhotoAssets *)assets {
    
    [self.selectAssets addObject:assets];
    [self updateToolbar];
    
}

- (void)pickerCollectionViewDidDeselected:(LGPhotoPickerCollectionView *)pickerCollectionView deselectedAsset:(LGPhotoAssets *)assets {
    
    //根据url删除对象
    NSArray *arr = [self.selectAssets copy];
    for (LGPhotoAssets *selectAsset in arr) {
        if ([selectAsset.assetURL isEqual:assets.assetURL]) {
            [self.selectAssets removeObject:selectAsset];
        }
    }

    [self updateToolbar];
}

- (NSArray<LGPhotoAssets *> *)selectedAssestsForPhotoPickerCollectionView:(LGPhotoPickerCollectionView *)collectionView {
    return self.selectAssets;
}

- (void)updateToolbar {
    NSInteger count = self.selectAssets.count;
    self.toolBar.addedCount = count;
    self.toolBar.remainCount = self.configuration.maxSelectCount - count;
}

#pragma mark - LGPhotoPickerBrowserViewControllerDataSource

- (NSInteger)numberOfSectionInPhotosInPickerBrowser:(LGPhotoPickerBrowserViewController *)pickerBrowser{
    return 1;
}

- (NSInteger)photoBrowser:(LGPhotoPickerBrowserViewController *)photoBrowser numberOfItemsInSection:(NSUInteger)section{
    if (self.isPreview) {
        return self.selectAssets.count;
    } else {
        return self.assets.count;
    }
}

- (LGPhotoPickerBrowserPhoto *)photoBrowser:(LGPhotoPickerBrowserViewController *)pickerBrowser photoAtIndexPath:(NSIndexPath *)indexPath
{
    
    LGPhotoAssets *imageObj = [[LGPhotoAssets alloc] init];
    if (self.isPreview && self.selectAssets.count) {
        imageObj = [self.selectAssets objectAtIndex:indexPath.row];
    } else if (!self.isPreview && self.assets.count){
        imageObj = [self.assets objectAtIndex:indexPath.row];
    }
    // 包装下imageObj 成 LGPhotoPickerBrowserPhoto 传给数据源
    LGPhotoPickerBrowserPhoto *photo = [LGPhotoPickerBrowserPhoto photoAnyImageObjWith:imageObj];
    
    LGPhotoPickerCollectionViewCell *cell = (LGPhotoPickerCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    photo.thumbImage = cell.imageView.image;
    
    return photo;
}

#pragma mark - LGPhotoPickerBrowserViewControllerDelegate

- (void)photoBrowserWillExit:(LGPhotoPickerBrowserViewController *)pickerBrowser
{
    self.selectAssets = [NSMutableArray arrayWithArray:pickerBrowser.selectedAssets];
    NSInteger count = self.selectAssets.count;
    self.makeView.hidden = !count;
    self.makeView.text = [NSString stringWithFormat:@"%ld",(long)count];
    self.sendBtn.enabled = (count > 0);
    self.previewBtn.enabled = (count > 0);
    self.isOriginal = pickerBrowser.isOriginal;
    [self updateToolbar];
}

- (void)photoBrowserSendBtnTouched:(LGPhotoPickerBrowserViewController *)pickerBrowser isOriginal:(BOOL)isOriginal
{
    self.isOriginal = isOriginal;
    self.selectAssets = pickerBrowser.selectedAssets;
    [self sendBtnTouched];
}

#pragma mark - Actions

- (void) cancelBtnTouched{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) sendBtnTouched {
	[[NSNotificationCenter defaultCenter] postNotificationName:PICKER_TAKE_DONE object:nil userInfo:@{@"selectAssets":self.selectAssets,@"isOriginal":@(self.isOriginal)}];
	NSLog(@"%@",@(self.isOriginal));
    [self dismissViewControllerAnimated:NO completion:nil];
}

#pragma mark - Private Method
/**
 *  跳转照片浏览器
 *
 *  @param preview YES - 从‘预览’按钮进去，浏览器显示的时被选中的照片
 *                  NO - 点击cell进去，浏览器显示所有照片
 *  @param CurrentIndexPath 进入浏览器后展示图片的位置
 */
- (void) setupPhotoBrowserInCasePreview:(BOOL)preview
                       CurrentIndexPath:(NSIndexPath *)indexPath{
    
    self.isPreview = preview;
    // 图片游览器
    LGPhotoPickerBrowserViewController *pickerBrowser = [[LGPhotoPickerBrowserViewController alloc] init];
    pickerBrowser.showType = self.configuration.showType;
    pickerBrowser.delegate = self;
    pickerBrowser.dataSource = self;
    pickerBrowser.maxCount = self.configuration.maxSelectCount;
    pickerBrowser.isOriginal = self.isOriginal;
    pickerBrowser.selectedAssets = [self.selectAssets mutableCopy];
    pickerBrowser.editing = NO;
    // 当前选中的值
    pickerBrowser.currentIndexPath = indexPath;
    [self.navigationController presentViewController:pickerBrowser animated:YES completion:nil];
    
}

@end
