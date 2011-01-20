//
//  LibraryAdvancedSearch.m
//  Harvard Mobile
//
//  Created by Muhammad J Amjad on 12/16/10.
//  Copyright 2010 ModoLabs Inc. All rights reserved.
//

#import "LibraryAdvancedSearch.h"
#import "CoreDataManager.h"
#import "LibrarySearchCode.h"
#import "Constants.h"
#import "LibrariesSearchViewController.h"
#import "LibraryDataManager.h"
#import "JSONAPIRequest.h"

@implementation LibraryAdvancedSearch
@synthesize keywords;
@synthesize titleKeywords;
@synthesize authorKeywords;
@synthesize format;
@synthesize formatDisclosure;
@synthesize location;
@synthesize locationDisclosure;
@synthesize englishSwitch;
@synthesize scrollView;

-(void) setupLayout{
	
    NSPredicate * matchAll = [NSPredicate predicateWithFormat:@"TRUEPREDICATE"];
    NSSortDescriptor *nameSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"sortOrder" ascending:YES] autorelease];
    NSArray *sortDescriptors = [NSArray arrayWithObject:nameSortDescriptor];

    if (![libraryArray count] || [libraryArray count] <= 1) {
        NSArray * libraryCodes = [CoreDataManager objectsForEntity:LibraryLocationCodeEntityName matchingPredicate:matchAll sortDescriptors:sortDescriptors];
        if (libraryCodes != nil) {
            libraryArray = [[NSMutableArray alloc] initWithArray:libraryCodes];
        }
        [libraryArray insertObject:@"Any" atIndex:0];
    }

    if (![formatArray count] || [formatArray count] <= 1) {
        NSArray * formatCodes = [CoreDataManager objectsForEntity:LibraryFormatCodeEntityName matchingPredicate:matchAll sortDescriptors:sortDescriptors];
        if (formatCodes != nil) {
            formatArray = [[NSMutableArray alloc] initWithArray:formatCodes];
        }
        [formatArray insertObject:@"Any" atIndex:0];
    }
    
    if (![pubdateArray count] || [pubdateArray count] <= 1) {
        NSArray * pubdateCodes = [CoreDataManager objectsForEntity:LibraryPubDateCodeEntityName matchingPredicate:matchAll sortDescriptors:sortDescriptors];
        if (pubdateCodes != nil) {
            pubdateArray = [[NSMutableArray alloc] initWithArray:pubdateCodes];
        }
        [pubdateArray insertObject:@"Any" atIndex:0];
    }
    
    // Data may have changed due to JSON response
    [locationPickerView reloadAllComponents];
    [formatPickerView reloadAllComponents];
    [pubdatePickerView reloadAllComponents];
	
	keywords.delegate = self;
	titleKeywords.delegate = self;
	authorKeywords.delegate = self;
	
	if (nil != keywordTextAtInitialization && [keywordTextAtInitialization length]) {
        DLog(@"Got keywords %@", keywordTextAtInitialization);
		self.keywords.text = keywordTextAtInitialization;
        [keywordTextAtInitialization release];
        keywordTextAtInitialization = nil;
	}
    
	if (nil != titleTextAtInitialization && [titleTextAtInitialization length]) {
        DLog(@"Got title %@", titleTextAtInitialization);
		self.titleKeywords.text = titleTextAtInitialization;
        [titleTextAtInitialization release];
        titleTextAtInitialization = nil;
	}
    
	if (nil != authorTextAtInitialization && [authorTextAtInitialization length]) {
        DLog(@"Got author %@", authorTextAtInitialization);
		self.authorKeywords.text = authorTextAtInitialization;
        [authorTextAtInitialization release];
        authorTextAtInitialization = nil;
	}
    
    if (englishOnlySwitchAtInitialization) {
        englishSwitch.selected = YES;
    }
    
    if (formatIndexAtInitialization > 0 && formatIndexAtInitialization < [formatArray count]) {
        DLog(@"Got format %d", formatIndexAtInitialization);
        [formatPickerView selectRow:formatIndexAtInitialization inComponent:0 animated:false]; 
        [self pickerView:formatPickerView didSelectRow:formatIndexAtInitialization inComponent:0];
        formatIndexAtInitialization = 0;
    }
    
    if (locationIndexAtInitialization > 0 && locationIndexAtInitialization < [libraryArray count]) {
        DLog(@"Got location %d", locationIndexAtInitialization);
        [locationPickerView selectRow:locationIndexAtInitialization inComponent:0 animated:false];
        [self pickerView:locationPickerView didSelectRow:locationIndexAtInitialization inComponent:0];
        locationIndexAtInitialization = 0;
    }
    
    if (pubdateIndexAtInitialization > 0 && pubdateIndexAtInitialization < [pubdateArray count]) {
        DLog(@"Got location %d", pubdateIndexAtInitialization);
        [pubdatePickerView selectRow:pubdateIndexAtInitialization inComponent:0 animated:false];
        [self pickerView:pubdatePickerView didSelectRow:pubdateIndexAtInitialization inComponent:0];
        pubdateIndexAtInitialization = 0;
    }
}

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil 
               bundle:(NSBundle *)nibBundleOrNil 
             keywords:(NSString *) keywordsText 
                title:(NSString *) titleText 
               author:(NSString *) authorText 
    englishOnlySwitch:(BOOL) englishOnlySwitch 
          formatIndex:(NSInteger) formatIndex 
        locationIndex:(NSInteger) locationIndex
         pubdateIndex:(NSInteger) pubdateIndex {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
		
		keywordTextAtInitialization = [keywordsText retain];
		titleTextAtInitialization = [titleText retain];
		authorTextAtInitialization = [authorText retain];
		formatIndexAtInitialization = formatIndex;
		locationIndexAtInitialization = locationIndex;
        englishOnlySwitchAtInitialization = englishOnlySwitch;
        pubdateIndexAtInitialization = pubdateIndex;

	}
    return self;
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	self.view.backgroundColor = [UIColor clearColor];
    UIImage *normalImage = [[UIImage imageNamed:@"global/subheadbar_button.png"] stretchableImageWithLeftCapWidth:10 topCapHeight:0];
    UIImage *pressedImage = [[UIImage imageNamed:@"global/subheadbar_button_pressed.png"] stretchableImageWithLeftCapWidth:10 topCapHeight:0];
    [searchButton setBackgroundImage:normalImage forState:UIControlStateNormal];
    [searchButton setBackgroundImage:pressedImage forState:UIControlStateHighlighted];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(searchCodesDidLoad:)
                                                 name:LibraryRequestDidCompleteNotification
                                               object:LibraryDataRequestSearchCodes];
    
    [[LibraryDataManager sharedManager] updateSearchCodes];
    
	[self setupLayout];
}


-(void) viewWillAppear:(BOOL)animated{
	[super viewWillAppear:animated];
	[self setupLayout];
}

- (void)didReceiveMemoryWarning {
	
    // Releases the view if it doesn't have a superview.
	
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
	
}

- (IBAction)resignAllResponders:(id)sender {
    [keywords resignFirstResponder];
    [titleKeywords resignFirstResponder];
    [authorKeywords resignFirstResponder];
	
	formatPickerView.hidden = YES;
	locationPickerView.hidden = YES;
    pubdatePickerView.hidden = YES;
    
    [self.scrollView setContentSize:self.view.bounds.size];
    [self.scrollView scrollRectToVisible:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) animated:YES];
}

- (void)viewDidUnload {
    
    self.keywords = nil;
    self.titleKeywords = nil;
    self.authorKeywords = nil;
    self.format = nil;
    self.formatDisclosure = nil;
    self.location = nil;
    self.locationDisclosure = nil;
    self.englishSwitch = nil;
	
}

- (void)dealloc {
    
    self.keywords = nil;
    self.titleKeywords = nil;
    self.authorKeywords = nil;
    self.format = nil;
    self.formatDisclosure = nil;
    self.location = nil;
    self.locationDisclosure = nil;
    self.englishSwitch = nil;
	
    [formatArray release];
    [libraryArray release];
    [pubdateArray release];
    
    [super dealloc];
	
}

-(void) search {
    
    NSMutableDictionary *searchParams = [NSMutableDictionary dictionary];
    if ([keywords.text length]) {
        [searchParams setObject:keywords.text forKey:@"keywords"];
    }
    if ([titleKeywords.text length]) {
        [searchParams setObject:titleKeywords.text forKey:@"title"];
    }
    if ([authorKeywords.text length]) {
        [searchParams setObject:authorKeywords.text forKey:@"author"];
    }
	
	if (englishSwitch.selected) {
        [searchParams setObject:@"eng" forKey:@"language"];
    }
    
	int formatRow = [formatPickerView selectedRowInComponent:0];
	
	if (formatRow > 0) {
        [searchParams setObject:((LibrarySearchCode *)[formatArray objectAtIndex:formatRow]).code forKey:@"format"];
	}
	
	int libraryRow = [locationPickerView selectedRowInComponent:0];
	
	if (libraryRow > 0) {
        [searchParams setObject:((LibrarySearchCode *)[libraryArray objectAtIndex:libraryRow]).code forKey:@"location"];
	}
	
	int pubdateRow = [pubdatePickerView selectedRowInComponent:0];
	
	if (pubdateRow > 0) {
        [searchParams setObject:((LibrarySearchCode *)[pubdateArray objectAtIndex:pubdateRow]).code forKey:@"pubDate"];
	}
	
	LibrariesSearchViewController *vc = [[LibrariesSearchViewController alloc] initWithViewController: nil];
    vc.keywordText = keywords.text;
    vc.titleText = titleKeywords.text;
    vc.authorText = authorKeywords.text;
	vc.englishOnlySwitch = englishSwitch.selected;
    
	JSONAPIRequest * apiRequest = [JSONAPIRequest requestWithJSONAPIDelegate:vc];
	
	[apiRequest requestObjectFromModule:@"libraries"
                                                command:@"search"
                                             parameters:searchParams];
    [self.navigationController pushViewController:vc animated:YES];
    
	[vc release];
}

#pragma mark User Actions

- (IBAction)pickerSelected:(id)sender {
	[keywords resignFirstResponder];
    [titleKeywords resignFirstResponder];	
    [authorKeywords resignFirstResponder];
	
	formatPickerView.hidden = YES;
	locationPickerView.hidden = YES;
    pubdatePickerView.hidden = YES;
    
    CGSize size = CGSizeMake(self.view.bounds.size.width, searchButton.frame.origin.y + searchButton.frame.size.height);
    
    if (sender == formatDisclosure) {
        formatPickerView.hidden = NO;
        size.height += formatPickerView.frame.size.height + 20;
        
    } else if (sender == locationDisclosure) {
        locationPickerView.hidden = NO;
        size.height += locationPickerView.frame.size.height + 20;

    } else if (sender == pubdateDisclosure) {
        pubdatePickerView.hidden = NO;
        size.height += pubdatePickerView.frame.size.height + 20;
        
    }
    
    CGRect visibleRect = CGRectMake(0, size.height - self.view.bounds.size.height, self.view.bounds.size.width, self.view.bounds.size.height);
    [self.scrollView setContentSize:size];
    [self.scrollView scrollRectToVisible:visibleRect animated:YES];
}

-(IBAction) searchButtonPressed:(id) sender{
	
	[self search];
}

-(void)englishButtonPressed: (id) sender {
	
	englishSwitch.selected = !englishSwitch.selected;
}


#pragma mark -
#pragma mark Picker Data Source Methods

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
	if (pickerView == formatPickerView)
		return [formatArray count];
	
	else if (pickerView == locationPickerView)
		return [libraryArray count];
	
    else if (pickerView == pubdatePickerView)
        return [pubdateArray count];
    
	return 0;
}

#pragma mark Picker Delegate Methods

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSArray *theArray;
    
	if (pickerView == formatPickerView) {
        theArray = formatArray;
	} else if (pickerView == locationPickerView) {
        theArray = libraryArray;
	} else if (pickerView == pubdatePickerView) {
		theArray = pubdateArray;
	}
    
    if ([[theArray objectAtIndex:row] isKindOfClass:[LibrarySearchCode class]]) {
        return ((LibrarySearchCode *)[theArray objectAtIndex:row]).name;
    } else {
        return [theArray objectAtIndex:row];
    }
    
	return @"";
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    NSArray *theArray;
    UILabel *theLabel;
    
	if (pickerView == formatPickerView) {
        theArray = formatArray;
        theLabel = format;
	} else if (pickerView == locationPickerView) {
        theArray = libraryArray;
        theLabel = location;
	} else if (pickerView == pubdatePickerView) {
		theArray = pubdateArray;
        theLabel = pubdate;
	}
    
    if ([[theArray objectAtIndex:row] isKindOfClass:[LibrarySearchCode class]]) {
        theLabel.text = ((LibrarySearchCode *)[theArray objectAtIndex:row]).name;
    } else {
        theLabel.text = @"Any";
    }
}

#pragma mark UITextField delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
	
	[self search];
	return YES;
}


#pragma mark -

- (void)searchCodesDidLoad:(NSNotification *)aNotification {
    [self setupLayout];
}

@end



