//
//  Phone.h
//  Harvard Mobile
//
//  Created by Muhammad J Amjad on 11/30/10.
//  Copyright 2010 ModoLabs Inc. All rights reserved.
//

#import <CoreData/CoreData.h>

@class Library;

@interface LibraryPhone : NSManagedObject {
}

@property (nonatomic, retain) NSString * descriptionText;
@property (nonatomic, retain) NSString * phoneNumber;
@property (nonatomic, retain) Library * library;
@property (nonatomic, retain) NSNumber * sortOrder;

- (NSComparisonResult)compare:(LibraryPhone *)otherObject;

@end
