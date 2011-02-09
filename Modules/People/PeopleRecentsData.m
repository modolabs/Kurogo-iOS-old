#import "PeopleRecentsData.h"
#import "CoreDataManager.h"

#define MAX_PEOPLE_RESULTS 25

NSString * const PeopleDisplayFieldsDidDownloadNotification = @"peopleDisplayFieldsDownloaded";

@implementation PeopleRecentsData

@synthesize recents;

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
	PersonDetails *person = [[CoreDataManager sharedManager] getObjectForEntity:PersonDetailsEntityName attribute:@"uid" value:uid];
	return person;
}

- (void)loadRecentsFromCache {
    recents = [[NSMutableArray alloc] initWithCapacity:0];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"viewed = YES"];
    NSArray *sort = [NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"lastUpdate" ascending:NO] autorelease]];
    for (PersonDetails *person in [[CoreDataManager sharedManager] objectsForEntity:PersonDetailsEntityName matchingPredicate:pred sortDescriptors:sort]) {
        [recents addObject:person];
    }
}

- (id)init
{
    if (self = [super init]) {
        [self displayFields];
        [self loadRecentsFromCache];
    }
	return self;
}

- (void)clearOldResults {
    // if the person's result was viewed over X days ago, remove it
    // TODO: configure these timeouts
    NSDate *timeout = [NSDate dateWithTimeIntervalSinceNow:-1500000];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"viewed = NO OR lastUpdate < %@", timeout];
    NSArray *sort = [NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"lastUpdate" ascending:NO] autorelease]];
    
    NSArray *results = [[CoreDataManager sharedManager] objectsForEntity:PersonDetailsEntityName matchingPredicate:pred sortDescriptors:sort];
    if (results.count > MAX_PEOPLE_RESULTS) {
        for (PersonDetails *person in [results subarrayWithRange:NSMakeRange(MAX_PEOPLE_RESULTS, results.count - MAX_PEOPLE_RESULTS)]) {
            [[CoreDataManager sharedManager] deleteObject:person];
        }
        [[CoreDataManager sharedManager] saveData];
    }
}

// TODO: make sure there aren't multiple simultaneous requests
- (NSDictionary *)displayFields
{
    if (!displayFields) {
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
    }
    return displayFields;
}

+ (void)eraseAll
{
    [[CoreDataManager sharedManager] deleteObjects:[[self sharedData] recents]];
    [[CoreDataManager sharedManager] saveData];
	[[[self sharedData] recents] removeAllObjects];
}

- (void)request:(JSONAPIRequest *)request jsonLoaded:(id)result {
    if (result && [result isKindOfClass:[NSDictionary class]]) {
        displayFields = [result retain];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *ldapDisplayFile = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"ldapDisplayFields.plist"];
        BOOL saved = [displayFields writeToFile:ldapDisplayFile atomically:YES];
        if (saved) {
            NSNotification *notification = [NSNotification notificationWithName:PeopleDisplayFieldsDidDownloadNotification object:self];
            [[NSNotificationCenter defaultCenter] postNotification:notification];
        } else {
            DLog(@"could not save file with contents %@", [displayFields description]);
        }
    }
}

@end
