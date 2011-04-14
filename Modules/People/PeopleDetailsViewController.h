#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import "KGOTableViewController.h"
#import "KGODetailPager.h"
#import "KGOPersonWrapper.h"
#import <MessageUI/MFMailComposeViewController.h>


@interface PeopleDetailsViewController : KGOTableViewController
	<ABPeoplePickerNavigationControllerDelegate, 
	 ABNewPersonViewControllerDelegate, 
	 ABPersonViewControllerDelegate, 
     KGODetailPagerDelegate,
     MFMailComposeViewControllerDelegate> 
{

    KGOPersonWrapper *_person;
	NSMutableArray *_sectionArray;
    NSInteger _phoneSection;
    NSInteger _emailSection;
    NSInteger _addressSection;
}

@property (nonatomic, retain) KGOPersonWrapper *person;
@property (nonatomic, retain) NSMutableArray *sectionArray;
@property (nonatomic, retain) KGODetailPager *pager;

- (void)mapIconTapped:(NSString *)address;
- (void)phoneIconTapped:(NSString *)phone;
- (void)emailIconTapped:(NSString *)email;

@end

