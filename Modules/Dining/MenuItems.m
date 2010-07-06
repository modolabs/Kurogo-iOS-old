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
	
	NSMutableArray *List = [[NSMutableArray alloc] init];
	NSMutableArray *List1 = [[NSMutableArray alloc] init];
	NSMutableDictionary *ListDictionary = [[NSMutableDictionary alloc] init];
	
	int len = [allItems count];
	int i;
	for (i=0; i<len; i++) {
		
		NSMutableDictionary *tempDict = [allItems objectAtIndex:i];
		NSString *key;
		
		key = (NSString *) [[tempDict objectForKey:@"category"] description];
		
		NSMutableArray * temp;
		
		temp = [ListDictionary objectForKey:key];
		
		if (temp == nil)
		{
			temp = [[NSMutableArray alloc] init];
			[List addObject:key];
			
		}
		
		else {
			[ListDictionary removeObjectForKey:key];
		}
		
		[temp addObject:tempDict];
		[ListDictionary setValue:temp forKey:key];
		
	}
	
	// NOTE: The order is very important here.
	// Find a more efficient way of doing this.
	
	if ([List containsObject:@"BREAKFAST ENTREES"]) 
		[List1 addObject:@"BREAKFAST ENTREES"];

	if ([List containsObject:@"TODAY'S SOUP"]) 
		[List1 addObject:@"TODAY'S SOUP"];
	
	if ([List containsObject:@"BRUNCH"]) 
		[List1 addObject:@"BRUNCH"];
	
	if ([List containsObject:@"ENTREES"]) 
		[List1 addObject:@"ENTREES"];
	
	if ([List containsObject:@"ACCOMPANIMENTS"]) 
		[List1 addObject:@"ACCOMPANIMENTS"];
	
	if ([List containsObject:@"DESSERTS"]) 
		[List1 addObject:@"DESSERTS"];
	
	if ([List containsObject:@"PASTA ALA CARTE"]) 
		[List1 addObject:@"PASTA ALA CARTE"];

	if ([List containsObject:@"VEGETABLES"]) 
		[List1 addObject:@"VEGETABLES"];
	
	if ([List containsObject:@"STARCH & POTATOES"]) 
		[List1 addObject:@"STARCH & POTATOES"];
	
	// Insert all other Categories	
	for (int j = 0; j < [List count]; j++)
	{
		NSString *item = [List objectAtIndex:j];
		
		if (![item isEqualToString:@"BREAKFAST ENTREES"] &&
			![item isEqualToString:@"TODAY'S SOUP"] &&
			![item isEqualToString:@"BRUNCH"] &&
			![item isEqualToString:@"ENTREES"] &&
			![item isEqualToString:@"ACCOMPANIMENTS"] &&
			![item isEqualToString:@"DESSERTS"] &&
			![item isEqualToString:@"PASTA ALA CARTE"] &&
			![item isEqualToString:@"VEGETABLES"] &&
			![item isEqualToString:@"STARCH & POTATOES"])
		{	
			[List1 addObject:[List objectAtIndex:j]];
		}
	}
	menuItems = List1;
	menuDetails = ListDictionary;
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
