#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "KGOContactInfo.h"

@class KGOEventAttendee;

@interface KGOEventContactInfo : KGOContactInfo {
@private
}
@property (nonatomic, retain) KGOEventAttendee * attendee;

@end
