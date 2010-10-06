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
@synthesize detailsString = _detailsString;


- (void)loadView {
    [super loadView];
	//CGRect frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
	//CGRect systemTextDetailsViewFrame = CGRectMake(5, 0, self.view.frame.size.width - 10, self.view.frame.size.height - 10);
	//systemTextDetailsView = [[UIWebView alloc] initWithFrame:systemTextDetailsViewFrame];
    systemTextDetailsView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.title = @"Details";
	
	//UIView *viewContainer = [[UIView alloc] initWithFrame:frame];
	
	//tempString = @"<p>Harvard Shuttle Services is pleased to announce that the <font color=\"#800000\"><strong>ShuttleTracker &#160;iPhone App <\/strong><\/font>is now available in the iTunes App Store (link&#160;<a title=\"http:\/\/itunes.apple.com\/us\/app\/transloc-transit-visualization\/id367023550?mt=8\" target=\"_blank\" href=\"http:\/\/itunes.apple.com\/us\/app\/transloc-transit-visualization\/id367023550?mt=8\">here<\/a>). &#160;This enhancement--<font color=\"#800000\"><strong>at no additional charge<\/strong>-- <\/font>allows faster loading of the map, viewing of multiple routes, and geolocation features. &#160;Please share this news with your friends and download it today for your iPhone or iPod Touch!&#160;&#160;<\/p><div><a href=\"http:\/\/itunes.apple.com\/us\/app\/transloc-transit-visualization\/id367023550?mt=8\">http:\/\/itunes.apple.com\/us\/app\/transloc-transit-visualization\/id367023550?mt=8<\/a><\/div><div><br \/>  &#160;<\/div>";
	
	//tempString = self.detailsString;				   
		
	//viewContainer.backgroundColor = [UIColor whiteColor];
	//[self.view addSubview:viewContainer];
    [self.view addSubview:systemTextDetailsView];
    systemTextDetailsView.delegate = self;
    systemTextDetailsView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
}

- (NSString *)detailsString {
    return _detailsString;
}

- (void)setDetailsString:(NSString *)aString {
    if (aString != _detailsString) {
        [_detailsString release];
        _detailsString = [aString retain];
    }
    
    if (_detailsString) {
        NSString *htmlString = [NSString stringWithFormat:@"<html>"
                                "<head><style type=\"text/css\">"
                                "body {font-family:Helvetica;font-size:15px;color:#333;padding:10px}\n"
                                "a {color:#8C000B;text-decoration:none}\n"
                                "h2 {color:#1A1611;font-size:18px}\n"
                                "</style></head>"
                                "<body>%@</body>"
                                "</html>", _detailsString];
                                
        [systemTextDetailsView loadHTMLString:htmlString baseURL:nil];
    }
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
    self.detailsString = nil;
    self.titleString = nil;
    
    [super dealloc];
}

#pragma mark UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    // only allow webView to load whatever html we feed it (about:blank)
    if ([[[request URL] scheme] isEqualToString:@"about"])
        return YES;
    
    if ([[UIApplication sharedApplication] canOpenURL:[request URL]]) {
        [[UIApplication sharedApplication] openURL:[request URL]];
    }
    return NO;
}

@end
