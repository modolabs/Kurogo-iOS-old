//
//  ContactsTableViewController.h
//  Harvard Mobile
//
//  Created by Muhammad Amjad on 9/24/10.
//  Copyright 2010 Modo Labs. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ContactsTableViewController : UITableViewController {

	UINavigationController *parentViewController;
}

@property (nonatomic, retain) UINavigationController *parentViewController;


-(NSArray *)getEmergencyPhoneNumbers;
-(NSArray *)getShuttleServicePhoneNumbers;
-(NSArray *)getSystemArrayPhoneNumbers;

-(NSArray *)getEmergencyPhoneNumbersText;
-(NSArray *)getShuttleServicePhoneNumbersText;
-(NSArray *)getSystemArrayPhoneNumbersText;

@end
