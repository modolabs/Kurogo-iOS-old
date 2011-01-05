#import "LibraryDataManager.h"
#import "CoreDataManager.h"
#import "Library.h"
#import "LibraryPhone.h"
#import "LibraryItemFormat.h"
#import "LibraryLocation.h"
#import "LibraryAlias.h"

// api names

NSString * const LibraryDataRequestLibraries = @"libraries";
NSString * const LibraryDataRequestArchives = @"archives";
NSString * const LibraryDataRequestOpenLibraries = @"opennow";
NSString * const LibraryDataRequestSearchCodes = @"searchcodes";
NSString * const LibraryDataRequestLibraryDetail = @"libdetail";
NSString * const LibraryDataRequestArchiveDetail = @"archivedetail";
NSString * const LibraryDataRequestAvailability = @"fullAvailability";
NSString * const LibraryDataRequestThumbnail = @"imagethumbnail";
NSString * const LibraryDataRequestSearch = @"search";

// notification names

NSString * const LibraryRequestDidCompleteNotification = @"libRequestComplete";
NSString * const LibraryRequestDidFailNotification = @"libRequestFailed";

// user defaults

NSString * const LibrariesLastUpdatedKey = @"librariesLastUpdated";
NSString * const ArchivesLastUpdatedKey = @"archivesLastUpdated";


NSInteger libraryNameSort(id lib1, id lib2, void *context) {
    
	LibraryAlias * library1 = (LibraryAlias *)lib1;
	LibraryAlias * library2 = (LibraryAlias *)lib2;
	
	return [library1.name compare:library2.name];
}


@interface LibraryDataManager (Private)

- (void)makeOneTimeRequestWithCommand:(NSString *)command;
//- (void)showAlertForFailedDispatch;

@end


@implementation LibraryDataManager

static LibraryDataManager *s_sharedManager = nil;

+ (LibraryDataManager *)sharedManager {
    if (s_sharedManager == nil) {
        s_sharedManager = [[LibraryDataManager alloc] init];
    }
    return s_sharedManager;
}

- (id)init {
    if (self = [super init]) {
        oneTimeRequests = [[NSMutableDictionary alloc] init];
        anytimeRequests = [[NSMutableArray alloc] init];
        
        _allLibraries = [[NSMutableArray alloc] init];
        _allArchives = [[NSMutableArray alloc] init];
        
        _allOpenLibraries = [[NSMutableArray alloc] init];
        _allOpenArchives = [[NSMutableArray alloc] init];
        
        _schedulesByLibID = [[NSMutableDictionary alloc] init];
        
        //delegates = [[NSMutableSet alloc] init];
        
        // fetch objects from core data
        NSDate *librariesDate = [[NSUserDefaults standardUserDefaults] objectForKey:LibrariesLastUpdatedKey];
        NSDate *archivesDate = [[NSUserDefaults standardUserDefaults] objectForKey:ArchivesLastUpdatedKey];
        
        BOOL isUpdated = YES;
        
        if (-[librariesDate timeIntervalSinceNow] < 24 * 60 * 60) {
            isUpdated = NO;
            [self requestLibraries];
        }

        if (-[archivesDate timeIntervalSinceNow] < 24 * 60 * 60) {
            isUpdated = NO;
            [self requestArchives];
        }
        
        if (isUpdated) {
            NSPredicate *matchAll = [NSPredicate predicateWithFormat:@"TRUEPREDICATE"];
            NSArray *tempArray = [CoreDataManager objectsForEntity:LibraryAliasEntityName matchingPredicate:matchAll];
            if (![tempArray count]) { // just in case they have nothing even with an updated date
                [self requestLibraries];
                [self requestArchives];
            } else {
                for(LibraryAlias *alias in tempArray) {
                    if ([alias.library.type isEqualToString:@"archive"]) {
                        [_allArchives addObject:alias];
                    }
                    else if ([alias.library.type isEqualToString: @"library"]) {
                        [_allLibraries addObject:alias];
                    }
                }
                
                [_allArchives sortUsingFunction:libraryNameSort context:nil];
                [_allLibraries sortUsingFunction:libraryNameSort context:nil];
                
                [self requestOpenLibraries];
            }
        }
    }
    return self;
}

- (NSArray *)allLibraries {
    return _allLibraries;
}

- (NSArray *)allOpenLibraries {
    return _allOpenLibraries;
}

- (NSArray *)allArchives {
    return _allArchives;
}

- (NSArray *)allOpenArchives {
    return _allOpenArchives;
}

- (Library *)libraryWithID:(NSString *)libID primaryName:(NSString *)primaryName {
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"identityTag like %@", libID];
    Library *library = [[CoreDataManager objectsForEntity:LibraryEntityName matchingPredicate:pred] lastObject];
    if (!library) {
        library = [CoreDataManager insertNewObjectForEntityForName:LibraryEntityName];
        library.identityTag = libID;
        library.isBookmarked = [NSNumber numberWithBool:NO];
        
        if (primaryName) {
            library.primaryName = primaryName;
            
            // make sure there is an alias whose display name is the primary name
            LibraryAlias *primaryAlias = [CoreDataManager insertNewObjectForEntityForName:LibraryAliasEntityName];
            primaryAlias.library = library;
            primaryAlias.name = library.primaryName;
            
            [CoreDataManager saveData];
        }
    }
    return library;
}

- (NSDictionary *)scheduleForLibID:(NSString *)libID {
    return [_schedulesByLibID objectForKey:libID];
}

- (LibraryAlias *)libraryAliasWithID:(NSString *)libID name:(NSString *)name {
    Library *theLibrary = [self libraryWithID:libID primaryName:nil];
    LibraryAlias *alias = nil;
    if (theLibrary) {
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"name like %@", name];
        alias = [[theLibrary.aliases filteredSetUsingPredicate:pred] anyObject];
        if (!alias) {
            alias = [CoreDataManager insertNewObjectForEntityForName:LibraryAliasEntityName];
            alias.library = theLibrary;
            alias.name = name;
            [CoreDataManager saveData];
        }
    }
    return alias;
}

#pragma mark -

- (void)makeOneTimeRequestWithCommand:(NSString *)command {
    JSONAPIRequest *api = [oneTimeRequests objectForKey:command];
    if (api) {
        [api abortRequest];
    }
    api = [JSONAPIRequest requestWithJSONAPIDelegate:self];
    api.userData = command;
    
    if ([api requestObjectFromModule:@"libraries" command:command parameters:nil]) {
        [oneTimeRequests setObject:api forKey:command];
    }
}

- (void)requestLibraries {
    [self makeOneTimeRequestWithCommand:LibraryDataRequestLibraries];
}

- (void)requestArchives {
    [self makeOneTimeRequestWithCommand:LibraryDataRequestArchives];
}

- (void)requestOpenLibraries {
    [self makeOneTimeRequestWithCommand:LibraryDataRequestOpenLibraries];
}

- (void)requestSearchCodes {
    [self makeOneTimeRequestWithCommand:LibraryDataRequestSearchCodes];
}

- (void)registerDelegate:(id<LibraryDataManagerDelegate>)aDelegate {
    [delegates addObject:aDelegate];
}

- (void)unregisterDelegate:(id<LibraryDataManagerDelegate>)aDelegate {
    [delegates removeObject:aDelegate];
}

- (void)requestDetailsForLibType:(NSString *)libOrArchive libID:(NSString *)libID libName:(NSString *)libName {
    if ([libOrArchive isEqualToString:@"library"])
        libOrArchive = LibraryDataRequestLibraryDetail;
    else if ([libOrArchive isEqualToString:@"archive"])
        libOrArchive = LibraryDataRequestArchiveDetail;
    
    JSONAPIRequest *api = [JSONAPIRequest requestWithJSONAPIDelegate:self];
    api.userData = libOrArchive;

    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:libID, @"id", libName, @"name", nil];
    if ([api requestObjectFromModule:@"libraries" command:libOrArchive parameters:params]) {
        [anytimeRequests addObject:api];
    }
}

- (void)requestFullAvailabilityForItem:(NSString *)itemID {
    JSONAPIRequest *api = [JSONAPIRequest requestWithJSONAPIDelegate:self];
    api.userData = LibraryDataRequestAvailability;
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:itemID, @"itemid", nil];
    if ([api requestObjectFromModule:@"libraries" command:LibraryDataRequestAvailability parameters:params]) {
        [anytimeRequests addObject:api];
    }
}

- (void)requestThumbnailForItem:(NSString *)itemID {
    JSONAPIRequest *api = [JSONAPIRequest requestWithJSONAPIDelegate:self];
    api.userData = LibraryDataRequestThumbnail;
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:itemID, @"itemid", nil];
    if ([api requestObjectFromModule:@"libraries" command:LibraryDataRequestThumbnail parameters:params]) {
        [anytimeRequests addObject:api];
    }
}

- (void)searchLibraries:(NSString *)searchTerms {
    JSONAPIRequest *api = [JSONAPIRequest requestWithJSONAPIDelegate:self];
    api.userData = LibraryDataRequestSearch;
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:searchTerms, @"q", nil];
    if ([api requestObjectFromModule:@"libraries" command:LibraryDataRequestSearch parameters:params]) {
        [anytimeRequests addObject:api];
    }
}

#pragma mark -
#pragma mark JSONAPIDelegate

- (void)request:(JSONAPIRequest *)request jsonLoaded:(id)JSONObject {
    NSString *command = request.userData;
    
#pragma mark libraries/archives API
    if ([command isEqualToString:LibraryDataRequestLibraries] || [command isEqualToString:LibraryDataRequestArchives]) {
        
        // TODO: if user has libraries cached, check for obsoleted libraries and delete them
        
        if ([JSONObject isKindOfClass:[NSArray class]] && [(NSArray *)JSONObject count]) {
            NSArray *resultArray = (NSArray *)JSONObject;
            
            if ([command isEqualToString:LibraryDataRequestLibraries]) {
                [_allLibraries release];
                _allLibraries = [[NSMutableArray alloc] init];
            } else {
                [_allArchives release];
                _allArchives = [[NSMutableArray alloc] init];
            }
            
            for (NSInteger index=0; index < [resultArray count]; index++) {
                
                NSDictionary *libraryDictionary = [resultArray objectAtIndex:index];
                
                NSString * name = [libraryDictionary objectForKey:@"name"];
                NSString * primaryName = [libraryDictionary objectForKey:@"primaryName"];
                NSString * identityTag = [libraryDictionary objectForKey:@"id"];
                NSNumber * latitude = [libraryDictionary objectForKey:@"latitude"];
                NSNumber * longitude = [libraryDictionary objectForKey:@"longitude"];
                NSString * location = [libraryDictionary objectForKey:@"address"];
                
                NSString * type = [libraryDictionary objectForKey:@"type"];
                
                //NSPredicate *pred = [NSPredicate predicateWithFormat:@"identityTag like %@", identityTag];
                
                Library *library = [self libraryWithID:identityTag primaryName:primaryName];
                // if library was just created in core data, the following properties will be saved when alias is created
                library.location = location;
                library.lat = [NSNumber numberWithDouble:[latitude doubleValue]];
                library.lon = [NSNumber numberWithDouble:[longitude doubleValue]];
                library.type = type;
                
                LibraryAlias *alias = [self libraryAliasWithID:identityTag name:name];
                /*
                Library *alreadyInDB = [[CoreDataManager objectsForEntity:LibraryEntityName matchingPredicate:pred] lastObject];
                
                if (!alreadyInDB) {
                    alreadyInDB = [CoreDataManager insertNewObjectForEntityForName:LibraryEntityName];
                    alreadyInDB.identityTag = identityTag;
                    alreadyInDB.isBookmarked = [NSNumber numberWithBool:NO];

                    alreadyInDB.primaryName = primaryName;
                    alreadyInDB.location = location;
                    alreadyInDB.lat = [NSNumber numberWithDouble:[latitude doubleValue]];
                    alreadyInDB.lon = [NSNumber numberWithDouble:[longitude doubleValue]];
                    alreadyInDB.type = type;
                    
                    [CoreDataManager saveData];
                }
                
                pred = [NSPredicate predicateWithFormat:@"name like %@", name];
                LibraryAlias *alias = [[alreadyInDB.aliases filteredSetUsingPredicate:pred] anyObject];
                if (!alias) {
                    alias = [CoreDataManager insertNewObjectForEntityForName:LibraryAliasEntityName];
                    alias.library = alreadyInDB;
                    alias.name = name;
                    [CoreDataManager saveData];
                }
                */
                if ([command isEqualToString:LibraryDataRequestLibraries]) {
                    [_allLibraries addObject:alias];
                } else {
                    [_allArchives addObject:alias];
                }
                
                NSString *isOpenNow = [libraryDictionary objectForKey:@"isOpenNow"];
                BOOL isOpen = [isOpenNow isEqualToString:@"YES"];
                
                if (isOpen) {
                    if ([command isEqualToString:LibraryDataRequestLibraries]) {
                        [_allOpenLibraries addObject:alias];
                    } else {
                        [_allOpenArchives addObject:alias];
                    }
                }
                
            }
            
            if ([command isEqualToString:LibraryDataRequestLibraries]) {
                [_allLibraries sortUsingFunction:libraryNameSort context:nil];
                [_allOpenLibraries sortUsingFunction:libraryNameSort context:nil];
            } else {
                [_allArchives sortUsingFunction:libraryNameSort context:nil];
                [_allOpenArchives sortUsingFunction:libraryNameSort context:nil];
            }
        }
        
        if ([command isEqualToString:LibraryDataRequestLibraries]) {
            [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:LibrariesLastUpdatedKey];
        } else {
            [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:ArchivesLastUpdatedKey];
        }
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [oneTimeRequests removeObjectForKey:command];
        
    }
#pragma mark opennow API
    else if ([command isEqualToString:LibraryDataRequestOpenLibraries]) {
        
        if ([JSONObject isKindOfClass:[NSArray class]]) {
            
            NSArray *resultArray = (NSArray *)JSONObject;
            
            for (int index=0; index < [resultArray count]; index++) {
                NSDictionary *libraryDictionary = [resultArray objectAtIndex:index];
                
                NSString * name = [libraryDictionary objectForKey:@"name"];
                NSString * identityTag = [libraryDictionary objectForKey:@"id"];		
                NSString * type = [libraryDictionary objectForKey:@"type"];
                
                //NSPredicate *pred = [NSPredicate predicateWithFormat:@"identityTag like %@", identityTag];
                Library *library = [self libraryWithID:identityTag primaryName:nil];
                library.type = type; // saveData will be called if the alias we create below is new
                LibraryAlias *alias = [self libraryAliasWithID:identityTag name:name];
                
                /*
                Library *alreadyInDB = [[CoreDataManager objectsForEntity:LibraryEntityName matchingPredicate:pred] lastObject];
                if (!alreadyInDB) {
                    alreadyInDB = [CoreDataManager insertNewObjectForEntityForName:LibraryEntityName];
                    alreadyInDB.identityTag = identityTag;
                    alreadyInDB.isBookmarked = [NSNumber numberWithBool:NO];
                    alreadyInDB.type = type;

                    [CoreDataManager saveData];
                }
                
                pred = [NSPredicate predicateWithFormat:@"name like %@", name];
                LibraryAlias *alias = [[alreadyInDB.aliases filteredSetUsingPredicate:pred] anyObject];
                if (!alias) {
                    alias = [CoreDataManager insertNewObjectForEntityForName:LibraryAliasEntityName];
                    alias.library = alreadyInDB;
                    alias.name = name;
                    [CoreDataManager saveData];
                }
                */
                
                NSString *isOpenNow = [libraryDictionary objectForKey:@"isOpenNow"];
                BOOL isOpen = [isOpenNow isEqualToString:@"YES"];
                
                if (isOpen) {
                    if ([type isEqualToString:@"library"]) {
                        [_allOpenLibraries addObject:alias];
                    } else if ([type isEqualToString:@"archive"]) {
                        [_allOpenArchives addObject:alias];
                    }
                }
            }
            
            [_allOpenLibraries sortUsingFunction:libraryNameSort context:self];
            [_allOpenArchives sortUsingFunction:libraryNameSort context:self];
            
            [oneTimeRequests removeObjectForKey:command];
            
        }
    }
#pragma mark searchcodes API
    else if ([command isEqualToString:LibraryDataRequestSearchCodes]) {
        
        if ([JSONObject isKindOfClass:[NSDictionary class]]) {
            NSInteger i;
            NSDictionary *dictionaryResults = (NSDictionary *)JSONObject;
            
            NSDictionary *formatCodes = [dictionaryResults objectForKey:@"formats"];
            NSDictionary *locationCodes = [dictionaryResults objectForKey:@"locations"];
            
            if (formatCodes) {
                NSInteger count = [formatCodes count];
                NSArray *codes = [formatCodes allKeys];
                for (i = 0; i < count; i++) {
                    NSString *code = [codes objectAtIndex:i];
                    NSString *name = [formatCodes objectForKey: code];
                    
                    NSPredicate *pred = [NSPredicate predicateWithFormat:@"code == %@", code];
                    LibraryItemFormat *alreadyInDB = [[CoreDataManager objectsForEntity:LibraryFormatCodeEntityName matchingPredicate:pred] lastObject];
                    
                    if (nil == alreadyInDB) {
                        alreadyInDB = [CoreDataManager insertNewObjectForEntityForName:LibraryFormatCodeEntityName];
                    }
                    
                    alreadyInDB.code = code;
                    alreadyInDB.name = name;
                }
            }
            
            if (locationCodes) {
                NSInteger count = [locationCodes count];
                NSArray *codes = [locationCodes allKeys];
                for (i = 0; i < count; i++) {
                    NSString *code = [codes objectAtIndex:i];
                    NSString *name = [locationCodes objectForKey: code];
                    
                    NSPredicate *pred = [NSPredicate predicateWithFormat:@"code == %@", code];
                    LibraryLocation *alreadyInDB = [[CoreDataManager objectsForEntity:LibraryLocationCodeEntityName matchingPredicate:pred] lastObject];
                    
                    if (nil == alreadyInDB) {
                        alreadyInDB = [CoreDataManager insertNewObjectForEntityForName:LibraryLocationCodeEntityName];
                    }
                    
                    alreadyInDB.code = code;
                    alreadyInDB.name = name;
                }
            }
        }
        
        [CoreDataManager saveData];
        
        [oneTimeRequests removeObjectForKey:command];

    }
#pragma mark libdetail/archivedetail API
    else if ([command isEqualToString:LibraryDataRequestLibraryDetail] || [command isEqualToString:LibraryDataRequestArchiveDetail]) {
        
        if ([JSONObject isKindOfClass:[NSDictionary class]]) {
        
            // cached library info
            
            NSDictionary *libraryDictionary = (NSDictionary *)JSONObject;
            
            NSString *identityTag = [libraryDictionary objectForKey:@"id"];
            NSString *name = [libraryDictionary objectForKey:@"name"];
            NSString *primaryName = [libraryDictionary objectForKey:@"primaryname"];
            NSString *directions = [libraryDictionary objectForKey:@"directions"];
            NSString *website = [libraryDictionary objectForKey:@"website"];
            NSString *email = [libraryDictionary objectForKey:@"email"];            
            NSArray * phoneNumberArray = (NSArray *)[libraryDictionary objectForKey:@"phone"];

            Library *lib = [self libraryWithID:identityTag primaryName:primaryName];
            
            /*
            NSPredicate *pred = [NSPredicate predicateWithFormat:@"identityTag like %@", identityTag];
            
            Library *lib = [[CoreDataManager objectsForEntity:LibraryEntityName matchingPredicate:pred] lastObject];
            if (!lib) {
                lib = [CoreDataManager insertNewObjectForEntityForName:LibraryEntityName];
                lib.identityTag = identityTag;
                lib.isBookmarked = [NSNumber numberWithBool:NO];
            }

            
            pred = [NSPredicate predicateWithFormat:@"name like %@", name];
            LibraryAlias *alias = [[lib.aliases filteredSetUsingPredicate:pred] anyObject];
            if (!alias) {
                alias = [CoreDataManager insertNewObjectForEntityForName:LibraryAliasEntityName];
                alias.library = lib;
                alias.name = name;
            }
            
            
            directions = [directions stringByReplacingOccurrencesOfString:@"\n" withString:@""];
            
            lib.primaryName = primaryName;
            */
            
            [self libraryAliasWithID:identityTag name:name];
            
            lib.websiteLib = website;
            lib.emailLib = email;
            lib.directions = directions;
            
            if ([lib.phone count])
                [lib removePhone:lib.phone];
            
            
            NSInteger phoneCount = 0;
            for(NSDictionary * phNbr in phoneNumberArray) {
                
                LibraryPhone * phone = [CoreDataManager insertNewObjectForEntityForName:LibraryPhoneEntityName];
                phone.descriptionText = [phNbr objectForKey:@"description"];
                
                NSString *phNumber = [phNbr objectForKey:@"number"];
				
				if (phNumber.length == 8) {
					phNumber = [NSString stringWithFormat:@"617-%@", phNumber];
				} 
                
                phone.phoneNumber = phNumber;
                phone.sortOrder = [NSNumber numberWithInt:phoneCount];
                phoneCount++;
                
                if (![lib.phone containsObject:phone])
                    [lib addPhoneObject:phone];
                
            }
            
            [CoreDataManager saveData];
            
            // library schedule
            
            NSMutableDictionary *schedule = [NSMutableDictionary dictionary];
            id value = [libraryDictionary objectForKey:@"weeklyHours"];
            if (value)
                [schedule setObject:value forKey:@"weeklyHours"];
            if (value = [libraryDictionary objectForKey:@"hoursOfOperationString"])
                [schedule setObject:value forKey:@"hoursOfOperationString"];

            [_schedulesByLibID setObject:schedule forKey:identityTag];
        }
        
        [anytimeRequests removeObject:request];
        
    }
#pragma mark fullAvailability API
    else if ([command isEqualToString:LibraryDataRequestAvailability]) {
        /*
		if ([JSONObject isKindOfClass:[NSArray class]]) {
			
			for (NSDictionary * tempDict in (NSArray *)JSONObject) {
				
				NSString * displayName = [tempDict objectForKey:@"name"];
                NSString * identityTag = [tempDict objectForKey:@"id"];
                NSString * type        = [tempDict objectForKey:@"type"];
                
                //NSDictionary * collection = [tempDict objectForKey:@"collection"];
                
                NSPredicate *pred = [NSPredicate predicateWithFormat:@"id == %@", identityTag, type];
                Library *alreadyInDB = [[CoreDataManager objectsForEntity:LibraryEntityName matchingPredicate:pred] lastObject];
                if (!alreadyInDB) {
                    alreadyInDB = (Library *)[CoreDataManager insertNewObjectForEntityForName:LibraryEntityName];
                    alreadyInDB.isBookmarked = [NSNumber numberWithBool:NO];
                    [CoreDataManager saveData];
                }
			}
        }
        */
        
        [anytimeRequests removeObject:request];

    }
#pragma mark imagethumbnail API
    else if ([command isEqualToString:LibraryDataRequestThumbnail]) {
        
        [anytimeRequests removeObject:request];

    }
#pragma mark search API
    else if ([command isEqualToString:LibraryDataRequestSearch]) {
        
        [anytimeRequests removeObject:request];
    } else {
        
        return;
    }
    
    
    // notify observers of success
    
    NSNotification *success = [NSNotification notificationWithName:LibraryRequestDidCompleteNotification object:command];
    [[NSNotificationCenter defaultCenter] postNotification:success];
    
    /*
    for (id<LibraryDataManagerDelegate> aDelegate in delegates) {
        [aDelegate requestDidSucceedForCommand:command];
    }
    */
}

- (BOOL)request:(JSONAPIRequest *)request shouldDisplayAlertForError:(NSError *)error {
    return YES;
}

- (void)request:(JSONAPIRequest *)request handleConnectionError:(NSError *)error {
    NSString *command = request.userData;
    
    if ([command isEqualToString:LibraryDataRequestLibraries]
        || [command isEqualToString:LibraryDataRequestOpenLibraries]
        || [command isEqualToString:LibraryDataRequestSearchCodes])
    {
        [oneTimeRequests removeObjectForKey:command];
        
    } else if ([command isEqualToString:LibraryDataRequestLibraryDetail]
               || [command isEqualToString:LibraryDataRequestArchiveDetail]
               || [command isEqualToString:LibraryDataRequestAvailability]
               || [command isEqualToString:LibraryDataRequestThumbnail]
               || [command isEqualToString:LibraryDataRequestSearch])
    {
        [anytimeRequests removeObject:request];
        
    } else {
        
        return;
    }
    
    NSNotification *failure = [NSNotification notificationWithName:LibraryRequestDidFailNotification object:command];
    [[NSNotificationCenter defaultCenter] postNotification:failure];
    
    //for (id<LibraryDataManagerDelegate> aDelegate in delegates) {
    //    [aDelegate requestDidFailForCommand:command];
    //}
}

/*
- (void)showAlertForFailedDispatch {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Connection Failed", nil)
                                                        message:NSLocalizedString(@"Could not connect to server. Please try again later.", nil)
                                                       delegate:nil 
                                              cancelButtonTitle:@"OK" 
                                              otherButtonTitles:nil];
    [alertView show];
    [alertView release];
}
*/

- (void)dealloc {
    for (JSONAPIRequest *api in anytimeRequests) {
        api.jsonDelegate = nil;
    }
    for (JSONAPIRequest *api in [oneTimeRequests allValues]) {
        api.jsonDelegate = nil;
    }
    [anytimeRequests release];
    [oneTimeRequests release];

    [_schedulesByLibID release];
    [_allOpenArchives release];
    [_allOpenLibraries release];
    [super dealloc];
}

@end
