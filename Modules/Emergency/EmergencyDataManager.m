#import "EmergencyDataManager.h"
#import "Foundation+KGOAdditions.h"
#import "CoreDataManager.h"

NSString * const EmergencyNoticeRetrievedNotification = @"EmergencyNoticeRetrieved";

@interface EmergencyDataManager (Private) 

- (id)initManagerWithTag:(NSString *) tag;
- (NSArray *)cachedNotices;
- (NSPredicate *)tagPredicate;

@end

@implementation EmergencyDataManager

- (id)initManagerWithTag:(NSString *)aTag {
    if ((self = [super init])) {
        tag = [aTag retain];
    }
    return self;
}

- (void)dealloc {
    [tag release];
    [super dealloc];
}

+ (EmergencyDataManager *)managerForTag:(NSString *)tag {
	static NSMutableDictionary *managers = nil;
    if  (managers == nil) {
        managers = [NSMutableDictionary new];
    }
    if (![managers objectForKey:tag]) {
        EmergencyDataManager *manager = [[EmergencyDataManager alloc] initManagerWithTag:tag];
        [managers setObject:manager forKey:tag];
    }
    return [managers objectForKey:tag];
}

- (void)fetchLatestEmergencyNotice {
    KGORequest *request = [[KGORequestManager sharedManager] 
                           requestWithDelegate:self
                           module:tag
                           path:@"notice"
                           params:nil];
    
    request.expectedResponseType = [NSDictionary class];
    request.handler = [[^(id result) {
        int retval;
        NSDictionary *emergencyNoticeResult = (NSDictionary *)result;
        
        NSArray *cachedNotices = [self cachedNotices];
        [[CoreDataManager sharedManager] deleteObjects:cachedNotices];
            
        id notice = [emergencyNoticeResult objectForKey:@"notice"];
        if(notice != [NSNull null]) {
            NSDictionary *noticeDict = (NSDictionary *)notice;
            EmergencyNotice *noticeObject = [[CoreDataManager sharedManager] insertNewObjectForEntityForName:EmergencyNoticeEntityName];
            noticeObject.title = [noticeDict stringForKey:@"title" nilIfEmpty:YES];
            noticeObject.pubDate = [NSDate dateWithTimeIntervalSince1970:[[notice numberForKey:@"unixtime"] longValue]];
            noticeObject.html = [noticeDict stringForKey:@"text" nilIfEmpty:YES];
            noticeObject.moduleTag = tag;
            retval = EmergencyNoticeActive;
        } else {
            retval = NoCurrentEmergencyNotice;
        }
        
        [[CoreDataManager sharedManager] saveData];
        return retval;
    } copy] autorelease];
    
    [request connect];
}

- (NSArray *)cachedNotices {
    return [[CoreDataManager sharedManager] objectsForEntity:EmergencyNoticeEntityName matchingPredicate:[self tagPredicate]];
}

- (NSPredicate *)tagPredicate {
    return [NSPredicate predicateWithFormat:@"moduleTag == %@", tag];
}

- (EmergencyNotice *)latestEmergency {
    return [[self cachedNotices] lastObject];
}

#pragma KGORequestDelegate Methods

- (void)request:(KGORequest *)request didHandleResult:(NSInteger)returnValue { 
    if([request.path isEqualToString:@"notice"]) {
        NSMutableDictionary *userInfo = [NSMutableDictionary 
                                         dictionaryWithObject:[NSNumber numberWithInt:returnValue] 
                                         forKey:@"EmergencyStatus"];

        [[NSNotificationCenter defaultCenter] postNotificationName:EmergencyNoticeRetrievedNotification 
                                                            object:self 
                                                          userInfo:userInfo];
    }
}

-(void)requestWillTerminate:(KGORequest *)request {
    request.delegate = nil;
}
             
@end
