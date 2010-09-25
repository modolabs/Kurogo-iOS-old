    //
//  ContactsSystemDetailsViewController.m
//  Harvard Mobile
//
//  Created by Muhammad Amjad on 9/25/10.
//  Copyright 2010 Modo Labs. All rights reserved.
//

#import "ContactsSystemDetailsViewController.h"


@implementation ContactsSystemDetailsViewController
@synthesize titleString;
@synthesize detailsString;


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.title = @"Details";
	
	CGRect frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
	CGRect systemTextDetailsViewFrame = CGRectMake(5, 0, self.view.frame.size.width - 10, self.view.frame.size.height - 10);
	
	UIView *viewContainer = [[UIView alloc] initWithFrame:frame];
	systemTextDetailsView = [[UIView alloc] initWithFrame:systemTextDetailsViewFrame];
	
	NSString *tempString;
	//tempString = @"<p>Harvard Shuttle Services is pleased to announce that the <font color=\"#800000\"><strong>ShuttleTracker &#160;iPhone App <\/strong><\/font>is now available in the iTunes App Store (link&#160;<a title=\"http:\/\/itunes.apple.com\/us\/app\/transloc-transit-visualization\/id367023550?mt=8\" target=\"_blank\" href=\"http:\/\/itunes.apple.com\/us\/app\/transloc-transit-visualization\/id367023550?mt=8\">here<\/a>). &#160;This enhancement--<font color=\"#800000\"><strong>at no additional charge<\/strong>-- <\/font>allows faster loading of the map, viewing of multiple routes, and geolocation features. &#160;Please share this news with your friends and download it today for your iPhone or iPod Touch!&#160;&#160;<\/p><div><a href=\"http:\/\/itunes.apple.com\/us\/app\/transloc-transit-visualization\/id367023550?mt=8\">http:\/\/itunes.apple.com\/us\/app\/transloc-transit-visualization\/id367023550?mt=8<\/a><\/div><div><br \/>  &#160;<\/div>";
	
	tempString = self.detailsString;				   
		
	viewContainer.backgroundColor = [UIColor whiteColor];
	[self.view addSubview:viewContainer];
	
}



- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end
