#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class KGOEventCategory, KGOEventParticipantRelation;

@interface KGOEvent : NSManagedObject {
@private
}
@property (nonatomic, retain) NSDate * start;
@property (nonatomic, retain) NSDate * lastUpdate;
@property (nonatomic, retain) NSData * rrule;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSString * briefLocation;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * location;
@property (nonatomic, retain) NSString * summary;
@property (nonatomic, retain) NSDate * end;
@property (nonatomic, retain) NSData * userInfo;
@property (nonatomic, retain) NSNumber * bookmarked;
@property (nonatomic, retain) NSString * placemarkID;
@property (nonatomic, retain) NSSet* calendars;
@property (nonatomic, retain) NSSet* particpants;

+ (KGOEvent *)eventWithID:(NSString *)identifier;
+ (KGOEvent *)findEventWithID:(NSString *)identifier;

@end
