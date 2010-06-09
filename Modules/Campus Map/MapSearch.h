//
//  MapSearch.h
//  MIT Mobile
//
//  Created by Craig on 5/19/10.
//  Copyright 2010 Raizlabs. All rights reserved.
//

#import <CoreData/CoreData.h>


@interface MapSearch :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * searchTerm;
@property (nonatomic, retain) NSDate * date;

@end



