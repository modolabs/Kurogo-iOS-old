/****************************************************************
 *
 *  Copyright 2010 The President and Fellows of Harvard College
 *  Copyright 2010 Modo Labs Inc.
 *
 *****************************************************************/
#import <UIKit/UIKit.h>


@interface MenuDetailsController : UITableViewController {
	
	NSArray *itemCategory;
	NSArray *itemDetails;
}

@property (nonatomic, retain) NSArray *itemDetails;
@property (nonatomic, retain) NSArray *itemCategory;

-(void)setDetails:(NSArray *)itemDetails setItemCategory: (NSArray *) itemCat;

@end
