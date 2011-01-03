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
	
	
	self.view.backgroundColor = [UIColor clearColor];
	[format setUserInteractionEnabled:NO];
	
	[location setUserInteractionEnabled:NO];
	
	//formatDisclosure.transform = CGAffineTransformMakeRotation(M_PI/2);
	//locationDisclosure.transform = CGAffineTransformMakeRotation(M_PI/2);
	[keywords becomeFirstResponder];
	
    NSPredicate * matchAll = [NSPredicate predicateWithFormat:@"TRUEPREDICATE"];
    NSSortDescriptor *nameSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES] autorelease];
    NSArray *sortDescriptors = [NSArray arrayWithObject:nameSortDescriptor];
    
    NSArray * libraryCodes = [CoreDataManager objectsForEntity:LibraryLocationCodeEntityName matchingPredicate:matchAll sortDescriptors:sortDescriptors];
    if (libraryCodes != nil) {
        libraryArray = [[NSMutableArray alloc] initWithArray:libraryCodes];
    } else {
        libraryArray = [[NSMutableArray alloc] init];
    }
    [libraryArray insertObject:@"All Libraries/Archives" atIndex:0];

    NSArray * formatCodes = [CoreDataManager objectsForEntity:LibraryFormatCodeEntityName matchingPredicate:matchAll sortDescriptors:sortDescriptors];
    if (formatCodes != nil) {
        formatArray = [[NSMutableArray alloc] initWithArray:formatCodes];
    } else {
        formatArray = [[NSMutableArray alloc] init];
    }
    [formatArray insertObject:@"All formats (everything)" atIndex:0];
    
	locationPickerView.hidden = YES;
    [locationPickerView reloadAllComponents];  // Data may have changed due to JSON response
    [formatPickerView reloadAllComponents];  // Data may have changed due to JSON response
	
	keywords.delegate = self;
	titleKeywords.delegate = self;
	authorKeywords.delegate = self;
	
	if (nil != keywordTextAtInitialization && [keywordTextAtInitialization length]) {
        NSLog(@"Got keywords %@", keywordTextAtInitialization);
		self.keywords.text = [keywordTextAtInitialization autorelease];
        keywordTextAtInitialization = nil;
	}
    
	if (nil != titleTextAtInitialization && [titleTextAtInitialization length]) {
        NSLog(@"Got title %@", titleTextAtInitialization);
		self.titleKeywords.text = [titleTextAtInitialization autorelease];
        titleTextAtInitialization = nil;
	}
    
	if (nil != authorTextAtInitialization && [authorTextAtInitialization length]) {
        NSLog(@"Got author %@", authorTextAtInitialization);
		self.authorKeywords.text = [authorTextAtInitialization autorelease];
        authorTextAtInitialization = nil;
	}
    
    if (englishOnlySwitchAtInitialization) {
        englishSwitch.selected = YES;
    }
    
    if (formatIndexAtInitialization > 0 && formatIndexAtInitialization < [formatArray count]) {
        NSLog(@"Got format %d", formatIndexAtInitialization);
        [formatPickerView selectRow:formatIndexAtInitialization inComponent:0 animated:false]; 
        [self pickerView:formatPickerView didSelectRow:formatIndexAtInitialization inComponent:0];
        formatIndexAtInitialization = 0;
    }
    
    if (locationIndexAtInitialization > 0 && locationIndexAtInitialization < [libraryArray count]) {
        NSLog(@"Got location %d", locationIndexAtInitialization);
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
		
		keywordTextAtInitialization = keywordsText;
		titleTextAtInitialization = titleText;
		authorTextAtInitialization = authorText;
		formatIndexAtInitialization = formatIndex;
		locationIndexAtInitialization = locationIndex;
        englishOnlySwitchAtInitialization = englishOnlySwitch;

	}
    return self;
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
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
	
    // Release any retained subviews of the main view.
	
    // e.g. self.myOutlet = nil;
	
}

- (void)dealloc {
	
    [super dealloc];
	
}

-(void) search{
	
	NSString * keyword = keywords.text;
	if ([keyword length] == 0)
		keyword = @"\"\"";
	NSString * titleStr = titleKeywords.text;
	if ([titleStr length] == 0)
		titleStr =  @"\"\"";
	NSString * authorStr = authorKeywords.text;
	if ([authorStr length] == 0)
		authorStr =  @"\"\"";
	
	
	NSString * parameterQ = [NSString stringWithFormat:@"%@+title:%@+author:%@", keyword, titleStr, authorStr];
	
	if (englishSwitch.selected)
		parameterQ = [parameterQ stringByAppendingFormat:@"+language-id:eng"];
	
	NSLog(@"q=%@", parameterQ);
	
	NSString * formatStr = @""; // Nothing selected or first item selected (first item is "all")
	int formatRow = [formatPickerView selectedRowInComponent:0];
	
	if (formatRow > 0) {
		formatStr = ((LibraryItemFormat *)[formatArray objectAtIndex:formatRow]).code;	
	}
	
	NSString * locationStr = @""; // Nothing selected or first item selected (first item is "all")
	int libraryRow = [locationPickerView selectedRowInComponent:0];
	
	if (libraryRow > 0) {
		locationStr = ((LibraryLocation *)[libraryArray objectAtIndex:libraryRow]).code;
	}
	
	
	NSLog(@"fmt=%@", formatStr);
	NSLog(@"lib=%@", locationStr);
	
	LibrariesSearchViewController *vc = [[LibrariesSearchViewController alloc] initWithViewController: nil];
	vc.title = @"Search Results";
    vc.keywordText = keywords.text;
    vc.titleText = titleKeywords.text;
    vc.authorText = authorKeywords.text;
	vc.englishOnlySwitch = englishSwitch.selected;
    
	apiRequest = [JSONAPIRequest requestWithJSONAPIDelegate:vc];
	
	BOOL requestWasDispatched = [apiRequest requestObjectFromModule:@"libraries"
                                                command:@"search"
                                             parameters:[NSDictionary dictionaryWithObjectsAndKeys:
														 parameterQ, @"q", 
														 formatStr, @"fmt",
														 locationStr, @"lib",
														 nil]];
	
    if (requestWasDispatched) {
		vc.searchTerms = parameterQ;
        if (formatRow != -1) {
            vc.formatIndex = formatRow;
            NSLog(@"Setting format row to %d", formatRow);
        }
        if (libraryRow != -1) {
            vc.locationIndex = libraryRow;
            NSLog(@"Setting location row to %d", libraryRow);
        }
		[self.navigationController pushViewController:vc animated:YES];
    } else {
        //[self handleWarningMessage:@"Could not dispatch search" title:@"Search Failed"];
    }
	
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

@end

