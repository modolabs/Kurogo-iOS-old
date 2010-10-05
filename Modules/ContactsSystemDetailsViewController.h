//
//  ContactsSystemDetailsViewController.h
//  Harvard Mobile
//
//  Created by Muhammad Amjad on 9/25/10.
//  Copyright 2010 Modo Labs. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ContactsSystemDetailsViewController : UIViewController {

	UIWebView *systemTextDetailsView;
	NSString *titleString;	
	NSString *_detailsString;
}

@property (nonatomic, retain) NSString * titleString;
@property (nonatomic, retain) NSString * detailsString;


@end
