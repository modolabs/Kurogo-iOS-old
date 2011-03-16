#import <UIKit/UIKit.h>

@class FacebookComment;
@protocol FacebookUploadDelegate;
/*
@protocol FacebookCommentDelegate <NSObject>

- (void)didPostComment:(FacebookComment *)aComment;

@end
*/
@class FacebookParentPost;

@interface FacebookCommentViewController : UIViewController <UITextViewDelegate> {
    
    IBOutlet UITextView *_textView;
    IBOutlet UIView *_loadingViewContainer;
    IBOutlet UIActivityIndicatorView *_spinner;
    IBOutlet UIButton *_submitButton;
    
}

@property(nonatomic, retain) FacebookParentPost *post;
//@property(nonatomic, assign) id<FacebookCommentDelegate> delegate;
@property(nonatomic, assign) id<FacebookUploadDelegate> delegate;

- (IBAction)submitButtonPressed:(UIButton *)sender;

@end
