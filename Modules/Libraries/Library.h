//
//  Library.h
//  Harvard Mobile
//
//  Created by Muhammad J Amjad on 11/16/10.
//  Copyright 2010 ModoLabs Inc. All rights reserved.
//

#import <CoreData/CoreData.h>


@interface Library : NSManagedObject {

}

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSNumber * lat;
@property (nonatomic, retain) NSNumber * lon;
@property (nonatomic, retain) NSString * webpage;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSString * phone;
@property (nonatomic, retain) NSNumber * isBookmarked;

@end
