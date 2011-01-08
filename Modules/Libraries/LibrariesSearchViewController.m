//
//  LibrariesSearchViewController.m
//  Harvard Mobile
//
//  Created by Muhammad J Amjad on 11/23/10.
//  Copyright 2010 ModoLabs Inc. All rights reserved.
//

#import "LibrariesSearchViewController.h"
#import "UITableView+MITUIAdditions.h"
#import "MITUIConstants.h"
#import "MITSearchDisplayController.h"
#import "LibrariesMultiLineCell.h"
#import "MITLoadingActivityView.h"
#import "LibItemDetailViewController.h"
#import "LibraryItem.h"
#import "CoreDataManager.h"
#import "LibraryAdvancedSearch.h"

@class LibrariesMultiLineCell;

@implementation LibrariesSearchViewController

@synthesize lastResults;
@synthesize activeMode;

@synthesize searchTerms, searchController;
@synthesize keywordText, titleText, authorText, englishOnlySwitch;
@synthesize formatIndex, locationIndex;
@synthesize searchBar = theSearchBar;
@synthesize tableView = _tableView;

- (BOOL) isSearchResultsVisible {
	return hasSearchInitiated && activeMode;
}

- (id) initWithViewController: (LibrariesMainViewController *)controller{
	if(self = [super init]) {
		activeMode = NO;
		viewController = controller;
		
		hasSearchInitiated = NO;
		actualCount = 0;
        formatIndex = 0;
        locationIndex = 0;
        
        keywordText = nil;
        titleText = nil;
        authorText = nil;
        englishOnlySwitch = false;
        
		self.lastResults = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (void) dealloc {
	[_advancedSearchButton release];

	[searchController release];

	self.tableView = nil;
    
    self.searchTerms = nil;
    self.keywordText = nil;
    self.titleText = nil;
    self.authorText = nil;
    self.searchBar = nil;
    self.lastResults = nil;
    
    viewController = nil; // this is set during -init and is never retained.  better to get rid of this ivar when we find another way to set the search terms.
    
	[super dealloc];
}

-(void) viewDidUnload{
	self.lastResults = nil;
	[_advancedSearchButton release];
    _advancedSearchButton = nil;
	[searchController release];
    searchController = nil;
    self.searchBar = nil;
	
	self.tableView = nil;

	[super viewDidUnload];
}


-(void) viewDidLoad {
    
    self.navigationItem.title = @"Search Results";
	
	if (nil == _advancedSearchButton) {
        UIImage *buttonImage = [[UIImage imageNamed:@"global/subheadbar_button"] stretchableImageWithLeftCapWidth:10 topCapHeight:0];
        NSString *buttonText = @"Refine";
        UIFont *buttonFont = [UIFont fontWithName:BOLD_FONT size:13];
        CGSize textSize = [buttonText sizeWithFont:buttonFont];
        CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
        
		_advancedSearchButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
		_advancedSearchButton.frame = CGRectMake(0, 0, textSize.width + 22, buttonImage.size.height);
		_advancedSearchButton.center = CGPointMake(appFrame.size.width - (_advancedSearchButton.frame.size.width / 2) - 2, (_advancedSearchButton.frame.size.height / 2) + 1);
        
		[_advancedSearchButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
		[_advancedSearchButton setBackgroundImage:[UIImage imageNamed:@"global/subheadbar_button_pressed"] forState:UIControlStateHighlighted];
        
        _advancedSearchButton.titleLabel.text = buttonText;
        _advancedSearchButton.titleLabel.font = buttonFont;
        _advancedSearchButton.titleLabel.textColor = [UIColor whiteColor];
        [_advancedSearchButton setTitle: buttonText forState: UIControlStateNormal];
        
        [_advancedSearchButton addTarget:self action:@selector(advancedSearchButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
	}
	
	if (nil == theSearchBar) {
        CGRect frame = CGRectMake(0.0f, 0.0f, self.view.frame.size.width - _advancedSearchButton.frame.size.width, NAVIGATION_BAR_HEIGHT);
        NSLog(@"%@", [_advancedSearchButton description]);
		theSearchBar = [[ModoSearchBar alloc] initWithFrame:frame];
    }
	
	theSearchBar.tintColor = SEARCH_BAR_TINT_COLOR;
	theSearchBar.placeholder = @"HOLLIS keyword search";
	theSearchBar.showsBookmarkButton = NO; // use custom bookmark button
	if ([self.searchTerms length] > 0)
		theSearchBar.text = self.searchTerms;
	
	if (nil == searchController)
		self.searchController = [[[MITSearchDisplayController alloc] initWithSearchBar:theSearchBar contentsController:self] autorelease];
	
	self.searchController.delegate = self;
	self.searchController.searchResultsDelegate = self;
	self.searchController.searchResultsDataSource = self;
	
	if (nil != viewController)
		theSearchBar.text = viewController.searchTerms;
	
    [self.view addSubview:theSearchBar];
	[self.view addSubview:_advancedSearchButton];
	
    CGRect frame = CGRectMake(0.0, theSearchBar.frame.size.height,
                              self.view.frame.size.width,
                              self.view.frame.size.height - theSearchBar.frame.size.height);
	
	self.tableView = [[[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain] autorelease];
	
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _tableView.delegate = self;
    _tableView.dataSource = self;
	
	[self.view addSubview:_tableView];
}


#pragma mark User Interaction

-(void) advancedSearchButtonClicked: (id) sender{
    NSLog(@"Passing format %d and location %d", formatIndex, locationIndex);
    
	LibraryAdvancedSearch * vc = [[LibraryAdvancedSearch alloc] initWithNibName:@"LibraryAdvancedSearch" 
																		 bundle:nil
																	   keywords:(keywordText && [keywordText length]) ? self.keywordText : self.searchTerms
                                                                          title:titleText ? self.titleText : @""
                                                                         author:authorText ? self.authorText : @""
                                                              englishOnlySwitch:self.englishOnlySwitch            
                                                                    formatIndex:formatIndex
                                                                  locationIndex:locationIndex];
	
	vc.title = @"Advanced Search";
    [self.navigationController pushViewController:vc animated:YES];
	[vc release];
}



#pragma mark UITableViewDataSource methods

- (NSInteger) tableView: (UITableView *)tableView numberOfRowsInSection: (NSInteger)section {
	return [self.lastResults count];
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	LibrariesMultiLineCell *cell = (LibrariesMultiLineCell *)[aTableView dequeueReusableCellWithIdentifier:@"HollisSearch"];
	if(cell == nil) {
		cell = [[[LibrariesMultiLineCell alloc] initWithStyle:UITableViewCellStyleSubtitle 
										 reuseIdentifier:@"HollisSearch"] autorelease];
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
	}
	
	LibraryItem * libItem = (LibraryItem *)[self.lastResults objectForKey:[NSString stringWithFormat:@"%d", indexPath.row+1]];
	NSString *cellText = nil;
	NSString *detailText = nil;
	
	if (nil != libItem) {
		cellText = [NSString stringWithFormat:@"%d. %@", indexPath.row + 1, libItem.title];
		
		if (([libItem.year length] == 0) && ([libItem.author length] ==0))
			detailText = @"       ";
		
		else if (([libItem.year length] == 0) && ([libItem.author length] > 0))
			detailText = [NSString stringWithFormat:@"%@", libItem.author];
		
		else if (([libItem.year length] > 0) && ([libItem.author length] == 0))
			detailText = [NSString stringWithFormat:@"%@", libItem.year];
		
		else if (([libItem.year length] > 0) && ([libItem.author length] > 0))
			detailText = [NSString stringWithFormat:@"%@ | %@", libItem.year, libItem.author];
		
		else {
			detailText = [NSString stringWithFormat:@"       "];
		}
	}
	
	cell.textLabelNumberOfLines = 2;
	cell.textLabel.text = cellText;
	cell.textLabel.lineBreakMode = UILineBreakModeTailTruncation;
	cell.textLabel.font = [UIFont fontWithName:STANDARD_FONT size:STANDARD_CONTENT_FONT_SIZE];

	cell.detailTextLabel.text = detailText;
	cell.detailTextLabel.textColor = [UIColor colorWithHexString:@"#554C41"];
	cell.detailTextLabel.font = [UIFont fontWithName:STANDARD_FONT size:13];
	cell.detailTextLabel.lineBreakMode = UILineBreakModeTailTruncation;

	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	cell.selectionStyle = UITableViewCellSelectionStyleGray;
	
	NSString * imageString;
	
	if (nil != libItem.formatDetail) {
		
		if ([libItem.formatDetail isEqualToString:@"Recording"])
			imageString = @"soundrecording.png";
		
		else if ([libItem.formatDetail isEqualToString:@"Image"])
			imageString = @"image.png";
		
		else if ([libItem.formatDetail isEqualToString:@"Map"])
			imageString = @"map.png";
		
		else if ([libItem.formatDetail isEqualToString:@"Journal / Serial"])
			imageString = @"journal.png";
		
		else if ([libItem.formatDetail isEqualToString:@"Movie"])
			imageString = @"video.png";
		
		else {
			imageString = @"book.png";
		}
		UIImage *image = [UIImage imageNamed:imageString];
		cell.imageView.image = image;
	}
	return cell;
}

- (CGFloat) tableView: (UITableView *)tableView heightForRowAtIndexPath: (NSIndexPath *)indexPath {
	//return [StellarClassTableCell cellHeightForTableView:tableView class:[self.lastResults objectAtIndex:indexPath.row]];
	
	UITableViewCellAccessoryType accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	LibraryItem * libItem = (LibraryItem *)[self.lastResults objectForKey:[NSString stringWithFormat:@"%d", indexPath.row+1]];
	NSString *cellText = nil;
	NSString *detailText = nil;
	
	if (nil != libItem) {
		cellText = [NSString stringWithFormat:@"%d. %@", indexPath.row + 1, libItem.title];
		
		if (([libItem.year length] == 0) && ([libItem.author length] ==0))
			detailText = @"         ";
		
		else if (([libItem.year length] == 0) && ([libItem.author length] > 0))
			detailText = [NSString stringWithFormat:@"%@", libItem.author];
		
		else if (([libItem.year length] > 0) && ([libItem.author length] == 0))
			detailText = [NSString stringWithFormat:@"%@", libItem.year];
			
		else if (([libItem.year length] > 0) && ([libItem.author length] > 0))
			detailText = [NSString stringWithFormat:@"%@ | %@", libItem.year, libItem.author];
		
		else {
			detailText = [NSString stringWithFormat:@"      "];
		}

	}

	UIFont *detailFont = [UIFont fontWithName:STANDARD_FONT size:13];
	
	return [LibrariesMultiLineCell heightForCellWithStyle:UITableViewCellStyleSubtitle
											 tableView:tableView 
												  text:cellText
										  maxTextLines:2
											detailText:detailText
										maxDetailLines:10
												  font:[UIFont fontWithName:STANDARD_FONT size:STANDARD_CONTENT_FONT_SIZE]
											detailFont:detailFont
										 accessoryType:accessoryType
											 cellImage:YES];
}

- (NSInteger) numberOfSectionsInTableView: (UITableView *)tableView {
	return 1;
}

- (NSString *) tableView: (UITableView *)tableView titleForHeaderInSection: (NSInteger)section {
	if([lastResults count]) {
		if (actualCount > [lastResults count])
			return [NSString stringWithFormat:@"Displaying %i of %d", [self.lastResults count], actualCount];
		
		return [NSString stringWithFormat:@"%i matches found", [self.lastResults count]];
	}
	return nil;
}

- (UIView *) tableView: (UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	NSString *headerTitle = nil;
	
	if([lastResults count]) {
		if (actualCount > [lastResults count])
			headerTitle =  [NSString stringWithFormat:@"Displaying %i of %d", [self.lastResults count], actualCount];
		else
			headerTitle = [NSString stringWithFormat:@"%i matches found", [self.lastResults count]];
		
		return [UITableView ungroupedSectionHeaderWithTitle:headerTitle];
	}
	return nil;
}

- (CGFloat)tableView: (UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return UNGROUPED_SECTION_HEADER_HEIGHT;
}

#pragma mark UITableViewDelegate methods

- (void) tableView: (UITableView *)tableView didSelectRowAtIndexPath: (NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
	
	LibraryItem * libItem = (LibraryItem *)[self.lastResults objectForKey:[NSString stringWithFormat:@"%d", indexPath.row+1]];
	
	BOOL displayImage = NO;
	
	if ([libItem.formatDetail isEqualToString:@"Image"])
		displayImage = YES;
	
	LibItemDetailViewController *vc = [[LibItemDetailViewController alloc]  initWithStyle:UITableViewStyleGrouped
																				libraryItem:libItem
																				itemArray:self.lastResults
																		  currentItemIdex:indexPath.row
																			 imageDisplay:displayImage];
    
    [self.navigationController pushViewController:vc animated:YES];	

	[vc release];
	
}


- (void)setupSearchController {
    if (!self.searchController) {
        self.searchController = [[MITSearchDisplayController alloc] initWithSearchBar:theSearchBar contentsController:self];
        self.searchController.delegate = self;
    }
}

- (void)hideToolBar {
    [UIView beginAnimations:@"searching" context:nil];
    [UIView setAnimationDuration:0.4];
    _advancedSearchButton.alpha = 0.0;
	theSearchBar.frame = CGRectMake(0, 0, self.view.frame.size.width, NAVIGATION_BAR_HEIGHT);
	// _toolBar.alpha = 0.0;
    [UIView commitAnimations];
}

- (void)restoreToolBar {
    [theSearchBar setShowsCancelButton:NO animated:YES];
    [UIView beginAnimations:@"searching" context:nil];
    [UIView setAnimationDuration:0.4];
	
	theSearchBar.frame = CGRectMake(0.0f, 0.0f, self.view.frame.size.width - _advancedSearchButton.frame.size.width, NAVIGATION_BAR_HEIGHT);
	_advancedSearchButton.alpha = 1.0;
	
    [UIView commitAnimations];
}


#pragma mark -
#pragma mark Search methods

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
	// if they cancelled while waiting for loading
	if (requestWasDispatched) {
	}
	[self restoreToolBar];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{	
	self.searchTerms = searchBar.text;
	
	JSONAPIRequest *api = [JSONAPIRequest requestWithJSONAPIDelegate:self];
	requestWasDispatched = [api requestObjectFromModule:@"libraries"
                                                command:@"search"
                                             parameters:[NSDictionary dictionaryWithObjectsAndKeys:self.searchTerms, @"keywords", nil]];
	
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
	[self setupSearchController]; // in case we got rid of it from a memory warning
    [self hideToolBar];
}

/*
- (void)presentSearchResults:(NSArray *)theSearchResults {

}
*/

#pragma mark -
#pragma mark Connection methods

- (void)cleanUpConnection {
	requestWasDispatched = NO;
}

- (void)request:(JSONAPIRequest *)request jsonLoaded:(id)result {
    [self cleanUpConnection];
	
    if (result && [result isKindOfClass:[NSDictionary class]]) {
        DLog(@"%@", [result description]);
        
        NSNumber *total = [(NSDictionary *)result objectForKey:@"total"];
        if (total) {
            actualCount = [total integerValue];
        }
        NSString *query = [(NSDictionary *)result objectForKey:@"q"];

        self.searchTerms = query;
        self.searchBar.text = query;
        
        NSArray *items = [(NSDictionary *)result objectForKey:@"items"];
        
        [self.searchBar addDropShadow];
        
        if ([items count] == 0) {
            [self handleWarningMessage:NSLocalizedString(@"No results found", nil) title:nil];
            [self restoreToolBar];
            [theSearchBar becomeFirstResponder];
            return;
        }
        else {
            self.lastResults = [[NSMutableDictionary alloc] init];
        }
        
        for (NSDictionary * libraryDictionary in items) {
            
            NSString * title = [libraryDictionary objectForKey:@"title"];
            NSString *author = [libraryDictionary objectForKey:@"creator"];
            
            NSString *year = [libraryDictionary objectForKey:@"date"];
            
            NSString * index = [libraryDictionary objectForKey:@"index"];
            NSString *itemId = [libraryDictionary objectForKey:@"itemId"];
            NSString * edition = [libraryDictionary objectForKey:@"edition"];
            
            NSDictionary * format = [libraryDictionary objectForKey:@"format"];
            
            NSString *typeDetail = [format objectForKey:@"typeDetail"];
            NSString * formatDetail = [format objectForKey:@"formatDetail"];
            
            LibraryItem *alreadyInDB = [[LibraryDataManager sharedManager] libraryItemWithID:itemId];
            
            alreadyInDB.title = title;
            alreadyInDB.author = author;
            alreadyInDB.year = year;
            alreadyInDB.edition = edition;
            alreadyInDB.typeDetail = typeDetail;
            alreadyInDB.formatDetail = formatDetail;
            
            [CoreDataManager saveData];
            
            [self.lastResults setObject:alreadyInDB forKey:index];
        }
        [_tableView reloadData];
        
        if ([items count] > 0)
            [_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
        
	}
	
	[searchController hideSearchOverlayAnimated:YES];
	[self restoreToolBar];
}

- (BOOL)request:(JSONAPIRequest *)request shouldDisplayAlertForError:(NSError *)error
{
    return YES;
}

- (void)request:(JSONAPIRequest *)request handleConnectionError:(NSError *)error
{
	[self cleanUpConnection];
}


- (void)handleWarningMessage:(NSString *)message title:(NSString *)theTitle {
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:theTitle 
													message:message
												   delegate:self
										  cancelButtonTitle:@"OK" 
										  otherButtonTitles:nil]; 
	[alert show];
	[alert release];
}



@end
