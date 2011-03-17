#import "KGOModule.h"

@class KGOHomeScreenWidget;

@interface MicroblogModule : KGOModule {
    
    KGOHomeScreenWidget *_chatBubble;
    KGOHomeScreenWidget *_buttonWidget;
    
    UILabel *_chatBubbleTitleLabel;
    UILabel *_chatBubbleSubtitleLabel;
    
}

@property(nonatomic, retain) UIImage *buttonImage;
@property(nonatomic, retain) NSString *labelText;

@property(nonatomic, readonly) KGOHomeScreenWidget *buttonWidget;

// chat bubble properties
@property(nonatomic, readonly) KGOHomeScreenWidget *chatBubble;
@property(nonatomic, readonly) UILabel *chatBubbleTitleLabel;
@property(nonatomic, readonly) UILabel *chatBubbleSubtitleLabel;
@property(nonatomic) CGFloat chatBubbleCaratOffset;

@end
