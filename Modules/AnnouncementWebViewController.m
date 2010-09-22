    //
//  AnnouncementWebViewController.m
//  Harvard Mobile
//
//  Created by Muhammad Amjad on 9/22/10.
//  Copyright 2010 Modo Labs. All rights reserved.
//

#import "AnnouncementWebViewController.h"


@implementation AnnouncementWebViewController

@synthesize htmlStringToDisplay;
@synthesize titleString;

- (NSString *)htmlStringFromString:(NSString *)source {
	NSURL *baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath] isDirectory:YES];
	NSURL *fileURL = [NSURL URLWithString:@"events/events_template.html" relativeToURL:baseURL];
	NSError *error;
	NSMutableString *target = [NSMutableString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:&error];
	if (!target) {
		DLog(@"Failed to load template at %@. %@", fileURL, [error userInfo]);
	}
	[target replaceOccurrencesOfStrings:[NSArray arrayWithObject:@"__BODY__"] 
							withStrings:[NSArray arrayWithObject:source] 
								options:NSLiteralSearch];
	return target;
}




// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.title = @"Detail";
	
	CGRect frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
	CGRect webViewFrame = CGRectMake(5, 0, self.view.frame.size.width - 10, self.view.frame.size.height - 10);
	
	UIView *webViewContainer = [[UIView alloc] initWithFrame:frame];
	webView = [[UIWebView alloc] initWithFrame:webViewFrame];
	
	NSString *tempString;
	//tempString = @"<p>Harvard Shuttle Services is pleased to announce that the <font color=\"#800000\"><strong>ShuttleTracker &#160;iPhone App <\/strong><\/font>is now available in the iTunes App Store (link&#160;<a title=\"http:\/\/itunes.apple.com\/us\/app\/transloc-transit-visualization\/id367023550?mt=8\" target=\"_blank\" href=\"http:\/\/itunes.apple.com\/us\/app\/transloc-transit-visualization\/id367023550?mt=8\">here<\/a>). &#160;This enhancement--<font color=\"#800000\"><strong>at no additional charge<\/strong>-- <\/font>allows faster loading of the map, viewing of multiple routes, and geolocation features. &#160;Please share this news with your friends and download it today for your iPhone or iPod Touch!&#160;&#160;<\/p><div><a href=\"http:\/\/itunes.apple.com\/us\/app\/transloc-transit-visualization\/id367023550?mt=8\">http:\/\/itunes.apple.com\/us\/app\/transloc-transit-visualization\/id367023550?mt=8<\/a><\/div><div><br \/>  &#160;<\/div>";

	tempString = self.htmlStringToDisplay;
	NSString *descriptionString = [[NSString alloc] initWithFormat:@"<h3><b>%@ </h3> </b>", self.titleString];
								   
	descriptionString = [descriptionString stringByAppendingFormat:@"%@", tempString];						   
	 
		 
	[webView loadHTMLString:[self htmlStringFromString:descriptionString] baseURL:nil];
	[webViewContainer addSubview: webView];
	webViewContainer.backgroundColor = [UIColor whiteColor];
	[self.view addSubview:webViewContainer];
	
}


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

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
