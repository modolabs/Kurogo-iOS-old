//
//  ShuttlesMainViewController.h
//  Harvard Mobile
//
//  Created by Muhammad Amjad on 9/17/10.
//  Copyright 2010 Modo Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ShuttlesTabViewControl.h"
#import "ShuttleRoutes.h"
#import "JSONAPIRequest.h"
#import "AnnouncementsTableViewController.h"
#import "ContactsTableViewController.h"

@class AnnouncementsTableViewController;
@class ContactsTableViewController;
@class ShuttleRoutes;


@interface ShuttlesMainViewController : UIViewController<TabViewControlDelegate, JSONAPIDelegate> {
	
	ShuttleRoutes *shuttleRoutesTableView; 
	
	IBOutlet UIView *tabViewContainer;
	
	NSMutableArray *_tabViewsArray;
	
	IBOutlet ShuttlesTabViewControl *tabView;
	
	AnnouncementsTableViewController * announcementsTab;
	
	IBOutlet UIImageView *newAnnouncement;
	
	ContactsTableViewController * contactsTab;
	
	UIView * loadingIndicator;

}

@property (nonatomic, retain) ShuttlesTabViewControl *tabView;

-(void)couldNotConnectToServer;
- (void)addLoadingIndicator;
-(void)removeLoadingIndicator;
@end
