//
//  ContentWebView.m
//  Universitas
//
//  Created by Muhammad J Amjad on 3/26/11.
//  Copyright 2011 ModoLabs Inc. All rights reserved.
//

#import "ContentWebView.h"


@implementation ContentWebView

- (void)dealloc
{
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}
*/

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}



#pragma mark KGORequestDelegate

- (void)requestWillTerminate:(KGORequest *)request {
}

- (void)request:(KGORequest *)request didReceiveResult:(id)result {
    
    NSLog(@"%@", [result description]);
    
    NSDictionary * resultDict = [result objectForKey:@"feedData"];
    
    NSString * htmlStringText = [resultDict objectForKey:@"contentBody"]; 
    [super setLoadHtmlString: htmlStringText];
    
    NSString * titleString = [resultDict objectForKey:@"title"];
    self.title = titleString;
    
    NSLog(@"%@", htmlStringText);
    
}


@end
