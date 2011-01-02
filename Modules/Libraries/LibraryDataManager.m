#import "LibraryDataManager.h"
#import "CoreDataManager.h"
#import "Library.h"
#import "LibraryPhone.h"
#import "LibraryItemFormat.h"
#import "LibraryLocation.h"

// api names

NSString * const LibraryDataRequestLibraries = @"libraries";
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



NSInteger libraryNameSort(id lib1, id lib2, void *context) {
    
	Library * library1 = (Library *)lib1;
	Library * library2 = (Library *)lib2;
	
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
        
        _librariesByID = [[NSMutableDictionary alloc] init];
        _archivesByID = [[NSMutableDictionary alloc] init];
        _allOpenLibraries = [[NSMutableArray alloc] init];
        _allOpenArchives = [[NSMutableArray alloc] init];
        
        _schedulesByLibID = [[NSMutableDictionary alloc] init];
        
        //delegates = [[NSMutableSet alloc] init];
        
        // fetch objects from core data
        // TODO: update periodically from server instead of always trusting cache
        NSPredicate *matchAll = [NSPredicate predicateWithFormat:@"TRUEPREDICATE"];
        NSArray *tempArray = [CoreDataManager objectsForEntity:LibraryEntityName matchingPredicate:matchAll];
        if ([tempArray count]) {
            for(Library *aLibrary in tempArray) {
                if ([aLibrary.type isEqualToString:@"archive"])
                    [_archivesByID setObject:aLibrary forKey:aLibrary.identityTag];
                else if ([aLibrary.type isEqualToString: @"library"])
                    [_librariesByID setObject:aLibrary forKey:aLibrary.identityTag];
            }
        } else {
            [self requestLibraries];
        }
            
        [self requestOpenLibraries];
    }
    return self;
}

- (NSArray *)allLibraries {
    return [[_librariesByID allValues] sortedArrayUsingFunction:libraryNameSort context:self];
}

- (NSArray *)allOpenLibraries {
    return _allOpenLibraries;
}

- (NSArray *)allArchives {
    return [[_archivesByID allValues] sortedArrayUsingFunction:libraryNameSort context:self];
}

- (NSArray *)allOpenArchives {
    return _allOpenArchives;
}

- (Library *)libraryWithID:(NSString *)libID {
    Library *library = [_librariesByID objectForKey:libID];
    if (!library) {
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"identityTag like %@", libID];
        library = [[CoreDataManager objectsForEntity:LibraryEntityName matchingPredicate:pred] lastObject];
        if (library) {
            [_librariesByID setObject:library forKey:libID];
        }
    }
    return library;
}

- (NSDictionary *)scheduleForLibID:(NSString *)libID {
    return [_schedulesByLibID objectForKey:libID];
}

- (void)makeOneTimeRequestWithCommand:(NSString *)command {
    JSONAPIRequest *api = [oneTimeRequests objectForKey:command];
    if (!api) {
        api = [JSONAPIRequest requestWithJSONAPIDelegate:self];
        api.userData = command;
    }
    
    if ([api requestObjectFromModule:@"libraries" command:command parameters:nil]) {
        [oneTimeRequests setObject:api forKey:command];
    }
}

- (void)requestLibraries {
    [self makeOneTimeRequestWithCommand:LibraryDataRequestLibraries];
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
    
#pragma mark libraries API
    if ([command isEqualToString:LibraryDataRequestLibraries]) {
        
        // TODO: if user has libraries cached, check for obsoleted libraries and delete them
        
        if ([JSONObject isKindOfClass:[NSArray class]] && [(NSArray *)JSONObject count]) {
            NSArray *resultArray = (NSArray *)JSONObject;
            
            for (NSInteger index=0; index < [resultArray count]; index++) {
                
                NSDictionary *libraryDictionary = [resultArray objectAtIndex:index];
                
                NSString * name = [libraryDictionary objectForKey:@"name"];
                NSString * primaryName = [libraryDictionary objectForKey:@"primaryName"];
                NSString * identityTag = [libraryDictionary objectForKey:@"id"];
                NSNumber * latitude = [libraryDictionary objectForKey:@"latitude"];
                NSNumber * longitude = [libraryDictionary objectForKey:@"longitude"];
                NSString * location = [libraryDictionary objectForKey:@"address"];
                
                NSString * type = [libraryDictionary objectForKey:@"type"];
                
                // TODO: if this list is comprehensive, populate _openLibaries and _openArchives
                // otherwise ignore this flag
                NSString *isOpenNow = [libraryDictionary objectForKey:@"isOpenNow"];
                BOOL isOpen = [isOpenNow isEqualToString:@"YES"];
                
                //NSString *typeOfLib = [command isEqualToString:LibraryDataRequestLibraryDetail] ? @"library" : @"archive";
                
                //NSPredicate *pred = [NSPredicate predicateWithFormat:@"name == %@ AND type == %@", name, typeOfLib];
                NSPredicate *pred = [NSPredicate predicateWithFormat:@"identityTag like %@", identityTag];
                
                Library *alreadyInDB = [[CoreDataManager objectsForEntity:LibraryEntityName matchingPredicate:pred] lastObject];
                if (!alreadyInDB) {
                    alreadyInDB = [CoreDataManager insertNewObjectForEntityForName:LibraryEntityName];
                    alreadyInDB.identityTag = identityTag;
                    alreadyInDB.isBookmarked = [NSNumber numberWithBool:NO];
                }
                
                alreadyInDB.name = name;
                alreadyInDB.primaryName = primaryName;
                alreadyInDB.location = location;
                alreadyInDB.lat = [NSNumber numberWithDouble:[latitude doubleValue]];
                alreadyInDB.lon = [NSNumber numberWithDouble:[longitude doubleValue]];
                alreadyInDB.type = type;
                
                [CoreDataManager saveData];
                
                if ([type isEqualToString:@"library"]) {
                    [_librariesByID setObject:alreadyInDB forKey:identityTag];
                } else if ([type isEqualToString:@"archive"]) {
                    [_archivesByID setObject:alreadyInDB forKey:identityTag];
                }
                
                //if (isOpen) {
                //    [_allOpenLibraries addObject:alreadyInDB];
                //}
            }
        }
        
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
                
                NSString *isOpenNow = [libraryDictionary objectForKey:@"isOpenNow"];
                
                BOOL isOpen = [isOpenNow isEqualToString:@"YES"];
                
                //NSPredicate *pred = [NSPredicate predicateWithFormat:@"name == %@ AND type == %@", name, type];
                NSPredicate *pred = [NSPredicate predicateWithFormat:@"identityTag like %@", identityTag];
                Library *alreadyInDB = [[CoreDataManager objectsForEntity:LibraryEntityName matchingPredicate:pred] lastObject];
                if (!alreadyInDB) {
                    alreadyInDB = [CoreDataManager insertNewObjectForEntityForName:LibraryEntityName];
                    alreadyInDB.identityTag = identityTag;
                    alreadyInDB.isBookmarked = [NSNumber numberWithBool:NO];
                    alreadyInDB.name = name;
                    alreadyInDB.type = type;

                    [CoreDataManager saveData];
                }
                
                [_librariesByID setObject:alreadyInDB forKey:identityTag];
                if ([type isEqualToString:@"library"]) {
                    [_allOpenLibraries addObject:alreadyInDB];
                } else if ([type isEqualToString:@"archive"]) {
                    [_allOpenArchives addObject:alreadyInDB];
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
            NSPredicate *pred = [NSPredicate predicateWithFormat:@"identityTag like %@", identityTag];
            
            Library *lib = [[CoreDataManager objectsForEntity:LibraryEntityName matchingPredicate:pred] lastObject];
            if (!lib) {
                lib = [CoreDataManager insertNewObjectForEntityForName:LibraryEntityName];
                lib.identityTag = identityTag;
                lib.isBookmarked = [NSNumber numberWithBool:NO];
            }

            NSString *name = [libraryDictionary objectForKey:@"name"];
            NSString *primaryName = [libraryDictionary objectForKey:@"primaryname"];
            NSString *directions = [libraryDictionary objectForKey:@"directions"];
            NSString *website = [libraryDictionary objectForKey:@"website"];
            NSString *email = [libraryDictionary objectForKey:@"email"];
            
            NSArray * phoneNumberArray = (NSArray *)[libraryDictionary objectForKey:@"phone"];
            
            directions = [directions stringByReplacingOccurrencesOfString:@"\n" withString:@""];
            
            lib.name = name;
            lib.primaryName = primaryName;
            lib.websiteLib = website;
            lib.emailLib = email;
            lib.directions = directions;
            
            if ([lib.phone count])
                [lib removePhone:lib.phone];
            
            
            for(NSDictionary * phNbr in phoneNumberArray) {
                
                LibraryPhone * phone = [CoreDataManager insertNewObjectForEntityForName:LibraryPhoneEntityName];
                phone.descriptionText = [phNbr objectForKey:@"description"];
                
                NSString *phNumber = [phNbr objectForKey:@"number"];
				
				if (phNumber.length == 8) {
					phNumber = [NSString stringWithFormat:@"617-%@", phNumber];
				} 
                
                phone.phoneNumber = phNumber;
                
                if (![lib.phone containsObject:phone])
                    [lib addPhoneObject:phone];
                
            }
            
            [CoreDataManager saveData];
            
            [_librariesByID setObject:lib forKey:identityTag];
            
            // library schedule
            
            NSMutableDictionary *schedule = [NSMutableDictionary dictionary];
            id value = [libraryDictionary objectForKey:@"weeklyHours"];
            if (value)
                [schedule setObject:value forKey:@"weeklyHours"];
            if (value = [libraryDictionary objectForKey:@"hoursOfOperationString"])
                [schedule setObject:value forKey:@"hoursOfOperationString"];

            [_schedulesByLibID setObject:schedule forKey:identityTag];

            /*
            NSMutableDictionary *sched = [NSMutableDictionary dictionary];
            
            for (NSDictionary *wkSched in schedule) {
                NSString *day = [wkSched objectForKey:@"day"];
                NSString *hours = [wkSched objectForKey:@"hours"];
                [sched setObject:hours forKey:day];
            }
            
            NSMutableDictionary * tempDict = [NSMutableDictionary dictionary];
            
            if ([sched count] < 7){
                [tempDict setObject:[libraryDictionary objectForKey:@"hoursOfOperationString"] forKey:@"Hours"];
                
            } else {
                for (NSString * dayOfWeek in daysOfWeek) {
                    NSString *scheduleString = [sched objectForKey:dayOfWeek];
                    if (!scheduleString)
                        scheduleString = @"contact library/archive";
                    [tempDict setObject:scheduleString forKey:dayOfWeek];
                }
            }
            
            [_schedulesByLibID setObject:tempDict forKey:identityTag];
             */
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
    [_librariesByID release];
    [_archivesByID release];
    [_allOpenArchives release];
    [_allOpenLibraries release];
    [super dealloc];
}

@end
