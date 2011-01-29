//
//  CategoriesTableViewController.h
//  MIT Mobile
//
//  Created by Craig Spitzkoff on 5/20/10.
//  Copyright 2010 Raizlabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JSONAPIRequest.h"
#import "MITLoadingActivityView.h"

@class MapSelectionController;

@interface CategoriesTableViewController : UITableViewController <JSONAPIDelegate> {
	MapSelectionController *_mapSelectionController;
	
	NSMutableArray *_itemsInTable;
	NSString *_headerText;
    NSString *_category;
    UIView *_headerView;
	
	MITLoadingActivityView* _loadingView;
}

@property (nonatomic, assign) MapSelectionController* mapSelectionController;
@property (nonatomic, retain) NSMutableArray* itemsInTable;
@property (nonatomic, retain) NSString* headerText;
@property (nonatomic, retain) NSString *category;

-(void) executeServerCategoryRequest;

@end
