#import "PeopleRecentsData.h"
#import "CoreDataManager.h"

@implementation PeopleRecentsData

@synthesize recents, displayFields;

static PeopleRecentsData *instance = nil;

#pragma mark Singleton Boilerplate

+ (PeopleRecentsData *)sharedData
{
	if (instance == nil) {
		instance = [[super allocWithZone:NULL] init];
	}
	return instance;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [[self sharedData] retain];	
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)retain
{
    return self;	
}

- (NSUInteger)retainCount
{
    return NSUIntegerMax;  //denotes an object that cannot be released	
}

- (void)release
{
    //do nothing	
}

- (id)autorelease
{
    return self;	
}

#pragma mark -
#pragma mark Core data interface

+ (PersonDetails *)personWithUID:(NSString *)uid
{
	PersonDetails *person = [CoreDataManager getObjectForEntity:PersonDetailsEntityName attribute:@"uid" value:uid];
	return person;
}

- (id)init
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *ldapDisplayFile = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"ldapDisplayFields.plist"];
    displayFields = [[NSDictionary dictionaryWithContentsOfFile:ldapDisplayFile] retain];
    BOOL needsUpdate = YES;
    if (displayFields != nil) {
        NSError *error = nil;
        NSDictionary *fileInfo = [[NSFileManager defaultManager] attributesOfItemAtPath:ldapDisplayFile error:&error];
        if (fileInfo && [[NSDate date] timeIntervalSinceDate:[fileInfo objectForKey:NSFileModificationDate]] <= 86400) {
            needsUpdate = NO;
        }
    }
    
    if (needsUpdate) {
        JSONAPIRequest *request = [JSONAPIRequest requestWithJSONAPIDelegate:self];
        [request requestObjectFromModule:@"people" command:@"displayFields" parameters:nil];
    }
    
	recents = [[NSMutableArray alloc] initWithCapacity:0];
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"lastUpdate" ascending:NO];
	for (PersonDetails *person in [CoreDataManager fetchDataForAttribute:PersonDetailsEntityName 
														  sortDescriptor:sortDescriptor]) {
		// if the person's result was viewed over X days ago, remove it
		if ([[person valueForKey:@"lastUpdate"] timeIntervalSinceNow] < -1500000) {
			[CoreDataManager deleteObject:person]; // this invokes saveData
		} else {
			[recents addObject:person]; // store in memory
		}
	}
    [CoreDataManager saveData];
	[sortDescriptor release];
	return self;
}

+ (void)eraseAll
{
    [CoreDataManager deleteObjects:[[self sharedData] recents]];
    [CoreDataManager saveData];
	[[[self sharedData] recents] removeAllObjects];
}

// TODO: this should become an instance method of PersonDetails
// rather than a method that modifies PersonDetails objects as a side effect
+ (PersonDetails *)updatePerson:(PersonDetails *)personDetails withSearchResult:(NSDictionary *)searchResult
{    
    
    // TODO: sanity test to make sure at least the uid and something else (sn probably) has a value
    
	[personDetails setValue:[NSDate date] forKey:@"lastUpdate"];
	
    NSArray *fetchTags = [[[PeopleRecentsData sharedData] displayFields] allKeys];
    
	for (NSString *key in fetchTags) {
        // if someone has multiple emails/phones join them into a string
        id value = [searchResult objectForKey:key];
        if ([value isKindOfClass:[NSArray class]]) {
            value = [PersonDetails joinedValueFromPersonDetailsJSONDict:searchResult forKey:key];
        }   
        
		if ([value isKindOfClass:[NSString class]]) {
			[personDetails setValue:value forKey:key];
		}        
	}
    
    NSLog(@"%@", [personDetails description]);

	// the "id" field we receive from mobi is either the unix uid (more
	// common) or something derived from another field (ldap "dn"), the
	// former has an 8 char limit but the uids that come from some LDAP servers  
	// will sometimes have a non-unique first eight characters. So, we used to 
	// trim it down to 8, but now we let it go longer.
	personDetails.uid = [PersonDetails trimUID:[personDetails valueForKey:@"uid"]];;
	
	// put latest person on top; remove if the person is already there
	NSMutableArray *recentsData = [[self sharedData] recents];
	for (NSInteger i = 0; i < [recentsData count]; i++) {
		PersonDetails *oldPerson = [recentsData objectAtIndex:i];
		if ([[oldPerson valueForKey:@"uid"] isEqualToString:[personDetails valueForKey:@"uid"]]) {
			[recentsData removeObjectAtIndex:i];
			break;
		}
	}
	[recentsData insertObject:personDetails atIndex:0];
	
	[CoreDataManager saveData];
	
	return personDetails;
}


+ (PersonDetails *)createFromSearchResult:(NSDictionary *)searchResult 
{
	
	PersonDetails *personDetails = (PersonDetails *)[CoreDataManager insertNewObjectForEntityForName:PersonDetailsEntityName];
	
	[self updatePerson:personDetails withSearchResult:searchResult];
	
	return personDetails;
}

- (void)request:(JSONAPIRequest *)request jsonLoaded:(id)result {
    if (result && [result isKindOfClass:[NSDictionary class]]) {
        displayFields = [result retain];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *ldapDisplayFile = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"ldapDisplayFields.plist"];
        BOOL saved = [displayFields writeToFile:ldapDisplayFile atomically:YES];
        if (!saved) {
            NSLog(@"could not save file with contents %@", [displayFields description]);
        }
    }
}

@end
