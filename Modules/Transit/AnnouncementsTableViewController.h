//
//  AnnouncementsTableViewController.h
//  Harvard Mobile
//
//  Created by Muhammad Amjad on 9/22/10.
//  Copyright 2010 Modo Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MultiLineTableViewCell.h"

@interface AnnouncementsTableViewController : UITableViewController {

	NSMutableArray * harvardAnnouncements;
	NSMutableArray * mascoAnnouncements;
	UINavigationController *parentViewController;
}

@property (nonatomic, retain) UINavigationController *parentViewController;
@property (nonatomic, retain) NSMutableArray * harvardAnnouncements;
@property (nonatomic, retain) NSMutableArray * mascoAnnouncements;

@end


@interface AnnouncementsTableViewHeaderCell : MultiLineTableViewCell
{
	CGFloat height;
}

@property CGFloat height;

@end