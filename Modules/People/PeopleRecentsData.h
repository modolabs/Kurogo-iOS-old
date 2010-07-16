#import <Foundation/Foundation.h>
#import "PersonDetails+Methods.h"


@interface PeopleRecentsData : NSObject {
	
	NSMutableArray *recents;
}

@property (nonatomic, retain) NSMutableArray *recents;

+ (PersonDetails *)personWithUID:(NSString *)uid;
+ (PeopleRecentsData *)sharedData;
+ (void)eraseAll;
+ (PersonDetails *)updatePerson:(PersonDetails *)personDetails withSearchResult:(NSDictionary *)searchResult;
+ (PersonDetails *)createFromSearchResult:(NSDictionary *)searchResult;

@end
