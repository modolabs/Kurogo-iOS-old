//
//  MenuItems.m
//  diningTemp
//
//  Created by Muhammad Amjad on 6/29/10.
//  Copyright 2010 Modo Labs. All rights reserved.
//

#import "MenuItems.h"


@implementation MenuItems

-(void)getData:(id)JSONObject
{
	NSArray *allItems;
	allItems = (NSArray *) JSONObject;
	
	NSMutableArray *List = [NSMutableArray array];
	NSMutableArray *List1 = [NSMutableArray array];
	NSMutableDictionary *ListDictionary = [NSMutableDictionary dictionary];
	
	int len = [allItems count];
	int i;
	for (i=0; i<len; i++) {
		
		NSMutableDictionary *tempDict = [allItems objectAtIndex:i];
		NSString *key;
		
		key = (NSString *) [[tempDict objectForKey:@"category"] description];
		
		NSString *servingSize = (NSString *) [[tempDict objectForKey:@"servingSize"] description];
		NSString *servingUnit = (NSString *) [[tempDict objectForKey:@"servingUnit"] description];
		
		servingSize = [NSString stringWithFormat:@"%@ %@", servingSize, servingUnit];
		
		[tempDict removeObjectForKey:@"servingSize"];
		[tempDict removeObjectForKey:@"servingUnit"];
		[tempDict setValue:servingSize forKey:@"servingSize"];
		
		NSMutableArray * temp;
		
		temp = [ListDictionary objectForKey:key];
		
		if (temp == nil)
		{
			temp = [NSMutableArray array];
			[List addObject:key];
			
		}
		
		else {
			[ListDictionary removeObjectForKey:key];
		}
			
		if (![temp containsObject:tempDict])
			[temp addObject:tempDict];
		
		[ListDictionary setValue:temp forKey:key];
		
		
	}
	
	// NOTE: The order is very important here.
	// Find a more efficient way of doing this.
	
	if ([List containsObject:@"Breakfast Entrees"]) 
		[List1 addObject:@"Breakfast Entrees"];

	if ([List containsObject:@"Today's Soup"]) 
		[List1 addObject:@"Today's Soup"];
	
	if ([List containsObject:@"Brunch"]) 
		[List1 addObject:@"Brunch"];
	
	if ([List containsObject:@"Entrees"]) 
		[List1 addObject:@"Entrees"];
	
	if ([List containsObject:@"Accompaniments"]) 
		[List1 addObject:@"Accompaniments"];
	
	if ([List containsObject:@"Desserts"]) 
		[List1 addObject:@"Desserts"];
	
	if ([List containsObject:@"Pasta a la Carte"]) 
		[List1 addObject:@"Pasta a la Carte"];

	if ([List containsObject:@"Vegetables"]) 
		[List1 addObject:@"Vegetables"];
	
	if ([List containsObject:@"Starch & Potatoes"]) 
		[List1 addObject:@"Starch & Potatoes"];
	
	// Insert all other Categories	
	for (int j = 0; j < [List count]; j++)
	{
		NSString *item = [List objectAtIndex:j];
		
		if (![item isEqualToString:@"Breakfast Entrees"] &&
			![item isEqualToString:@"Today's Soup"] &&
			![item isEqualToString:@"Brunch"] &&
			![item isEqualToString:@"Entrees"] &&
			![item isEqualToString:@"Accompaniments"] &&
			![item isEqualToString:@"Desserts"] &&
			![item isEqualToString:@"Pasta a la Carte"] &&
			![item isEqualToString:@"Vegetables"] &&
			![item isEqualToString:@"Starch & Potatoes"])
		{	

			[List1 addObject:[List objectAtIndex:j]];
		}
	}
	menuItems = [List1 retain];
	menuDetails = [ListDictionary retain];
}

// This methods needs the "getData:" methods to have been called first
-(NSArray *)getItems
{
	return menuItems;
}

// This methods needs the "getData:" methods to have been called first
-(NSDictionary *)getMenuDetails
{
	return menuDetails;
}

@end
