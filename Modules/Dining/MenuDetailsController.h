//
//  BreakfastDetailsController.h
//  diningTemp
//
//  Created by Muhammad Amjad on 6/23/10.
//  Copyright 2010 Modo Labs. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface MenuDetailsController : UITableViewController {
	
	NSArray *itemCategory;
	NSArray *itemDetails;
}

@property (nonatomic, retain) NSArray *itemDetails;
@property (nonatomic, retain) NSArray *itemCategory;

-(void)setDetails:(NSArray *)itemDetails setItemCategory: (NSArray *) itemCat;

@end
