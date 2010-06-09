//
//  RecentSearchesViewController.h
//  MIT Mobile
//
//  Created by Craig Spitzkoff on 5/18/10.
//  Copyright 2010 Raizlabs. All rights reserved.
//

#import <UIKit/UIKit.h>
@class MapSelectionController;

@interface RecentSearchesViewController : UITableViewController {

	MapSelectionController* _mapSelectionController;
	
	NSArray* _searches; 
}

-(id) initWithMapSelectionController:(MapSelectionController*)mapSelectionController;


@property (nonatomic, assign) MapSelectionController* mapSelectionController;

@end
