//
//  NewsCategory.h
//  Universitas
//
//  Created by Brian Patt on 3/15/11.
//  Copyright (c) 2011 Modo Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NewsStory;

@interface NewsCategory : NSManagedObject {
@private
}
@property (nonatomic, retain) NSNumber * moreStories;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * category_id;
@property (nonatomic, retain) NSNumber * isMainCategory;
@property (nonatomic, retain) NSDate * lastUpdated;
@property (nonatomic, retain) NSNumber * nextSeekId;
@property (nonatomic, retain) NSSet* stories;

@end
