#import <Foundation/Foundation.h>
#import "PersonDetails.h"
#import "JSONAPIRequest.h"

@interface PeopleRecentsData : NSObject <JSONAPIDelegate> {
	
	NSMutableArray *recents;
    NSDictionary *displayFields;
}

@property (nonatomic, retain) NSMutableArray *recents;
@property (nonatomic, readonly) NSDictionary *displayFields;

+ (PersonDetails *)personWithUID:(NSString *)uid;
+ (PeopleRecentsData *)sharedData;
+ (void)eraseAll;
+ (PersonDetails *)updatePerson:(PersonDetails *)personDetails withSearchResult:(NSDictionary *)searchResult;
+ (PersonDetails *)createFromSearchResult:(NSDictionary *)searchResult;

@end
