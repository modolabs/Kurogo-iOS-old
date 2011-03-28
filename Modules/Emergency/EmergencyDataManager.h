#import <Foundation/Foundation.h>
#import "KGORequestManager.h"
#import "EmergencyNotice.h"


enum EmergencyNoticeStatus {
    NoCurrentEmergencyNotice,        // feed exists, but currently empty (no emergency is going on)
    EmergencyNoticeActive,           // feed exists and emergency notice found
};
extern NSString * const EmergencyNoticeRetrievedNotification;

@interface EmergencyNoticeNotification : NSObject <KGORequestDelegate> {
@private
    NSString *_tag;
    EmergencyNotice *_notice;
}

@property (readonly) NSString *tag;
@property (readonly) EmergencyNotice *notice;
@end

@interface EmergencyDataManager : NSObject {
    NSString *tag;
}

+ (EmergencyDataManager *)managerForTag:(NSString *)tag;
- (void)fetchLatestEmergencyNotice;
- (EmergencyNotice *)latestEmergency;

@end
