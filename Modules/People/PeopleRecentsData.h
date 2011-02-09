#import <Foundation/Foundation.h>
#import "PersonDetails.h"
#import "JSONAPIRequest.h"

extern NSString * const PeopleDisplayFieldsDidDownloadNotification;

@interface PeopleRecentsData : NSObject <JSONAPIDelegate> {
	
	NSMutableArray *recents;
    NSDictionary *displayFields;
}

@property (nonatomic, retain) NSMutableArray *recents;
@property (nonatomic, readonly) NSDictionary *displayFields;

- (void)clearOldResults;
- (void)loadRecentsFromCache;

+ (PersonDetails *)personWithUID:(NSString *)uid;
+ (PeopleRecentsData *)sharedData;
+ (void)eraseAll;
+ (PersonDetails *)createFromSearchResult:(NSDictionary *)searchResult;

@end
