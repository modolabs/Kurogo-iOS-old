#import <UIKit/UIKit.h>
#import "ConnectionWrapper.h"

@class NewsImage;

@interface StoryThumbnailView : UIView <ConnectionWrapperDelegate> {
    //NewsImageRep *imageRep;
    NewsImage *image;
	ConnectionWrapper *connection;
	NSData *imageData;
    UIActivityIndicatorView *loadingView;
    UIImageView *imageView;
}

- (void)loadImage;
- (void)requestImage;
- (BOOL)displayImage;

//@property (nonatomic, retain) NewsImageRep *imageRep;
@property (nonatomic, retain) NewsImage *image;
@property (nonatomic, retain) ConnectionWrapper *connection;
@property (nonatomic, retain) NSData *imageData;
@property (nonatomic, retain) UIActivityIndicatorView *loadingView;
@property (nonatomic, retain) UIImageView *imageView;

@end
