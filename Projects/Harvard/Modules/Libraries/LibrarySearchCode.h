//
//  LibraryLocation.h
//  Harvard Mobile
//
//  Created by Alexandra Ellwood on 12/27/10.
//  Copyright 2010 ModoLabs Inc. All rights reserved.
//

#import <CoreData/CoreData.h>


@interface LibrarySearchCode :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * code;
@property (nonatomic, retain) NSNumber * sortOrder;

@end



