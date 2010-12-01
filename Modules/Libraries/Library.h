//
//  Library.h
//  Harvard Mobile
//
//  Created by Muhammad J Amjad on 11/16/10.
//  Copyright 2010 ModoLabs Inc. All rights reserved.
//

#import <CoreData/CoreData.h>

@class LibraryPhone;


@interface Library : NSManagedObject {

}

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * identityTag;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSString * location;
@property (nonatomic, retain) NSNumber * lat;
@property (nonatomic, retain) NSNumber * lon;
@property (nonatomic, retain) NSString * websiteLib;
@property (nonatomic, retain) NSString * emailLib;
@property (nonatomic, retain) NSSet * phone;
@property (nonatomic, retain) NSString * directions;
@property (nonatomic, retain) NSNumber * isBookmarked;

@end

@interface Library (CoreDataGeneratedAccessors)
- (void)addPhoneObject:(LibraryPhone *)value;
- (void)removePhoneObject:(LibraryPhone *)value;
- (void)addPhone:(NSSet *)value;
- (void)removePhone:(NSSet *)value;

@end
