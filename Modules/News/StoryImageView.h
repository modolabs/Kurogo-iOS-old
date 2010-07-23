#import <UIKit/UIKit.h>
#import "ConnectionWrapper.h"

@class NewsImage;
@class StoryImageView;

@protocol StoryImageViewDelegate <NSObject>
@optional
- (void)storyImageViewDidDisplayImage:(StoryImageView *)imageView;
@end


@interface StoryImageView : UIView <ConnectionWrapperDelegate> {
    id <StoryImageViewDelegate> delegate;
    NewsImage *image;
	ConnectionWrapper *connection;
	NSData *imageData;
    UIActivityIndicatorView *loadingView;
    UIImageView *imageView;
}

- (void)loadImage;
- (void)requestImage;
- (BOOL)displayImage;

@property (nonatomic, assign) id <StoryImageViewDelegate> delegate;
@property (nonatomic, retain) NewsImage *image;
@property (nonatomic, retain) NSData *imageData;
@property (nonatomic, retain) UIActivityIndicatorView *loadingView;
@property (nonatomic, retain) UIImageView *imageView;

@end
