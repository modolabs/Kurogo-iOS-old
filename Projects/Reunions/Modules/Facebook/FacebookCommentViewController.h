#import <UIKit/UIKit.h>

@class FacebookComment;

@protocol FacebookCommentDelegate <NSObject>

- (void)didPostComment:(FacebookComment *)aComment;

@end

@class FacebookPost;

@interface FacebookCommentViewController : UIViewController <UITextViewDelegate> {
    
    IBOutlet UITextView *_textView;
    IBOutlet UIView *_loadingViewContainer;
    IBOutlet UIActivityIndicatorView *_spinner;
    IBOutlet UIButton *_submitButton;
    
}

@property(nonatomic, retain) FacebookPost *post;
@property(nonatomic, assign) id<FacebookCommentDelegate> delegate;

- (IBAction)submitButtonPressed:(UIButton *)sender;
- (void)didPostComment:(id)result;
- (void)didFailToPostComment:(NSError *)error;

@end
