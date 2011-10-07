#import <Foundation/Foundation.h>
#import "KGORequestManager.h"
#import "EmergencyModel.h"

enum EmergencyNoticeStatus {
    NoCurrentEmergencyNotice,        // feed exists, but currently empty (no emergency is going on)
    EmergencyNoticeActive,           // feed exists and emergency notice found
};
extern NSString * const EmergencyNoticeRetrievedNotification;
extern NSString * const EmergencyContactsRetrievedNotification;

@interface EmergencyDataManager : NSObject <KGORequestDelegate> {
    NSString *tag;
}

+ (EmergencyDataManager *)managerForTag:(NSString *)tag;
- (void)fetchLatestEmergencyNotice;
- (EmergencyNotice *)latestEmergency;

- (BOOL)hasSecondaryContacts;
- (void)fetchContacts;
- (NSArray *)primaryContacts;
- (NSArray *)allContacts;

@end
