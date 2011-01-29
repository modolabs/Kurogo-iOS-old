//
//  LibraryAdvancedSearch.h
//  Harvard Mobile
//
//  Created by Muhammad J Amjad on 12/16/10.
//  Copyright 2010 ModoLabs Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CancellableScrollView;

@interface LibraryAdvancedSearch : UIViewController <UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate> {
    
    IBOutlet UIScrollView *scrollView;
	
    IBOutlet UITextField *keywords;
	
    IBOutlet UITextField *titleKeywords;
	
    IBOutlet UITextField *authorKeywords;
	
	IBOutlet UILabel *format;	
	IBOutlet UIButton *formatDisclosure;
	
	IBOutlet UILabel *location;
	IBOutlet UIButton *locationDisclosure;
    
    IBOutlet UILabel *pubdate;
    IBOutlet UIButton *pubdateDisclosure;
	
	IBOutlet UIButton * englishSwitch;
	
	IBOutlet UIPickerView * formatPickerView;
	IBOutlet UIPickerView * locationPickerView;
	IBOutlet UIPickerView * pubdatePickerView;
	
	IBOutlet UIButton * searchButton;
	
	NSMutableArray * formatArray;
	NSMutableArray * libraryArray;
    NSMutableArray * pubdateArray;
	
	NSString * keywordTextAtInitialization;
	NSString * titleTextAtInitialization;
	NSString * authorTextAtInitialization;
	BOOL englishOnlySwitchAtInitialization;
	NSInteger formatIndexAtInitialization;
	NSInteger locationIndexAtInitialization;
    NSInteger pubdateIndexAtInitialization;
}

@property (nonatomic, retain) IBOutlet UIScrollView *scrollView;
@property (nonatomic, retain) IBOutlet UITextField *keywords;
@property (nonatomic, retain) IBOutlet UITextField *titleKeywords;
@property (nonatomic, retain) IBOutlet UITextField *authorKeywords;
@property (nonatomic, retain) IBOutlet UILabel *format;
@property (nonatomic, retain) IBOutlet UIButton * formatDisclosure;
@property (nonatomic, retain) IBOutlet UILabel * location;
@property (nonatomic, retain) IBOutlet UIButton * locationDisclosure;
@property (nonatomic, retain) IBOutlet UIButton * englishSwitch;

- (IBAction)pickerSelected:(id)sender;
-(IBAction) searchButtonPressed:(id) sender;
-(IBAction) englishButtonPressed: (id) sender;

- (IBAction)resignAllResponders:(id)sender;

- (id)initWithNibName:(NSString *)nibNameOrNil 
               bundle:(NSBundle *)nibBundleOrNil 
             keywords:(NSString *) keywordsText 
                title:(NSString *) titleText 
               author:(NSString *) authorText 
    englishOnlySwitch:(BOOL) englishOnlySwitch 
          formatIndex:(NSInteger) formatIndex 
        locationIndex:(NSInteger) locationIndex
         pubdateIndex:(NSInteger) pubdateIndex;
-(void) search;
@end
