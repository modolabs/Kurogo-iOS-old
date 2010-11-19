//
//  LibraryItem.h
//  Harvard Mobile
//
//  Created by Muhammad J Amjad on 11/16/10.
//  Copyright 2010 ModoLabs Inc. All rights reserved.
//

#import <CoreData/CoreData.h>


@interface LibraryItem : NSManagedObject {
}

//@property (nonatomic, retain) NSDate * lastUpdate;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * author;
@property (nonatomic, retain) NSString * year;
@property (nonatomic, retain) NSString * details;
@property (nonatomic, retain) NSString * itemType;
@property (nonatomic, retain) NSNumber * isBookmarked;
@property (nonatomic, retain) NSString * callNumber;


@end
