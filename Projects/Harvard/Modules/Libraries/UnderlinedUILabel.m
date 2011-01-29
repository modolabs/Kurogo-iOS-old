//
//  UnderlinedUILabel.m
//  Harvard Mobile
//
//  Created by Muhammad J Amjad on 12/14/10.
//  Copyright 2010 ModoLabs Inc. All rights reserved.
//

#import "UnderlinedUILabel.h"


@implementation UnderlinedUILabel


- (void)drawRect:(CGRect)rect 
{
	// Get the Render Context
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	
	// Measure the font size, so the line fits the text.
	// Could be that "titleLabel" is something else in other classes like UILable, dont know.
	// So make sure you fix it here if you are enhancing UILabel or something else..
	CGSize fontSize =[self.text sizeWithFont:super.font
											   forWidth:self.bounds.size.width
										  lineBreakMode:UILineBreakModeTailTruncation];
	// Get the fonts color. 
	const float * colors = CGColorGetComponents(self.textColor.CGColor);
	// Sets the color to draw the line
	CGContextSetRGBStrokeColor(ctx, colors[0], colors[1], colors[2], 1.0f); // Format : RGBA
	
	// Line Width : make thinner or bigger if you want
	CGContextSetLineWidth(ctx, 1.0f);
	
	// Calculate the starting point (left) and target (right)	
	float fontLeft = 0; //self.titleLabel.center.x - fontSize.width/2.0;
	float fontRight = fontSize.width; //self.titleLabel.center.x + fontSize.width/2.0;
	
	// Add Move Command to point the draw cursor to the starting point
	CGContextMoveToPoint(ctx, fontLeft, self.bounds.size.height - 1);
	
	// Add Command to draw a Line
	CGContextAddLineToPoint(ctx, fontRight, self.bounds.size.height - 1);
	
	// Actually draw the line.
	CGContextStrokePath(ctx);
	
	// should be nothing, but who knows...
	[super drawRect:rect];   
}


/*- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetRGBStrokeColor(ctx, 207.0f/255.0f, 91.0f/255.0f, 44.0f/255.0f, 1.0f); // RGBA
    CGContextSetLineWidth(ctx, 1.0f);
	
    CGContextMoveToPoint(ctx, 0, self.bounds.size.height - 1);
    CGContextAddLineToPoint(ctx, self.bounds.size.width, self.bounds.size.height - 1);
	
    CGContextStrokePath(ctx);
	
    [super drawRect:rect];  
}*/
@end
