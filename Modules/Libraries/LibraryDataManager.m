#import "LibraryDataManager.h"
#import "CoreDataManager.h"
#import "Library.h"
#import "LibraryPhone.h"
#import "LibraryItemFormat.h"
#import "LibraryLocation.h"
#import "LibraryAlias.h"
#import "LibraryItem.h"

// api names

NSString * const LibraryDataRequestLibraries = @"libraries";
NSString * const LibraryDataRequestArchives = @"archives";
NSString * const LibraryDataRequestOpenLibraries = @"opennow";
NSString * const LibraryDataRequestSearchCodes = @"searchcodes";
NSString * const LibraryDataRequestLibraryDetail = @"libdetail";
NSString * const LibraryDataRequestArchiveDetail = @"archivedetail";
NSString * const LibraryDataRequestAvailability = @"fullavailability";
NSString * const LibraryDataRequestThumbnail = @"imagethumbnail";
NSString * const LibraryDataRequestItemDetail = @"itemdetail";
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
        
        delegates = [[NSMutableSet alloc] init];
        itemDelegates = [[NSMutableSet alloc] init];
        
        // fetch objects from core data
        NSDate *librariesDate = [[NSUserDefaults standardUserDefaults] objectForKey:LibrariesLastUpdatedKey];
        NSDate *archivesDate = [[NSUserDefaults standardUserDefaults] objectForKey:ArchivesLastUpdatedKey];
        
        BOOL isUpdated = YES;
        
        if (-[librariesDate timeIntervalSinceNow] > 24 * 60 * 60) {
            isUpdated = NO;
            [self requestLibraries];
        }

        if (-[archivesDate timeIntervalSinceNow] > 24 * 60 * 60) {
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

- (NSDictionary *)scheduleForLibID:(NSString *)libID {
    return [_schedulesByLibID objectForKey:libID];
}

#pragma mark Database methods

- (Library *)libraryWithID:(NSString *)libID type:(NSString *)type primaryName:(NSString *)primaryName {
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"identityTag like %@ AND type like %@", libID, type];
    Library *library = [[CoreDataManager objectsForEntity:LibraryEntityName matchingPredicate:pred] lastObject];
    if (!library) {
        library = [CoreDataManager insertNewObjectForEntityForName:LibraryEntityName];
        library.identityTag = libID;
        library.type = type;
        library.isBookmarked = [NSNumber numberWithBool:NO];
    }
    
    if (primaryName) {
        BOOL needTOSave = NO;
        if (!library.primaryName) {
            needTOSave = YES;
            library.primaryName = primaryName;
        }
        
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"name like %@", primaryName];
        LibraryAlias *primaryAlias = [[library.aliases filteredSetUsingPredicate:pred] anyObject];
        if (!primaryAlias) {
            // make sure there is an alias whose display name is the primary name
            primaryAlias = [CoreDataManager insertNewObjectForEntityForName:LibraryAliasEntityName];
            primaryAlias.library = library;
            primaryAlias.name = library.primaryName;
        }
        
        [CoreDataManager saveData];
    }
    
    return library;
}

- (LibraryAlias *)libraryAliasWithID:(NSString *)libID type:(NSString *)type name:(NSString *)name {
    Library *theLibrary = [self libraryWithID:libID type:type primaryName:nil];
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


- (LibraryItem *)libraryItemWithID:(NSString *)itemID {
	NSPredicate *pred = [NSPredicate predicateWithFormat:@"itemId == %@", itemID];
	LibraryItem *libItem = (LibraryItem *)[[CoreDataManager objectsForEntity:LibraryItemEntityName matchingPredicate:pred] lastObject];
    if (!libItem) {
        libItem = (LibraryItem *)[CoreDataManager insertNewObjectForEntityForName:LibraryItemEntityName];
        libItem.itemId = itemID;
        libItem.isBookmarked = [NSNumber numberWithBool:NO];
        [CoreDataManager saveData];
    }
    return libItem;
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

- (void)registerItemDelegate:(id<LibraryItemDetailDelegate>)aDelegate {
    [itemDelegates addObject:aDelegate];
}

- (void)unregisterItemDelegate:(id<LibraryItemDetailDelegate>)aDelegate {
    [itemDelegates removeObject:aDelegate];
}

- (void)requestDetailsForLibType:(NSString *)libOrArchive libID:(NSString *)libID libName:(NSString *)libName {
    if ([libOrArchive isEqualToString:@"library"])
        libOrArchive = LibraryDataRequestLibraryDetail;
    else if ([libOrArchive isEqualToString:@"archive"])
        libOrArchive = LibraryDataRequestArchiveDetail;
    
    JSONAPIRequest *api = [oneTimeRequests objectForKey:libOrArchive];
    if (api) {
        [api abortRequest];
    }
    
    api = [JSONAPIRequest requestWithJSONAPIDelegate:self];
    api.userData = libOrArchive;

    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:libID, @"id", libName, @"name", nil];
    if ([api requestObjectFromModule:@"libraries" command:libOrArchive parameters:params]) {
        [oneTimeRequests setObject:api forKey:libOrArchive];
        //[anytimeRequests addObject:api];
    }
}

- (void)requestDetailsForItem:(LibraryItem *)item {
    JSONAPIRequest *api = [oneTimeRequests objectForKey:LibraryDataRequestItemDetail];
    if (api) {
        [api abortRequest];
    }
    
    api = [JSONAPIRequest requestWithJSONAPIDelegate:self];
    api.userData = LibraryDataRequestItemDetail;
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:item.itemId, @"itemId", nil];
    if ([api requestObjectFromModule:@"libraries" command:LibraryDataRequestItemDetail parameters:params]) {
        [oneTimeRequests setObject:api forKey:LibraryDataRequestItemDetail];
        //[anytimeRequests addObject:api];
    }
}

- (void)requestFullAvailabilityForItem:(NSString *)itemID {
    JSONAPIRequest *api = [oneTimeRequests objectForKey:LibraryDataRequestAvailability];
    if (api) {
        [api abortRequest];
    }
    
    api = [JSONAPIRequest requestWithJSONAPIDelegate:self];
    api.userData = LibraryDataRequestAvailability;
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:itemID, @"itemId", nil];
    if ([api requestObjectFromModule:@"libraries" command:LibraryDataRequestAvailability parameters:params]) {
        [oneTimeRequests setObject:api forKey:LibraryDataRequestAvailability];
        //[anytimeRequests addObject:api];
    }
}

- (void)requestThumbnailForItem:(NSString *)itemID {
    JSONAPIRequest *api = [oneTimeRequests objectForKey:LibraryDataRequestThumbnail];
    if (api) {
        [api abortRequest];
    }
    
    api = [JSONAPIRequest requestWithJSONAPIDelegate:self];
    api.userData = LibraryDataRequestThumbnail;
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:itemID, @"itemId", nil];
    if ([api requestObjectFromModule:@"libraries" command:LibraryDataRequestThumbnail parameters:params]) {
        [oneTimeRequests setObject:api forKey:LibraryDataRequestThumbnail];
        //[anytimeRequests addObject:api];
    }
}

- (void)searchLibraries:(NSString *)searchTerms {
    JSONAPIRequest *api = [oneTimeRequests objectForKey:LibraryDataRequestSearch];
    if (api) {
        [api abortRequest];
    }
    
    api = [JSONAPIRequest requestWithJSONAPIDelegate:self];
    api.userData = LibraryDataRequestSearch;
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:searchTerms, @"q", nil];
    if ([api requestObjectFromModule:@"libraries" command:LibraryDataRequestSearch parameters:params]) {
        [oneTimeRequests setObject:api forKey:LibraryDataRequestSearch];
        //[anytimeRequests addObject:api];
    }
}

#pragma mark -

// TODO: skip to failed state if any isKindOfClass sanity check fails

- (void)request:(JSONAPIRequest *)request jsonLoaded:(id)JSONObject {
    NSString *command = request.userData;
    
#pragma mark Success - Libraries/Archives
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
                NSString * primaryName = [libraryDictionary objectForKey:@"primaryname"];
                NSString * identityTag = [libraryDictionary objectForKey:@"id"];
                NSNumber * latitude = [libraryDictionary objectForKey:@"latitude"];
                NSNumber * longitude = [libraryDictionary objectForKey:@"longitude"];
                NSString * location = [libraryDictionary objectForKey:@"address"];
                
                NSString * type = [libraryDictionary objectForKey:@"type"];
                
                Library *library = [self libraryWithID:identityTag type:type primaryName:primaryName];
                // if library was just created in core data, the following properties will be saved when alias is created
                library.location = location;
                library.lat = [NSNumber numberWithDouble:[latitude doubleValue]];
                library.lon = [NSNumber numberWithDouble:[longitude doubleValue]];
                library.type = type;
                
                LibraryAlias *alias = [self libraryAliasWithID:identityTag type:type name:name];
                if ([command isEqualToString:LibraryDataRequestLibraries]) {
                    [_allLibraries addObject:alias];
                } else {
                    [_allArchives addObject:alias];
                }
                
                NSString *isOpenNow = [libraryDictionary objectForKey:@"isOpenNow"];
                BOOL isOpen = [isOpenNow boolValue];
                
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
#pragma mark Success - Open Now
    else if ([command isEqualToString:LibraryDataRequestOpenLibraries]) {
        
        if ([JSONObject isKindOfClass:[NSArray class]]) {
            
            NSArray *resultArray = (NSArray *)JSONObject;
            
            for (int index=0; index < [resultArray count]; index++) {
                NSDictionary *libraryDictionary = [resultArray objectAtIndex:index];
                
                NSString * name = [libraryDictionary objectForKey:@"name"];
                NSString * identityTag = [libraryDictionary objectForKey:@"id"];
                NSString * type = [libraryDictionary objectForKey:@"type"];
                
                Library *library = [self libraryWithID:identityTag type:type primaryName:nil];
                library.type = type; // saveData will be called if the alias we create below is new
                LibraryAlias *alias = [self libraryAliasWithID:identityTag type:type name:name];
                
                NSString *isOpenNow = [libraryDictionary objectForKey:@"isOpenNow"];
                BOOL isOpen = [isOpenNow boolValue];
                
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
#pragma mark Success - Search Codes
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
#pragma mark Success - Library/Archive Detail
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
            NSString *type = [libraryDictionary objectForKey:@"type"];

            Library *lib = [self libraryWithID:identityTag type:type primaryName:primaryName];
            
            [self libraryAliasWithID:identityTag type:type name:name];
            
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
            if (value = [libraryDictionary objectForKey:@"hrsOpenToday"])
                [schedule setObject:value forKey:@"hrsOpenToday"];

            [_schedulesByLibID setObject:schedule forKey:identityTag];
        }
        
        //[anytimeRequests removeObject:request];
        [oneTimeRequests removeObjectForKey:command];
        
    }
#pragma mark Success - Item Detail
    else if ([command isEqualToString:LibraryDataRequestItemDetail]) {
        
		if ([JSONObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *result = (NSDictionary *)JSONObject;
            
            NSString *itemID = [result objectForKey:@"itemId"];
            LibraryItem *libItem = [self libraryItemWithID:itemID];
            libItem.title = [result objectForKey:@"title"];
            libItem.author = [result objectForKey:@"creator"];
            libItem.authorLink = [result objectForKey:@"creatorLink"];
            libItem.year = [result objectForKey:@"date"];
            libItem.publisher = [result objectForKey:@"publisher"];
            libItem.edition = [result objectForKey:@"edition"];

            NSNumber *numberOfImages = [result objectForKey:@"numberofimages"];
            if ([numberOfImages integerValue]) {
                libItem.numberOfImages = [NSNumber numberWithInt:[numberOfImages integerValue]];
            }
            
            NSString *workType = [result objectForKey:@"worktype"];
            if ([workType length]) {
                libItem.workType = workType;
            }
            
            NSString *thumbnail = [result objectForKey:@"thumbnail"];
            if ([thumbnail length]) {
                libItem.thumbnailURL = thumbnail;
                
                if (![libItem thumbnailImage]) {
                    [libItem requestImage];
                }
            }
            
            NSString *fullImageLink = [result objectForKey:@"fullimagelink"];
            if ([fullImageLink length]) {
                libItem.fullImageLink = fullImageLink;
            }
            
            NSString *catalogLink = [result objectForKey:@"cataloglink"];
            if ([catalogLink length]) {
                libItem.catalogLink = catalogLink;
            }
            
            NSDictionary *formatDict = [result objectForKey:@"format"];
            if ([formatDict isKindOfClass:[NSDictionary class]]) {
                libItem.formatDetail = [formatDict objectForKey:@"formatDetail"];
                libItem.typeDetail = [formatDict objectForKey:@"typeDetail"];
            }
            
            [CoreDataManager saveData];
                        
            for (id<LibraryItemDetailDelegate> aDelegate in itemDelegates) {
                [aDelegate detailsDidLoadForItem:libItem];
            }
		}
        
        //[anytimeRequests removeObject:request];
        [oneTimeRequests removeObjectForKey:command];
        
    }
#pragma mark Success - Item Availability
    else if ([command isEqualToString:LibraryDataRequestAvailability]) {

		if ([JSONObject isKindOfClass:[NSArray class]]) {
			
			for (NSDictionary * tempDict in (NSArray *)JSONObject) {
				NSString * displayName = [tempDict objectForKey:@"name"];
                NSString * identityTag = [tempDict objectForKey:@"id"];
                NSString * type        = [tempDict objectForKey:@"type"];
                
                Library *lib = [self libraryWithID:identityTag type:type primaryName:nil];
                [self libraryAliasWithID:identityTag type:type name:displayName];
                
                if ([lib.lat doubleValue] == 0) {
                    [self requestDetailsForLibType:type libID:identityTag libName:displayName];
                }
			}
            
            NSString *itemID = [request.params objectForKey:@"itemId"];
            
            for (id<LibraryItemDetailDelegate> aDelegate in itemDelegates) {
                [aDelegate availabilityDidLoadForItemID:itemID result:(NSArray *)JSONObject];
            }
        }
        
        //[anytimeRequests removeObject:request];
        [oneTimeRequests removeObjectForKey:command];

    }
#pragma mark Success - Image Thumbnail
    else if ([command isEqualToString:LibraryDataRequestThumbnail]) {
        
		if ([JSONObject isKindOfClass:[NSDictionary class]]){
            
            NSDictionary *result = (NSDictionary *)JSONObject;
			
            NSString *itemID = [result objectForKey:@"itemId"];
            
            LibraryItem *libItem = [self libraryItemWithID:itemID];
			NSString * catLink = [result objectForKey:@"cataloglink"];

            if ([catLink length]) {
                libItem.catalogLink = catLink;
            }
            
			libItem.fullImageLink = [[result objectForKey:@"fullimagelink"] retain];
            libItem.workType = [result objectForKey:@"worktype"];
            libItem.numberOfImages = [NSNumber numberWithInt:[[result objectForKey:@"numberofimages"] integerValue]];
			libItem.thumbnailURL = [result objectForKey:@"thumbnail"];
            
            if ([libItem.thumbnailURL length]) {
                if (![libItem thumbnailImage]) {
                    [libItem requestImage];
                }
            }
            
            //for (id<LibraryItemDetailDelegate> aDelegate in itemDelegates) {
            //    [aDelegate thumbnailDidLoadForItem:itemID result:libItem];
            //}
		}
        
        //[anytimeRequests removeObject:request];
        [oneTimeRequests removeObjectForKey:command];

    }
#pragma mark Success - Search
    else if ([command isEqualToString:LibraryDataRequestSearch]) {
        
        //[anytimeRequests removeObject:request];
        [oneTimeRequests removeObjectForKey:command];
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

#pragma mark -

- (void)request:(JSONAPIRequest *)request handleConnectionError:(NSError *)error {
    NSString *command = request.userData;
#pragma mark Failure - Item Availability
    if ([command isEqualToString:LibraryDataRequestAvailability]) {
        NSString *itemID = [request.params objectForKey:@"itemId"];
        
        for (id<LibraryItemDetailDelegate> aDelegate in itemDelegates) {
            [aDelegate availabilityFailedToLoadForItemID:itemID];
        }
#pragma mark Failure - Image Thumbnail
    } else if ([command isEqualToString:LibraryDataRequestThumbnail]) {
        //NSString *itemID = [request.params objectForKey:@"itemid"];
        
        //for (id<LibraryItemDetailDelegate> aDelegate in itemDelegates) {
        //    [aDelegate thumbnailFailedToLoadForItemID:itemID];
        //}
#pragma mark Failure - Item Detail
    } else if ([command isEqualToString:LibraryDataRequestItemDetail]) {
        NSString *itemID = [request.params objectForKey:@"itemId"];
        
        for (id<LibraryItemDetailDelegate> aDelegate in itemDelegates) {
            [aDelegate detailsFailedToLoadForItemID:itemID];
        }
        
    } else if ([command isEqualToString:LibraryDataRequestLibraries]
        || [command isEqualToString:LibraryDataRequestOpenLibraries]
        || [command isEqualToString:LibraryDataRequestSearchCodes])
    {
        [oneTimeRequests removeObjectForKey:command];
        
    } else if ([command isEqualToString:LibraryDataRequestLibraryDetail]
               || [command isEqualToString:LibraryDataRequestArchiveDetail]
               || [command isEqualToString:LibraryDataRequestSearch])
    {
        //[anytimeRequests removeObject:request];
        [oneTimeRequests removeObjectForKey:command];
        
    } else {
        
        return;
    }
    
    NSNotification *failure = [NSNotification notificationWithName:LibraryRequestDidFailNotification object:command];
    [[NSNotificationCenter defaultCenter] postNotification:failure];
    
    //for (id<LibraryDataManagerDelegate> aDelegate in delegates) {
    //    [aDelegate requestDidFailForCommand:command];
    //}
}

- (void)dealloc {
    for (JSONAPIRequest *api in anytimeRequests) {
        api.jsonDelegate = nil;
    }
    for (JSONAPIRequest *api in [oneTimeRequests allValues]) {
        api.jsonDelegate = nil;
    }
    [anytimeRequests release];
    [oneTimeRequests release];

    [delegates release];
    [itemDelegates release];

    [_schedulesByLibID release];
    [_allOpenArchives release];
    [_allOpenLibraries release];
    [super dealloc];
}

@end
