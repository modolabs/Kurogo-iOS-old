//
//  HallDetailsTableViewController.h
//  MIT Mobile
//
//  Created by Muhammad Amjad on 7/20/10.
//  Copyright 2010 Modo Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MultiLineTableViewCell.h"

@interface HallDetailsTableViewController : UITableViewController {

	NSDictionary *itemDetails;
}

@property (nonatomic, retain) NSDictionary *itemDetails;

-(void)setDetails:(NSDictionary *)details;


@end
