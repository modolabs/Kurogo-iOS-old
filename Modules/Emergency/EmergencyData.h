#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "JSONAPIRequest.h"

@interface EmergencyData : NSObject <JSONAPIDelegate> {
    NSManagedObject *info;
    NSArray *contacts;
    
    NSArray *primaryPhoneNumbers;
    NSArray *allPhoneNumbers;
    
    JSONAPIRequest *infoConnection;
    JSONAPIRequest *contactsConnection;
}

+ (EmergencyData *)sharedData;

- (void)fetchEmergencyInfo;
- (void)fetchContacts;

- (void)reloadContacts;
- (void)checkForEmergencies;

- (BOOL)hasNeverLoaded;

@property (nonatomic, readonly) NSString *htmlString;
@property (nonatomic, readonly) NSDate *lastUpdated;
@property (nonatomic, readonly) NSDate *lastFetched;
@property (nonatomic, readonly) NSArray *primaryPhoneNumbers;
@property (nonatomic, readonly) NSArray *allPhoneNumbers;
@property (retain) JSONAPIRequest *infoConnection;
@property (retain) JSONAPIRequest *contactsConnection;

@end
