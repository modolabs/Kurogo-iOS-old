//
//  LibraryAdvancedSearch.h
//  Harvard Mobile
//
//  Created by Muhammad J Amjad on 12/16/10.
//  Copyright 2010 ModoLabs Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JSONAPIRequest.h"


@interface LibraryAdvancedSearch : UIViewController <UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate, JSONAPIDelegate>{
	
    IBOutlet UITextField *keywords;
	
    IBOutlet UITextField *titleKeywords;
	
    IBOutlet UITextField *authorKeywords;
	
	IBOutlet UITextField *format;	
	IBOutlet UIButton *formatDisclosure;
	
	IBOutlet UITextField *location;
	IBOutlet UIButton *locationDisclosure;
	
	IBOutlet UISwitch * englishSwitch;
	
	IBOutlet UIPickerView * formatPickerView;
	IBOutlet UIPickerView * locationPickerView;
	
	
	IBOutlet UIButton * searchButton;
	
	NSDictionary * formatDictionary;
	NSArray * sortedFormats;
	
	NSMutableArray * libraryArray;
	
	JSONAPIRequest * apiRequest;
	
	NSString * keywordsTextAtInitialization;
}

@property (nonatomic, retain) IBOutlet UITextField *keywords;
@property (nonatomic, retain) IBOutlet UITextField *titleKeywords;
@property (nonatomic, retain) IBOutlet UITextField *authorKeywords;
@property (nonatomic, retain) IBOutlet UITextField *format;
@property (nonatomic, retain) IBOutlet UIButton * formatDisclosure;
@property (nonatomic, retain) IBOutlet UITextField * location;
@property (nonatomic, retain) IBOutlet UIButton * locationDisclosure;
@property (nonatomic, retain) IBOutlet UISwitch * englishSwitch;

-(IBAction) formatPressed:(id) sender;
-(IBAction) locationPressed:(id) sender;
-(IBAction) searchButtonPressed:(id) sender;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil keywords:(NSString *) keywordsText;
-(void) search;
@end