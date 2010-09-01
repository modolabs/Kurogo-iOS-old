/****************************************************************
 *
 *  Copyright 2010 The President and Fellows of Harvard College
 *  Copyright 2010 Modo Labs Inc.
 *
 *****************************************************************/

#import <Foundation/Foundation.h>


@interface MenuItems : NSObject {

	NSArray *menuItems;
	NSDictionary *menuDetails;
}


-(void)getData:(id)JSONObject;
-(NSArray *)getItems;
-(NSDictionary *)getMenuDetails;

@end
