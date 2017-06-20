//
//  LGPhotoPickerToolBar.m
//  LGPhotoBrowser
//
//  Created by Liujinlong on 19/06/2017.
//  Copyright © 2017 L&G. All rights reserved.
//

#import "LGPhotoPickerToolBar.h"

@interface LGPhotoPickerToolBar ()
@property (weak, nonatomic) IBOutlet UILabel *addedCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *remainCountLabel;

@end

@implementation LGPhotoPickerToolBar

- (void)setAddedCount:(NSInteger)addedCount {
    _addedCount = addedCount;
    self.addedCountLabel.text = [NSString stringWithFormat:@"%@", @(addedCount)];
}

- (void)setRemainCount:(NSInteger)remainCount {
    _remainCount = remainCount;
    self.remainCountLabel.text = [NSString stringWithFormat:@"%@", @(remainCount)];
}

@end
