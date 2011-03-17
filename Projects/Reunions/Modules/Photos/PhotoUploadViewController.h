#import <UIKit/UIKit.h>

@class FacebookPhotosViewController;

@interface PhotoUploadViewController : UIViewController {
    
    IBOutlet UIImageView *_imageView;
    IBOutlet UIButton *_submitButton;
    IBOutlet UITextView *_textView;
    
    IBOutlet UIView *_loadingView;
    IBOutlet UIActivityIndicatorView *_spinner;
    
}

- (IBAction)submitButtonPressed:(UIButton *)sender;
- (void)cancelButtonPressed:(id)sender;

@property(nonatomic, retain) UIImage *photo;
@property(nonatomic, retain) NSString *profile;

// might make this a delegate later
@property(nonatomic, assign) FacebookPhotosViewController *parentVC;

@end
