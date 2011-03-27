//
//  ContentTableViewController.h
//  Universitas
//
//  Created by Muhammad J Amjad on 3/26/11.
//  Copyright 2011 ModoLabs Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KGORequestManager.h"
#import "ContentWebView.h"


@interface ContentTableViewController : UITableViewController <KGORequestDelegate> {
	
    int numberOfFeeds;
    NSMutableDictionary * listOfFeeds;
    
    ContentWebView * webViewController;
    
    UIView * loadingView;
    UIActivityIndicatorView * loadingIndicator;
    
    UIWebView * singleFeedView;
    
    NSString * moduleTag;
    
}

@property (nonatomic, retain) NSString * moduleTag;
@property (nonatomic, retain) KGORequest *request;
@property (nonatomic, retain) ContentWebView * webViewController;
@property (nonatomic, retain) UIView * loadingView;
@property (nonatomic, retain) UIActivityIndicatorView * loadingIndicator;
@property (nonatomic, retain) UIWebView * singleFeedView;

- (id)initWithStyle:(UITableViewStyle)style moduleTag:(NSString *) tag;

- (void) addLoadingView;
- (void) removeLoadingView; 
- (void) showSingleFeedWebView: (NSString *) titleString htmlString: (NSString *) htmlStringText;

@end

