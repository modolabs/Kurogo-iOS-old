#import <UIKit/UIKit.h>

typedef enum {
    KGOGradientDirectionDefault = 0,
    KGOGradientDirectionUp,
    KGOGradientDirectionDown,
    KGOGradientDirectionLeft,
    KGOGradientDirectionRight
} KGOGradientDirection;

typedef enum {
    KGOGradientViewCornerTopRight = 1 << 8,
    KGOGradientViewCornerTopLeft = 2 << 8,
    KGOGradientViewCornerBottomRight = 3 << 8,
    KGOGradientViewCornerBottomLeft = 4 << 8,
} KGOGradientViewCorner;

@interface KGOGradientView : UIView

@property (nonatomic) KGOGradientDirection direction;
@property (nonatomic, retain) UIColor *tintColor;
@property (nonatomic) CGFloat topRightCornerRadius;
@property (nonatomic) CGFloat topLeftCornerRadius;
@property (nonatomic) CGFloat bottomRightCornerRadius;
@property (nonatomic) CGFloat bottomLeftCornerRadius;

@end
