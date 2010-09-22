//
//  AnnouncementsTableViewController.h
//  Harvard Mobile
//
//  Created by Muhammad Amjad on 9/22/10.
//  Copyright 2010 Modo Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AnnouncementsTableViewController : UITableViewController {

	NSMutableArray * announcements;
	UINavigationController *parentViewController;
}

@property (nonatomic, retain) UINavigationController *parentViewController;
@property (nonatomic, retain) NSMutableArray * announcements;

@end
