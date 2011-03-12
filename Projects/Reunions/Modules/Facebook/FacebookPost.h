//
//  FacebookPost.h
//  Reunions
//
//  Created by Sonya Huang on 3/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class FacebookUser;

@interface FacebookPost : NSManagedObject {
@private
}
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) FacebookUser * owner;

@end
