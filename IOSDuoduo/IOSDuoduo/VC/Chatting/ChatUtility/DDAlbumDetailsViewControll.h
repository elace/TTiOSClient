//
//  DDAlbumDetailsViewControllViewController.h
//  IOSDuoduo
//
//  Created by 东邪 on 14-6-4.
//  Copyright (c) 2014年 dujia. All rights reserved.
//

#import "AQGridViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
@class DDAlbumDetailsBottomBar;
@interface DDAlbumDetailsViewControll : UIViewController<AQGridViewDataSource,AQGridViewDelegate>
@property(nonatomic,strong)ALAssetsGroup *assetsGroup;
@property(nonatomic,strong)NSMutableArray *assetsArray;
@property(nonatomic,strong)NSMutableArray *choosePhotosArray;
@property(nonatomic,strong)AQGridView *gridView;
@property(nonatomic,strong)DDAlbumDetailsBottomBar *bar;

@end