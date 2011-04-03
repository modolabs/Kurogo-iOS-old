//
//  EmergencyContact.m
//  Universitas
//
//  Created by Brian Patt on 4/3/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "EmergencyContact.h"
#import "EmergencyContactsSection.h"


@implementation EmergencyContact
@dynamic title;
@dynamic subtitle;
@dynamic formattedPhone;
@dynamic dialablePhone;
@dynamic order;
@dynamic section;

- (NSString *)summary {
    if (self.subtitle) {
        return [NSString stringWithFormat:@"%@ (%@)", self.subtitle, self.formattedPhone];
    } else {
        return [NSString stringWithFormat:@"(%@)", self.formattedPhone];
    }
}

@end
