//
//  Phone.m
//  Harvard Mobile
//
//  Created by Muhammad J Amjad on 11/30/10.
//  Copyright 2010 ModoLabs Inc. All rights reserved.
//

#import "LibraryPhone.h"


@implementation LibraryPhone

@dynamic phoneNumber;
@dynamic descriptionText;
@dynamic library;


- (NSComparisonResult)compare:(LibraryPhone *)otherObject {
    return [self.phoneNumber compare:otherObject.phoneNumber];
}

@end
