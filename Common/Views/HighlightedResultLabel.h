#import <UIKit/UIKit.h>


@interface HighlightedResultLabel : UIView {
    
    UIFont *_font;
    UIFont *_boldFont;
    
    UIColor *_textColor;
    UIColor *_highlightedTextColor;

    NSString *_text;
    NSArray *_searchTokens;
    
    NSArray *_labels;
    
    BOOL _highlighted;
}

@property (nonatomic) BOOL highlighted;

@property (nonatomic, retain) UIFont *font;
@property (nonatomic, retain) UIFont *boldFont;
@property (nonatomic, retain) UIColor *textColor;
@property (nonatomic, retain) UIColor *highlightedTextColor;

@property (nonatomic, retain) NSString *text;
@property (nonatomic, retain) NSArray *searchTokens;

@end
