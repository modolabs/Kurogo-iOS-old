#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "KGOContactInfo.h"

@class KGOEventParticipant;

@interface KGOEventContactInfo : KGOContactInfo {
@private
}
@property (nonatomic, retain) KGOEventParticipant * attendee;

@end
