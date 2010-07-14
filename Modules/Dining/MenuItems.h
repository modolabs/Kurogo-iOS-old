//
//  MenuItems.h
//  diningTemp
//
//  Created by Muhammad Amjad on 6/29/10.
//  Copyright 2010 Modo Labs. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MenuItems : NSObject {

	NSArray *menuItems;
	NSDictionary *menuDetails;
}


-(void)getData:(id)JSONObject;
-(NSArray *)getItems;
-(NSDictionary *)getMenuDetails;

@end
