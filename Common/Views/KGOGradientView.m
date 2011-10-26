#import "KGOGradientView.h"

@implementation KGOGradientView

@synthesize tintColor, direction,
topRightCornerRadius, topLeftCornerRadius,
bottomRightCornerRadius, bottomLeftCornerRadius;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.direction = KGOGradientDirectionDefault;
        [self setBackgroundColor:[UIColor clearColor]];
        topLeftCornerRadius = topLeftCornerRadius = bottomRightCornerRadius = bottomLeftCornerRadius = 0;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.direction = KGOGradientDirectionDefault;
        [self setBackgroundColor:[UIColor clearColor]];
        topLeftCornerRadius = topLeftCornerRadius = bottomRightCornerRadius = bottomLeftCornerRadius = 0;
    }
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();

    // rounded corner code from 
    // http://stackoverflow.com/questions/1331632/uitableviewcell-rounded-corners-and-clip-subviews

    CGFloat minx = CGRectGetMinX(rect);
    CGFloat midx = CGRectGetMidX(rect);
    CGFloat maxx = CGRectGetMaxX(rect);
    CGFloat miny = CGRectGetMinY(rect);
    CGFloat midy = CGRectGetMidY(rect);
    CGFloat maxy = CGRectGetMaxY(rect);
    
    // start from top and go clockwise
    CGContextMoveToPoint(context, midx, miny);
    if (self.topRightCornerRadius) {
        CGContextAddArcToPoint(context, maxx, miny, maxx, midy, self.topRightCornerRadius);
    } else {
        CGContextAddLineToPoint(context, maxx, miny);
        CGContextAddLineToPoint(context, maxx, midy);
    }
    
    if (self.bottomRightCornerRadius) {
        CGContextAddArcToPoint(context, maxx, maxy, midx, maxy, self.bottomRightCornerRadius);
    } else {
        CGContextAddLineToPoint(context, maxx, maxy);
        CGContextAddLineToPoint(context, midx, maxy);
    }
    
    if (self.bottomLeftCornerRadius) {
        CGContextAddArcToPoint(context, minx, maxy, minx, midy, self.bottomLeftCornerRadius);
    } else {
        CGContextAddLineToPoint(context, minx, maxy);
        CGContextAddLineToPoint(context, minx, midy);
    }

    if (self.topLeftCornerRadius) {
        CGContextAddArcToPoint(context, minx, miny, midx, miny, self.topLeftCornerRadius);
    } else {
        CGContextAddLineToPoint(context, minx, miny);
        CGContextAddLineToPoint(context, midx, miny);
    }
    
    CGContextClip(context);
    
    // create gradient

    // this only works on iOS 5
    //CGFloat red, green, blue, alpha;
    //[self.tintColor getRed:&red green:&green blue:&blue alpha:&alpha];

    const CGFloat *tintComps = CGColorGetComponents([self.tintColor CGColor]);
    CGFloat red = tintComps[0];
    CGFloat green = tintComps[1];
    CGFloat blue = tintComps[2];
    CGFloat alpha = tintComps[3];
    
    CGFloat components[8] = {
        red * 1.1, green * 1.1, blue * 1.1, alpha,
        red * 0.9, green * 0.9, blue * 0.9, alpha
    };
    CGFloat locations[2] = { 0.0, 1.0 };

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, components, locations, 2);

    CGPoint startPoint, endPoint;
    
    switch (self.direction) {
        case KGOGradientDirectionUp:
            startPoint = CGPointMake(midx, maxy);
            endPoint = CGPointMake(midx, miny);
            break;

        case KGOGradientDirectionLeft:
            startPoint = CGPointMake(minx, midy);
            endPoint = CGPointMake(maxx, midy);
            break;

        case KGOGradientDirectionRight:
            startPoint = CGPointMake(maxx, midy);
            endPoint = CGPointMake(minx, midy);
            break;

        case KGOGradientDirectionDown:
        case KGOGradientDirectionDefault:
        default:
            startPoint = CGPointMake(midx, miny);
            endPoint = CGPointMake(midx, maxy);
            break;
    }
    
    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
    CGColorSpaceRelease(colorSpace);
    CGGradientRelease(gradient);
}

@end
