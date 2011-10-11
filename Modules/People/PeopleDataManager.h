#import <Foundation/Foundation.h>
#import "KGORequest.h"

@class PeopleDataManager;

@protocol PeopleDataDelegate <NSObject>

- (void)dataManager:(PeopleDataManager *)dataManager didReceiveContacts:(NSArray *)contacts;

@end

@interface PeopleDataManager : NSObject <KGORequestDelegate> {
    
}

@property (nonatomic, retain) ModuleTag *moduleTag;
@property (nonatomic, retain) KGORequest *staticContactsRequest;
@property (nonatomic, retain) KGORequest *groupContactsRequest;
@property (nonatomic, retain) NSArray *staticContacts;
@property (nonatomic, assign) id<PeopleDataDelegate> delegate;

- (void)fetchStaticContacts;
- (void)fetchContactsForGroup:(NSString *)groupID;

@end
