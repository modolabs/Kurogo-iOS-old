#import "PeopleDataManager.h"
#import "KGORequestManager.h"
#import "CoreDataManager.h"
#import "PeopleModel.h"
#import "Foundation+KGOAdditions.h"

#define STATIC_CONTACTS_CACHE_TIME 72

@implementation PeopleDataManager

@synthesize staticContactsRequest, groupContactsRequest;
@synthesize staticContacts;
@synthesize moduleTag;
@synthesize delegate;

- (void)fetchStaticContacts
{
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"person = nil AND contactGroup = nil"];
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES];
    NSArray *contacts = [[CoreDataManager sharedManager] objectsForEntity:PersonContactEntityName
                                                        matchingPredicate:pred
                                                          sortDescriptors:[NSArray arrayWithObject:sort]];
    
    sort = [NSSortDescriptor sortDescriptorWithKey:@"sortOrder" ascending:YES];
    NSArray *contactGroups = [[CoreDataManager sharedManager] objectsForEntity:PersonContactGroupEntityName
                                                             matchingPredicate:nil
                                                               sortDescriptors:[NSArray arrayWithObject:sort]];

    if (contacts.count) {
        self.staticContacts = [contacts arrayByAddingObjectsFromArray:contactGroups];
    } else if (contactGroups.count) {
        self.staticContacts = contactGroups;
    }
    
    if (self.staticContacts.count) {
        [self.delegate dataManager:self didReceiveContacts:self.staticContacts];
    }
    
    self.staticContactsRequest = [[KGORequestManager sharedManager] requestWithDelegate:self
                                                                                 module:self.moduleTag
                                                                                   path:@"contacts"
                                                                                version:1
                                                                                 params:nil];

    if (self.staticContacts.count) {
        self.staticContactsRequest.minimumDuration = STATIC_CONTACTS_CACHE_TIME;
    }
    self.staticContactsRequest.expectedResponseType = [NSDictionary class];
    [self.staticContactsRequest connect];
}

- (void)fetchContactsForGroup:(NSString *)groupID
{
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"person = nil AND contactGroup.identifier = %@", groupID];
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES];
    NSArray *contacts = [[CoreDataManager sharedManager] objectsForEntity:PersonContactEntityName
                                                        matchingPredicate:pred
                                                          sortDescriptors:[NSArray arrayWithObject:sort]];
    if (contacts.count) {
        [self.delegate dataManager:self didReceiveContacts:contacts];
    }

    NSDictionary *params = [NSDictionary dictionaryWithObject:groupID forKey:@"group"];
    self.groupContactsRequest = [[KGORequestManager sharedManager] requestWithDelegate:self
                                                                                module:self.moduleTag
                                                                                  path:@"contacts"
                                                                               version:1
                                                                                params:params];

    if (contacts.count) {
        self.groupContactsRequest.minimumDuration = STATIC_CONTACTS_CACHE_TIME;
    }
    [self.groupContactsRequest connect];
}

#pragma mark - KGORequestDelegate

- (void)requestWillTerminate:(KGORequest *)request
{
    if (request == self.staticContactsRequest) {
        self.staticContactsRequest = nil;
    } else if (request == self.groupContactsRequest) {
        self.groupContactsRequest = nil;
    }
}

- (void)request:(KGORequest *)request didReceiveResult:(id)result
{
    PersonContactGroup *parentGroup = nil;
    if (request == self.staticContactsRequest) {
        // TODO: make sure there are no race conditions with deleted objects
        for (NSManagedObject *anObject in self.staticContacts) {
            [[CoreDataManager sharedManager] deleteObject:anObject];
        }

    } else if (request == self.groupContactsRequest) {
        NSString *groupID = [request.getParams objectForKey:@"group"];
        parentGroup = [PersonContactGroup contactGroupWithID:groupID];
        for (NSManagedObject *anObject in parentGroup.contacts) {
            [[CoreDataManager sharedManager] deleteObject:anObject];
        }
        parentGroup.contacts = nil;
    }

    NSArray *contactDicts = [result arrayForKey:@"results"];
    NSMutableArray *contacts = [NSMutableArray array];

    NSInteger sortOrder = 0;
    for (NSDictionary *contactDict in contactDicts) {
        NSString *group = [contactDict nonemptyStringForKey:@"group"];
        if (group) {
            PersonContactGroup *contactGroup = [PersonContactGroup contactGroupWithDict:contactDict];
            contactGroup.sortOrder = [NSNumber numberWithInt:sortOrder];
            [contacts addObject:contactGroup];
            
        } else {
            NSString *type = [contactDict nonemptyStringForKey:@"type"];
            if (!type) {
                type = [contactDict nonemptyStringForKey:@"class"];
            }
            
            PersonContact *aContact = [PersonContact personContactWithDictionary:contactDict
                                                                            type:type];

            // this shouldn't conflict with regular contacts since we distinguish
            // them using whether or not a KGOPerson is attached
            aContact.identifier = [NSString stringWithFormat:@"%d", sortOrder];
            if (parentGroup) {
                aContact.contactGroup = parentGroup;
            }
            [contacts addObject:aContact];
        }
        sortOrder++;
    }
    
    [[CoreDataManager sharedManager] saveData];

    if (request == self.staticContactsRequest) {
        self.staticContacts = contacts;
        [self.delegate dataManager:self didReceiveContacts:self.staticContacts];

    } else if (request == self.groupContactsRequest) {
        [self.delegate dataManager:self didReceiveContacts:contacts];
    }
}

#pragma mark -

- (void)dealloc
{
    [self.staticContactsRequest cancel];
    self.staticContactsRequest = nil;
    
    [self.groupContactsRequest cancel];
    self.groupContactsRequest = nil;
    
    self.staticContacts = nil;
    self.delegate = nil;
    
    [super dealloc];
}

@end
