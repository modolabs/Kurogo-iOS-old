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


-(void) setupLayout{
	
	
	self.view.backgroundColor = [UIColor clearColor];
	[format setUserInteractionEnabled:NO];
	
	[location setUserInteractionEnabled:NO];
	
	//formatDisclosure.transform = CGAffineTransformMakeRotation(M_PI/2);
	//locationDisclosure.transform = CGAffineTransformMakeRotation(M_PI/2);
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
	
	if ([bookmarkedArray count] > 0) {
		[libraryArray insertObject:@"> Bookmarked Locations" atIndex:index];
		index++;
	}	
	for(Library * lib in bookmarkedArray){
		[libraryArray insertObject:lib atIndex:index];
		index++;
	}
	
	if ([bookmarkedArray count] > 0) {
		[libraryArray insertObject:@"> All Other Locations" atIndex:index];
		index++;
	}
	
	for(Library * lib in otherLibArray){
		[libraryArray insertObject:lib atIndex:index];
		index++;
	}
	
	[libraryArray retain];
	
	locationPickerView.hidden = YES;
	
	keywords.delegate = self;
	titleKeywords.delegate = self;
	authorKeywords.delegate = self;
	
	if (nil != keywordsTextAtInitialization)
		self.keywords.text = keywordsTextAtInitialization;
	
	
	englishSwitch = [UIButton buttonWithType:UIButtonTypeCustom];
	englishSwitch.frame = CGRectMake(152, 182, 15, 15);
	englishSwitch.enabled = YES;
	[englishSwitch setImage:[UIImage imageNamed:@"global/checkbox_normal.png"] forState:UIControlStateNormal];
	[englishSwitch setImage:[UIImage imageNamed:@"global/checkbox_pressed.png"] forState:(UIControlStateNormal | UIControlStateHighlighted)];
	[englishSwitch setImage:[UIImage imageNamed:@"global/checkbox_selected.png"] forState:UIControlStateSelected];
	[englishSwitch setImage:[UIImage imageNamed:@"global/checkbox_selected.png"] forState:(UIControlStateSelected | UIControlStateHighlighted)];
	[englishSwitch addTarget:self action:@selector(englishButtonPressed:) forControlEvents:UIControlEventTouchUpInside]; 
	[self.view addSubview:englishSwitch];
}

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil keywords:(NSString *) keywordsText{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
		
		keywordsTextAtInitialization = keywordsText;

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
		//formatPickerView.hidden = YES;
		//formatPickerView = nil;
	
		
		if ([[sortedFormats objectAtIndex:row] isEqualToString:@"All formats (everything)"]){
			//format.text = @"";
			format.text = @"Any";
		}
		
		else
			format.text = [sortedFormats objectAtIndex:row];
	}
	
	else if (pickerView == locationPickerView) {
		//locationPickerView.hidden = YES;
		
		if ([[libraryArray objectAtIndex:row] isKindOfClass:[Library class]])
			location.text = ((Library *)[libraryArray objectAtIndex:row]).name;
		
		else {
			//location.text = @"";
			location.text = @"Any"; //@"All Libraries/Archives";
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
	
	NSArray *resultArray = (NSArray *)result;

	for (int index=0; index < [result count]; index++) {
		NSDictionary *libraryDictionary = [resultArray objectAtIndex:index];
		
		NSString * name = [libraryDictionary objectForKey:@"name"];
		NSString * primaryName = [libraryDictionary objectForKey:@"primaryName"];
		NSString * identityTag = [libraryDictionary objectForKey:@"id"];
		NSNumber * latitude = [libraryDictionary objectForKey:@"latitude"];
		NSNumber * longitude = [libraryDictionary objectForKey:@"longitude"];
		NSString * locationAdd = [libraryDictionary objectForKey:@"address"];
		
		NSString * type = [libraryDictionary objectForKey:@"type"];

		NSPredicate *pred = [NSPredicate predicateWithFormat:@"name == %@ AND type == %@", name, type];
		Library *alreadyInDB = [[CoreDataManager objectsForEntity:LibraryEntityName matchingPredicate:pred] lastObject];
		
		
		NSManagedObject *managedObj;
		if (nil == alreadyInDB){
			managedObj = [CoreDataManager insertNewObjectForEntityForName:LibraryEntityName];
			alreadyInDB = (Library *)managedObj;
			alreadyInDB.isBookmarked = [NSNumber numberWithBool:NO];
		}
		
		/*[alreadyInDB setValue:name forKey:@"name"];
		 [alreadyInDB setValue:[NSNumber numberWithDouble:[latitude doubleValue]] forKey:@"lat"];
		 [alreadyInDB setValue:[NSNumber numberWithDouble:[longitude doubleValue]] forKey:@"lon"];		
		 */
		
		alreadyInDB.name = name;
		alreadyInDB.primaryName = primaryName;
		alreadyInDB.identityTag = identityTag;
		alreadyInDB.location = locationAdd;
		alreadyInDB.lat = [NSNumber numberWithDouble:[latitude doubleValue]];
		alreadyInDB.lon = [NSNumber numberWithDouble:[longitude doubleValue]];
		alreadyInDB.type = type;
		
		alreadyInDB.isBookmarked = alreadyInDB.isBookmarked;

	}

	
	[CoreDataManager saveData];
	[self viewWillAppear:YES];
	
}

- (BOOL)request:(JSONAPIRequest *)request shouldDisplayAlertForError:(NSError *)error {
	
    return YES;
}

- (void)request:(JSONAPIRequest *)request handleConnectionError:(NSError *)error {
	
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
														message:@"Could not retrieve Libraries/Archives" 
													   delegate:self 
											  cancelButtonTitle:@"OK" 
											  otherButtonTitles:nil];
	[alertView show];
	[alertView release];
}


@end

