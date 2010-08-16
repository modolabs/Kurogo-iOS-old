#import "EmergencyData.h"
#import "MIT_MobileAppDelegate.h"
#import "CoreDataManager.h"
#import "JSONAPIRequest.h"
#import "Foundation+MITAdditions.h"

@implementation EmergencyData

@synthesize primaryPhoneNumbers, allPhoneNumbers, infoConnection, contactsConnection;

@dynamic htmlString, lastUpdated, lastFetched;

#pragma mark -
#pragma mark Singleton Boilerplate

static EmergencyData *sharedEmergencyData = nil;

+ (EmergencyData *)sharedData {
    @synchronized(self) {
        if (sharedEmergencyData == nil) {
            sharedEmergencyData = [[super allocWithZone:NULL] init]; // assignment not done here
        }
    }
    return sharedEmergencyData;
}

+ (id)allocWithZone:(NSZone *)zone {
    return [[self sharedData] retain];
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (id)retain {
    return self;
}

- (unsigned)retainCount {
    return UINT_MAX;  //denotes an object that cannot be released
}

- (void)release {
    //do nothing
}

- (id)autorelease {
    return self;
}

#pragma mark -
#pragma mark Initialization

- (id) init {
    self = [super init];
    if (self != nil) {
        // TODO: get primary numbers (it's unlikely, but numbers might change)
        primaryPhoneNumbers = [[NSArray arrayWithObjects:
                                    [NSDictionary dictionaryWithObjectsAndKeys:
                                     @"Campus Police", @"title",
                                     @"555.555.5555", @"phone",
                                     nil],
                                    [NSDictionary dictionaryWithObjectsAndKeys:
                                     @"Medical", @"title",
                                     @"555.555.5555", @"phone",
                                     nil],
                                    [NSDictionary dictionaryWithObjectsAndKeys:
                                     @"Emergency Status", @"title",
                                     @"555.555.5555", @"phone",
                                     nil],
                                    nil] retain];
        [self fetchEmergencyInfo];
        [self fetchContacts];
        
        [self checkForEmergencies];
        [self reloadContacts];
    }
    return self;
}

- (void)fetchEmergencyInfo {
    info = [[[CoreDataManager fetchDataForAttribute:EmergencyInfoEntityName] lastObject] retain];
    if (!info) {
        info = [[CoreDataManager insertNewObjectForEntityForName:EmergencyInfoEntityName] retain];
        [info setValue:@"" forKey:@"htmlString"];
        [info setValue:[NSDate distantPast] forKey:@"lastUpdated"];
        [info setValue:[NSDate distantPast] forKey:@"lastFetched"];
    }
}

- (void)fetchContacts {
    NSPredicate *predicate = [NSPredicate predicateWithValue:YES];
    NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"ordinality" ascending:YES] autorelease];
    allPhoneNumbers = [[CoreDataManager objectsForEntity:EmergencyContactEntityName matchingPredicate:predicate sortDescriptors:[NSArray arrayWithObject:sortDescriptor]] retain];
    if (!allPhoneNumbers) {
        allPhoneNumbers = [[NSArray alloc] init];
    }
}


#pragma mark -
#pragma mark Accessors

- (BOOL) hasNeverLoaded {
	return ([[info valueForKey:@"htmlString"] length] == 0);
}

- (NSDate *)lastUpdated {
    return [info valueForKey:@"lastUpdated"];
}

- (NSDate *)lastFetched {
    return [info valueForKey:@"lastFetched"];
}

- (NSString *)htmlString {
    NSDate *lastUpdated = [info valueForKey:@"lastUpdated"];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"M/d/y h:m a zz"];
    [formatter setTimeZone:[NSTimeZone localTimeZone]];
    NSString *lastUpdatedString = [formatter stringFromDate:lastUpdated];
    [formatter release];
    
    NSURL *baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath] isDirectory:YES];
    NSURL *fileURL = [NSURL URLWithString:@"emergency/emergency_template.html" relativeToURL:baseURL];
    
    NSError *error = nil;
    NSMutableString *htmlString = [NSMutableString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:&error];
    if (!htmlString) {
        //NSLog(@"Failed to load template at %@. %@", fileURL, [error userInfo]);
        return nil;
    }
    
    NSArray *keys = [NSArray arrayWithObjects:@"__BODY__", @"__POST_DATE__", nil];
    
    NSArray *values = [NSArray arrayWithObjects:[info valueForKey:@"htmlString"], lastUpdatedString, nil];
    
    [htmlString replaceOccurrencesOfStrings:keys withStrings:values options:NSLiteralSearch];
    
    return htmlString;
}

#pragma mark -
#pragma mark Asynchronous HTTP - preferred

// Send request
- (void)checkForEmergencies {
    if (self.infoConnection) {
        return; // a connection already exists
    }
    self.infoConnection = [JSONAPIRequest requestWithJSONAPIDelegate:self];
    [self.infoConnection requestObject:[NSDictionary dictionaryWithObjectsAndKeys:@"emergency", @"module", nil]];
}

// request contacts
- (void)reloadContacts {
    if (self.contactsConnection) {
        return; // a connection already exists
    }
    self.contactsConnection = [JSONAPIRequest requestWithJSONAPIDelegate:self];
    [self.contactsConnection requestObjectFromModule:@"emergency" command:@"contacts" parameters:nil];
}

// Receive response
- (void)request:(JSONAPIRequest *)request jsonLoaded:(id)jsonObject {
    [(MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate] hideNetworkActivityIndicator];
    if (request == infoConnection) {
        self.infoConnection = nil;
        NSDictionary *response = nil;
        
        if (![jsonObject isKindOfClass:[NSArray class]]) {
            NSLog(@"%@ received json result as %@, not NSArray.", NSStringFromClass([self class]), NSStringFromClass([jsonObject class]));
        } else {
            response = [(NSArray *)jsonObject lastObject];
            
            NSDate *lastUpdated = [NSDate dateWithTimeIntervalSince1970:[[response objectForKey:@"unixtime"] doubleValue]];
            NSDate *previouslyUpdated = [info valueForKey:@"lastUpdated"];
            
            if (!previouslyUpdated || [lastUpdated timeIntervalSinceDate:previouslyUpdated] > 0) {
                [info setValue:lastUpdated forKey:@"lastUpdated"];
                [info setValue:[NSDate date] forKey:@"lastFetched"];
                [info setValue:[response objectForKey:@"text"] forKey:@"htmlString"];
                [CoreDataManager saveData];
                
                [self fetchEmergencyInfo];
                // notify listeners that this is a new emergency
                [[NSNotificationCenter defaultCenter] postNotificationName:EmergencyInfoDidChangeNotification object:self];
            }
            // notify listeners that the info is done loading, regardless of whether it's changed
            [[NSNotificationCenter defaultCenter] postNotificationName:EmergencyInfoDidLoadNotification object:self];
        }
    } else if (request == contactsConnection) {
        self.contactsConnection = nil;
        if (jsonObject && [jsonObject isKindOfClass:[NSArray class]]) {
            NSArray *contactsArray = (NSArray *)jsonObject;
            
            // delete all of the old numbers
            NSArray *oldContacts = [CoreDataManager fetchDataForAttribute:EmergencyContactEntityName];
            if ([oldContacts count] > 0) {
                [CoreDataManager deleteObjects:oldContacts];
            }
            
            // create new entry for each contact in contacts
            NSInteger i = 0;
            for (NSDictionary *contactDict in contactsArray) {
                NSManagedObject *contact = [CoreDataManager insertNewObjectForEntityForName:EmergencyContactEntityName];
                [contact setValue:[contactDict objectForKey:@"contact"] forKey:@"title"];
                [contact setValue:[contactDict objectForKey:@"description"] forKey:@"summary"];
                [contact setValue:[contactDict objectForKey:@"phone"] forKey:@"phone"];
                [contact setValue:[NSNumber numberWithInteger:i] forKey:@"ordinality"];
                i++;
            }
            [CoreDataManager saveData];
            [self fetchContacts];
            
            // notify listeners that contacts have finished loading
            [[NSNotificationCenter defaultCenter] postNotificationName:EmergencyContactsDidLoadNotification object:self];
        }
    }
    
    
}

- (void)handleConnectionFailureForRequest:(JSONAPIRequest *)request {
    [(MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate] hideNetworkActivityIndicator];
    // TODO: possibly retry at a later date if connection dropped or server was unavailable
    if (request == infoConnection) {
        self.infoConnection = nil;
		[[NSNotificationCenter defaultCenter] postNotificationName:EmergencyInfoDidFailToLoadNotification object:self];
    } else {
        self.contactsConnection = nil;
    }
}

#pragma mark -
#pragma mark Synchronous HTTP - less preferred

- (NSString *)stringWithUrl:(NSURL *)url
{
    NSString *result;
	NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url
                                                cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                            timeoutInterval:30];
    // Fetch the JSON response
	NSData *urlData;
	NSURLResponse *response;
	NSError *error;
    
	// Make synchronous request
	urlData = [NSURLConnection sendSynchronousRequest:urlRequest
                                    returningResponse:&response
                                                error:&error];
    
 	// Construct a String around the Data from the response
    result = [[NSString alloc] initWithData:urlData encoding:NSUTF8StringEncoding];
	return [result autorelease];
}

@end
