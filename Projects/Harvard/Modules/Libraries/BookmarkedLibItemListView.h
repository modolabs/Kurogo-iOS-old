//
//  BookmarkedLibItemListView.h
//  Harvard Mobile
//
//  Created by Muhammad J Amjad on 12/7/10.
//  Copyright 2010 ModoLabs Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NavScrollerView.h"
#import "JSONAPIRequest.h"
#import "LibraryItem.h"
#import "JSONAPIRequest.h"


@interface BookmarkedLibItemListView : UITableViewController {
	UIBarButtonItem * _viewTypeButton;
	
	UISegmentedControl *segmentedControl;
	
	JSONAPIRequest * api;
	
	NSArray * bookmarkedItems;
	NSMutableDictionary * bookmarkedItemsDictionaryWithIndexing;

	
}

@end
