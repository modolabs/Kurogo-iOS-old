//
//  CoursesSearchTableViewController.h
//  MIT Mobile
//
//  Created by Muhammad Amjad on 8/11/10.
//  Copyright 2010 Modo Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MultiLineTableViewCell.h"


@interface CoursesSearchTableViewController : UITableViewController {
	NSDictionary *groupToCourseCount;
}

-(void) setGroups: (NSDictionary *)groups;

@end
