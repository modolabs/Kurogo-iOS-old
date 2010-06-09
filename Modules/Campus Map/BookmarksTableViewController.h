//
//  BookmarksTableViewController.h
//  MIT Mobile
//
//  Created by Anna Callahan on 4/26/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CampusMapViewController;
@class MapSelectionController;

@interface BookmarksTableViewController : UITableViewController 
{	
	MapSelectionController* _mapSelectionController;
}

-(id) initWithMapSelectionController:(MapSelectionController*)mapSelectionController;


@property (nonatomic, assign) MapSelectionController* mapSelectionController;

@end
