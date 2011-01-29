//
//  AnnouncementWebViewController.h
//  Harvard Mobile
//
//  Created by Muhammad Amjad on 9/22/10.
//  Copyright 2010 Modo Labs. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface AnnouncementWebViewController : UIViewController {
	
	UIWebView *webView;
	NSString *htmlStringToDisplay;
	NSString *titleString;
	NSString *dateString;

}

@property (nonatomic, retain) NSString * htmlStringToDisplay;
@property (nonatomic, retain) NSString * titleString;
@property (nonatomic, retain) NSString * dateString;

- (NSString *)htmlStringFromString:(NSString *)source;

@end
