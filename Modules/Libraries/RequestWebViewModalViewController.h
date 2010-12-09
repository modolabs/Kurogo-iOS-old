//
//  RequestWebViewModalViewController.h
//  Harvard Mobile
//
//  Created by Muhammad J Amjad on 12/9/10.
//  Copyright 2010 ModoLabs Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface RequestWebViewModalViewController : UIViewController <UIWebViewDelegate>{
	
	UIWebView * urlWebView;
	NSString * requestUrl;
	
	UIActivityIndicatorView *av;
	
	UIView * navbarView;
	
	
	UISegmentedControl * barButtonControl; // to get the right shape automagically
}

@property (nonatomic, retain) UIActivityIndicatorView *av;

-(id) initWithRequestUrl: (NSString *) url;

@end
