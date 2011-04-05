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

@interface VideoDetailViewController : UIViewController {

}

@property (nonatomic, retain) Video *video;
@property (nonatomic, retain) MPMoviePlayerController *player;

- (id)initWithVideo:(Video *)aVideo;

@end
