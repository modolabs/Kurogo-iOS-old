//
//  EmergencyContactsSection.h
//  Universitas
//
//  Created by Brian Patt on 4/3/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class EmergencyContact;

@interface EmergencyContactsSection : NSManagedObject {
@private
}
@property (nonatomic, retain) NSString * moduleTag;
@property (nonatomic, retain) NSString * sectionTag;
@property (nonatomic, retain) NSDate * lastUpdate;
@property (nonatomic, retain) NSSet* contacts;

@end
