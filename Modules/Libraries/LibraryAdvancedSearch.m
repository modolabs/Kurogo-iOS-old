//
//  LibraryAdvancedSearch.m
//  Harvard Mobile
//
//  Created by Muhammad J Amjad on 12/16/10.
//  Copyright 2010 ModoLabs Inc. All rights reserved.
//

#import "LibraryAdvancedSearch.h"
#import "CoreDataManager.h"
#import "Library.h";
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

NSInteger libraryNameSortAdvancedSearch(id lib1, id lib2, void *context) {
	
	Library * library1 = (Library *)lib1;
	Library * library2 = (Library *)lib2;
	
	return [library1.name compare:library2.name];
}


// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
		
		self.view.backgroundColor = [UIColor clearColor];
		[format setUserInteractionEnabled:NO];
		
		[location setUserInteractionEnabled:NO];
		
		formatDisclosure.transform = CGAffineTransformMakeRotation(M_PI/2);
		locationDisclosure.transform = CGAffineTransformMakeRotation(M_PI/2);
		[keywords becomeFirstResponder];

		if (nil == formatDictionary) {
			
			formatDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:
								@"", @"All formats (everything)",
								@"matBook", @"Book",
								@"matMagazine", @"Journal/Serial",
								@"matManuscript", @"Archives / Manuscripts",
								@"matSheetMusic", @"Music Score",
								@"matRecording", @"Sound Recording",
								@"matMovie",@"Video / Film",
								@"matMap", @"Map",
								@"matPhoto", @"Image",
								@"matComputerFile", @"Computer file / Data",
								@"matObjects", @"Object", nil];
			
		}
		
		if (nil == sortedFormats)
			sortedFormats = [[NSArray alloc] init];
		
		sortedFormats = [formatDictionary allKeys];
		sortedFormats = [[sortedFormats sortedArrayUsingSelector:@selector(compare:)] retain];
		formatPickerView.hidden = YES;
		
		
		NSPredicate *bookmarkPred = [NSPredicate predicateWithFormat:@"isBookmarked == YES"];
		NSArray *bookmarkedArray = [CoreDataManager objectsForEntity:LibraryEntityName matchingPredicate:bookmarkPred];
		
		bookmarkedArray = [[bookmarkedArray sortedArrayUsingFunction:libraryNameSortAdvancedSearch context:self] retain];
		
		NSPredicate *otherPred = [NSPredicate predicateWithFormat:@"isBookmarked == NO"];
		NSArray *otherLibArray = [CoreDataManager objectsForEntity:LibraryEntityName matchingPredicate:otherPred];
		
		otherLibArray = [[otherLibArray sortedArrayUsingFunction:libraryNameSortAdvancedSearch context:self] retain];
		
		int index = 0;
		libraryArray = [[NSMutableArray alloc] init];
		
		[libraryArray insertObject:@"All Libraries/Archives" atIndex:index];
		index++;
		
		for(Library * lib in bookmarkedArray){
			[libraryArray insertObject:lib atIndex:index];
			index++;
		}
		
		[libraryArray insertObject:@"-------" atIndex:index];
		index++;
		
		for(Library * lib in otherLibArray){
			[libraryArray insertObject:lib atIndex:index];
			index++;
		}
		
		[libraryArray retain];
		
		locationPickerView.hidden = YES;
		
		keywords.delegate = self;
		titleKeywords.delegate = self;
		authorKeywords.delegate = self;
	}
    return self;
}

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

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
	NSLog(@"q=%@", parameterQ);
	
	NSString * formatStr = @"";
	int formatRow = [formatPickerView selectedRowInComponent:0];
	
	if (formatRow != -1){

		formatStr = [formatDictionary objectForKey:[sortedFormats objectAtIndex:formatRow]];		
	}
	
	NSString * locationStr = @"";
	int libraryRow = [locationPickerView selectedRowInComponent:0];
	
	if (libraryRow != -1){
		if ([[libraryArray objectAtIndex:libraryRow] isKindOfClass:[Library class]]){
			//locationStr = ((Library *)[libraryArray objectAtIndex:libraryRow]).name;	
		}
	}
	
	
	NSLog(@"fmt=%@", formatStr);
	NSLog(@"lib=%@", locationStr);
	
	LibrariesSearchViewController *vc = [[LibrariesSearchViewController alloc] initWithViewController: nil];
	vc.title = @"Search Results";
	
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


#pragma mark -
#pragma mark Picker Data Source Methods

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
	if (pickerView == formatPickerView)
		return [sortedFormats count];
	
	else if (pickerView == locationPickerView)
		return [libraryArray count];
	
	return 0;
}

#pragma mark Picker Delegate Methods

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
	if (pickerView == formatPickerView)
		return [sortedFormats objectAtIndex:row];
	
	else if (pickerView == locationPickerView) {
		
		if ([[libraryArray objectAtIndex:row] isKindOfClass:[Library class]])
			return ((Library *)[libraryArray objectAtIndex:row]).name;
		
		else {
			return [libraryArray objectAtIndex:row];
		}

	}
	
	return @"";
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
	
	if (pickerView == formatPickerView){
		formatPickerView.hidden = YES;
		//formatPickerView = nil;
	
		
		if ([[sortedFormats objectAtIndex:row] isEqualToString:@"All formats (everything)"]){
			format.text = @"";
			format.placeholder = @"Any";
		}
		
		else
			format.text = [sortedFormats objectAtIndex:row];
	}
	
	else if (pickerView == locationPickerView) {
		locationPickerView.hidden = YES;
		
		if ([[libraryArray objectAtIndex:row] isKindOfClass:[Library class]])
			location.text = ((Library *)[libraryArray objectAtIndex:row]).name;
		
		else {
			location.text = @"";
			location.placeholder = @"Any"; //@"All Libraries/Archives";
		}
	}
}

#pragma mark UITextField delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
	
	[self search];
	return YES;
}


@end

