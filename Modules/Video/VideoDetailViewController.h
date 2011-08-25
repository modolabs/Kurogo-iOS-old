//
//  VideoDetailViewController.h
//  Universitas
//
//  Created by Jim Kang on 4/5/11.
//  Copyright 2011 Modo Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Video.h"
#import <MediaPlayer/MediaPlayer.h>
#import "VideoDataManager.h"
#import "KGOShareButtonController.h"
#import "VideoDetailHeaderView.h"



@interface VideoDetailViewController : UIViewController <VideoDetailHeaderDelegate>{
    KGOShareButtonController *_shareController;    
    VideoDetailHeaderView *_headerView;
    UIView *bookmarkSharingView;

}

@property (nonatomic, retain) Video *video;
@property (nonatomic, retain) MPMoviePlayerController *player;
@property (nonatomic, retain) VideoDataManager *dataManager;
@property (nonatomic, retain) NSString *section;
@property (nonatomic, retain) UIScrollView *scrollView;
@property (nonatomic, retain) VideoDetailHeaderView *headerView;

- (id)initWithVideo:(Video *)aVideo andSection:(NSString *)videoSection;
- (void)requestVideoForDetailView;
- (void) setDescription;
- (UIView *)viewForTableHeader;

@end
