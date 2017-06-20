//
//  LGPhotoPickerToolBar.h
//  LGPhotoBrowser
//
//  Created by Liujinlong on 19/06/2017.
//  Copyright © 2017 L&G. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LGPhotoPickerToolBar : UIView


/**
 已经添加的个数
 */
@property (nonatomic, assign) NSInteger addedCount;


/**
 剩余的个数
 */
@property (nonatomic, assign) NSInteger remainCount;


/**
 点击完成的回调
 */
@property (nonatomic, copy) void (^clickFinishBlock)();

@end
