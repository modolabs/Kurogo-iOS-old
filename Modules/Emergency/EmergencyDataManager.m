#import "EmergencyDataManager.h"
#import "Foundation+KGOAdditions.h"
#import "CoreDataManager.h"

#define CONTACTS_EXPIRE 60 

NSString * const EmergencyNoticeRetrievedNotification = @"EmergencyNoticeRetrieved";
NSString * const EmergencyContactsRetrievedNotification = @"EmergencyContactsRetrieved";

@interface EmergencyDataManager (Private) 

- (id)initManagerWithTag:(NSString *) tag;
- (NSArray *)cachedNotices;
- (NSPredicate *)tagPredicate;

- (EmergencyContactsSection *)contactsSection:(NSString *)section;

@end

@implementation EmergencyDataManager

- (id)initManagerWithTag:(NSString *)aTag {
    self = [super init];
    if (self) {
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
        EmergencyDataManager *manager = [[[EmergencyDataManager alloc] initManagerWithTag:tag] autorelease];
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

- (BOOL)contactsFresh {
    EmergencyContactsSection *primary = [self contactsSection:@"primary"];
    if (primary) {
        return (-[primary.lastUpdate timeIntervalSinceNow] < CONTACTS_EXPIRE);
    } else {
        return NO;
    }
}
- (void)fetchContacts {
    KGORequest *request = [[KGORequestManager sharedManager] 
                           requestWithDelegate:self
                           module:tag
                           path:@"contacts"
                           params:nil];
    
    request.expectedResponseType = [NSDictionary class];
    request.handler = [[^(id result) {
        NSDictionary *emergencyContactsResult = (NSDictionary *)result;
        
        // delete old contacts
        EmergencyContactsSection *primary = [self contactsSection:@"primary"];
        EmergencyContactsSection *secondary = [self contactsSection:@"secondary"];
        if (primary) {
            [[CoreDataManager sharedManager] deleteObject:primary];
        }
        if (secondary) {
            [[CoreDataManager sharedManager] deleteObject:secondary];
        }
        
        for (NSString *sectionKey in [emergencyContactsResult allKeys]) {
            // create contacts section
            NSArray *contacts = [emergencyContactsResult objectForKey:sectionKey];
            EmergencyContactsSection *section = [[CoreDataManager sharedManager] insertNewObjectForEntityForName:EmergencyContactsSectionEntityName];
            section.moduleTag = tag;
            section.sectionTag = sectionKey;
            section.lastUpdate = [NSDate date];
            
            // create contacts
            for (int i=0; i < contacts.count; i++) {
                NSDictionary *contactDict = [contacts objectAtIndex:i];
                EmergencyContact *contact = [[CoreDataManager sharedManager] insertNewObjectForEntityForName:EmergencyContactEntityName];
                contact.title = [contactDict stringForKey:@"title" nilIfEmpty:NO];
                contact.subtitle = [contactDict stringForKey:@"subtitle" nilIfEmpty:YES];
                contact.formattedPhone = [contactDict stringForKey:@"formattedPhone" nilIfEmpty:NO];
                contact.dialablePhone = [contactDict stringForKey:@"dialablePhone" nilIfEmpty:NO];
                contact.order = [NSNumber numberWithInt:i];
                contact.section = section;
            }
        }
        
        [[CoreDataManager sharedManager] saveData];
        
        // return the number of sections created
        return [[emergencyContactsResult allKeys] count];
    } copy] autorelease];
    
    [request connect];    
}

- (EmergencyContactsSection *)contactsSection:(NSString *)section {
    NSPredicate *sectionPredicate = [NSPredicate predicateWithFormat:@"moduleTag == %@ AND sectionTag == %@", tag, section];
    NSArray *sections = [[CoreDataManager sharedManager] objectsForEntity:EmergencyContactsSectionEntityName matchingPredicate:sectionPredicate];
    return [sections lastObject];
}

- (NSArray *)contactsForSection:(NSString *)section {
    EmergencyContactsSection *contactsSection = [self contactsSection:section];
    
    if(contactsSection) {
        NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES];
        NSArray *descriptors = [NSArray arrayWithObject:descriptor];
        return [contactsSection.contacts sortedArrayUsingDescriptors:descriptors];
    } else {
        return nil;
    }
}

- (NSArray *)primaryContacts {
    return [self contactsForSection:@"primary"];
}

- (BOOL)hasSecondaryContacts {
    return ([self contactsForSection:@"secondary"] != nil);
}

- (NSArray *)allContacts {
    NSArray *contacts = [self primaryContacts];
    return [contacts arrayByAddingObjectsFromArray:[self contactsForSection:@"secondary"]];
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
        
    } else if([request.path isEqualToString:@"contacts"]) {
        // we have the number of sections created we could possibly pass it on
        [[NSNotificationCenter defaultCenter] postNotificationName:EmergencyContactsRetrievedNotification 
                                                            object:self];
    }
}

-(void)requestWillTerminate:(KGORequest *)request {
    request.delegate = nil;
}
             
@end
