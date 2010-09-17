/****************************************************************
 *
 *  Copyright 2010 The President and Fellows of Harvard College
 *  Copyright 2010 Modo Labs Inc.
 *
 *****************************************************************/

#import <UIKit/UIKit.h>

@class ShuttlesTabViewControl;

@protocol TabViewControlDelegate<NSObject>

-(void) tabControl:(ShuttlesTabViewControl*)control changedToIndex:(int)tabIndex tabText:(NSString*)tabText;

@end

@interface ShuttlesTabViewControl : UIControl {
	
	NSArray* _tabs;
	
	int _selectedTab;
	
	int _pressedTab;
	
	UIFont* _tabFont;
	
	id<TabViewControlDelegate> _delegate;
}

@property (nonatomic, retain) NSArray* tabs;
@property int selectedTab;
@property (nonatomic, assign) id<TabViewControlDelegate> delegate;


// adds a tab and returns the index of that tab
-(int) addTab:(NSString*) tabName;




@end
