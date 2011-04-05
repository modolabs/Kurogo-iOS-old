//
//  Video.h
//  Universitas
//
//  Created by Jim Kang on 3/30/11.
//  Copyright 2011 Modo Labs. All rights reserved.
//

#import <CoreData/CoreData.h>


@interface Video :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * videoID;
@property (nonatomic, retain) NSString * videoDescription;
@property (nonatomic, retain) NSString * author;
@property (nonatomic, retain) NSDate * published;
@property (nonatomic, retain) NSNumber * width;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * imageURLString;
@property (nonatomic, retain) NSNumber * height;
@property (nonatomic, retain) NSNumber * duration;
@property (nonatomic, retain) NSSet* tags;

@end


@interface Video (CoreDataGeneratedAccessors)
- (void)addTagsObject:(NSManagedObject *)value;
- (void)removeTagsObject:(NSManagedObject *)value;
- (void)addTags:(NSSet *)value;
- (void)removeTags:(NSSet *)value;

@end

