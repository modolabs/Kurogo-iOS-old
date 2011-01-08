//
//  LibraryAdvancedSearch.m
//  Harvard Mobile
//
//  Created by Muhammad J Amjad on 12/16/10.
//  Copyright 2010 ModoLabs Inc. All rights reserved.
//

#import "LibraryAdvancedSearch.h"
#import "CoreDataManager.h"
#import "LibraryItemFormat.h";
#import "LibraryLocation.h";
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

-(void) setupLayout{
	
	//formatDisclosure.transform = CGAffineTransformMakeRotation(M_PI/2);
	//locationDisclosure.transform = CGAffineTransformMakeRotation(M_PI/2);
	//[keywords becomeFirstResponder];
	
    NSPredicate * matchAll = [NSPredicate predicateWithFormat:@"TRUEPREDICATE"];
    NSSortDescriptor *nameSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES] autorelease];
    NSArray *sortDescriptors = [NSArray arrayWithObject:nameSortDescriptor];

    BOOL needCodesUpdate = NO;
    
    if (![libraryArray count] || [libraryArray count] <= 1) {
        NSArray * libraryCodes = [CoreDataManager objectsForEntity:LibraryLocationCodeEntityName matchingPredicate:matchAll sortDescriptors:sortDescriptors];
        if (libraryCodes != nil) {
            libraryArray = [[NSMutableArray alloc] initWithArray:libraryCodes];
        } else {
            needCodesUpdate = YES;
            libraryArray = [[NSMutableArray alloc] init];
        }
        [libraryArray insertObject:@"All Libraries/Archives" atIndex:0];
    }

    if (![formatArray count] || [formatArray count] <= 1) {
        NSArray * formatCodes = [CoreDataManager objectsForEntity:LibraryFormatCodeEntityName matchingPredicate:matchAll sortDescriptors:sortDescriptors];
        if (formatCodes != nil) {
            formatArray = [[NSMutableArray alloc] initWithArray:formatCodes];
        } else {
            needCodesUpdate = YES;
            formatArray = [[NSMutableArray alloc] init];
        }
        [formatArray insertObject:@"All formats (everything)" atIndex:0];
    }
    
    if (needCodesUpdate) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(searchCodesDidLoad:)
                                                     name:LibraryRequestDidCompleteNotification
                                                   object:LibraryDataRequestSearchCodes];
        
        [[LibraryDataManager sharedManager] requestSearchCodes];
    }
    
	locationPickerView.hidden = YES;
    [locationPickerView reloadAllComponents];  // Data may have changed due to JSON response
    [formatPickerView reloadAllComponents];  // Data may have changed due to JSON response
	
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
}

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil 
               bundle:(NSBundle *)nibBundleOrNil 
             keywords:(NSString *) keywordsText 
                title:(NSString *) titleText 
               author:(NSString *) authorText 
    englishOnlySwitch:(BOOL) englishOnlySwitch 
          formatIndex:(NSInteger) formatIndex 
        locationIndex:(NSInteger) locationIndex {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
		
		keywordTextAtInitialization = [keywordsText retain];
		titleTextAtInitialization = [titleText retain];
		authorTextAtInitialization = [authorText retain];
		formatIndexAtInitialization = formatIndex;
		locationIndexAtInitialization = locationIndex;
        englishOnlySwitchAtInitialization = englishOnlySwitch;

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
    NSLog(@"%@", [searchButton description]);

    // TODO: why isn't this being done in the nib file?
	[format setUserInteractionEnabled:NO];
	[location setUserInteractionEnabled:NO];
    
    formatPickerView.hidden = YES;
    locationPickerView.hidden = YES;

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

-(void) touchesBegan :(NSSet *) touches withEvent:(UIEvent *)event

{
	
    [keywords resignFirstResponder];	
    [titleKeywords resignFirstResponder];
    [authorKeywords resignFirstResponder];
	
	formatPickerView.hidden = YES;
	locationPickerView.hidden = YES;
	
    [super touchesBegan:touches withEvent:event];
	
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
        [searchParams setObject:((LibraryItemFormat *)[formatArray objectAtIndex:formatRow]).code forKey:@"format"];
	}
	
	int libraryRow = [locationPickerView selectedRowInComponent:0];
	
	if (libraryRow > 0) {
        [searchParams setObject:((LibraryLocation *)[libraryArray objectAtIndex:libraryRow]).code forKey:@"location"];
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

-(IBAction) formatPressed:(id) sender{
	
	[keywords resignFirstResponder];
    [titleKeywords resignFirstResponder];	
    [authorKeywords resignFirstResponder];
	
	locationPickerView.hidden = YES;
	formatPickerView.hidden = NO;
	
}
-(IBAction) locationPressed:(id) sender{
	
	[keywords resignFirstResponder];
    [titleKeywords resignFirstResponder];	
    [authorKeywords resignFirstResponder];
	
	formatPickerView.hidden = YES;
	locationPickerView.hidden = NO;
	
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
	
	return 0;
}

#pragma mark Picker Delegate Methods

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
	if (pickerView == formatPickerView) {
		if ([[formatArray objectAtIndex:row] isKindOfClass:[LibraryItemFormat class]]) {
			return ((LibraryItemFormat *)[formatArray objectAtIndex:row]).name;
		} else {
			return [formatArray objectAtIndex:row];
		}
	
	} else if (pickerView == locationPickerView) {
		
		if ([[libraryArray objectAtIndex:row] isKindOfClass:[LibraryLocation class]]) {
			return ((LibraryLocation *)[libraryArray objectAtIndex:row]).name;
        } else {
			return [libraryArray objectAtIndex:row];
		}
	}
	
	return @"";
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
	
	if (pickerView == formatPickerView){
		//formatPickerView.hidden = YES;
		
		if ([[formatArray objectAtIndex:row] isKindOfClass:[LibraryItemFormat class]]) {
			format.text = ((LibraryItemFormat *)[formatArray objectAtIndex:row]).name;
		} else {
			format.text = @"Any"; // @"All formats (everything)";
		}
	}
	
	else if (pickerView == locationPickerView) {
		//locationPickerView.hidden = YES;
		
		if ([[libraryArray objectAtIndex:row] isKindOfClass:[LibraryLocation class]]) {
			location.text = ((LibraryLocation *)[libraryArray objectAtIndex:row]).name;
		} else {
			location.text = @"Any"; // @"All Libraries/Archives";
		}
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

/*
#pragma mark JSONAPIRequest Delegate function 

- (void)request:(JSONAPIRequest *)request jsonLoaded:(id)result {
	
    if (result && [result isKindOfClass:[NSDictionary class]]) {
        NSInteger i;
        NSDictionary *dictionaryResults = (NSDictionary *)result;
    
        NSDictionary *formatCodes = [dictionaryResults objectForKey:@"formats"];
        NSDictionary *locationCodes = [dictionaryResults objectForKey:@"locations"];
        
        if (formatCodes) {
            NSInteger count = [formatCodes count];
            NSArray *codes = [formatCodes allKeys];
            for (i = 0; i < count; i++) {
                NSString *code = [codes objectAtIndex:i];
                NSString *name = [formatCodes objectForKey: code];
                
                NSPredicate *pred = [NSPredicate predicateWithFormat:@"code == %@", code];
                LibraryItemFormat *alreadyInDB = [[CoreDataManager objectsForEntity:LibraryFormatCodeEntityName matchingPredicate:pred] lastObject];
                
                if (nil == alreadyInDB) {
                    NSManagedObject *managedObj = [CoreDataManager insertNewObjectForEntityForName:LibraryFormatCodeEntityName];
                    alreadyInDB = (LibraryItemFormat *)managedObj;
                }
                
                alreadyInDB.code = code;
                alreadyInDB.name = name;
            }
        }
        
        if (locationCodes) {
            NSInteger count = [locationCodes count];
            NSArray *codes = [locationCodes allKeys];
            for (i = 0; i < count; i++) {
                NSString *code = [codes objectAtIndex:i];
                NSString *name = [locationCodes objectForKey: code];
                
                NSPredicate *pred = [NSPredicate predicateWithFormat:@"code == %@", code];
                LibraryLocation *alreadyInDB = [[CoreDataManager objectsForEntity:LibraryLocationCodeEntityName matchingPredicate:pred] lastObject];
                
                if (nil == alreadyInDB) {
                    NSManagedObject *managedObj = [CoreDataManager insertNewObjectForEntityForName:LibraryLocationCodeEntityName];
                    alreadyInDB = (LibraryLocation *)managedObj;
                }
                
                alreadyInDB.code = code;
                alreadyInDB.name = name;
            }
        }
    }
	
	[CoreDataManager saveData];
	[self viewWillAppear:YES];
}

- (BOOL)request:(JSONAPIRequest *)request shouldDisplayAlertForError:(NSError *)error {
	
    return YES;
}
*/
@end

