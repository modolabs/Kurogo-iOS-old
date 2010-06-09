//
//  MapBookmarkManager.h
//  MIT Mobile
//
//  Created by Craig on 4/27/10.
//  Copyright 2010 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MapBookmarkManager : NSObject {
	NSMutableArray* _bookmarks;
}

@property (readonly) NSArray* bookmarks;

+(MapBookmarkManager*) defaultManager;

-(void) addBookmark:(NSString*) bookmarkID title:(NSString*)title subtitle:(NSString*)subtitle data:(NSDictionary*)data;

-(void) removeBookmark:(NSString*) bookmarkID;

-(BOOL) isBookmarked:(NSString*) bookmarkID;

-(void) moveBookmarkFromRow:(int) from toRow:(int)to;

@end
