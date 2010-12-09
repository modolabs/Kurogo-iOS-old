//
//  RequestItemWebViewModalViewController.h
//  Harvard Mobile
//
//  Created by Muhammad J Amjad on 12/9/10.
//  Copyright 2010 ModoLabs Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface RequestItemWebViewModalViewController : UIViewController <UIWebViewDelegate>{
	
	UIWebView * webView;
	NSString * requestUrl;

}

@end
