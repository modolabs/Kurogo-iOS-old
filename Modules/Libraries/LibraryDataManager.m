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
//NSString * const LibraryDataRequestOldAvailability = @"fullavailability";
NSString * const LibraryDataRequestThumbnail = @"imagethumbnail";
NSString * const LibraryDataRequestItemDetail = @"itemdetail";
NSString * const LibraryDataRequestSearch = @"search";
NSString * const LibraryDataRequestFullAvailability = @"itemavailability";
NSString * const LibraryDataRequestAvailability = @"itemavailabilitysummary";

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

@end


@implementation LibraryDataManager

@synthesize itemDelegate, availabilityDelegate, libDelegate;

static LibraryDataManager *s_sharedManager = nil;

+ (LibraryDataManager *)sharedManager {
    if (s_sharedManager == nil) {
        s_sharedManager = [[LibraryDataManager alloc] init];
    }
    return s_sharedManager;
}

- (id)init {
    if (self = [super init]) {
        activeRequests = [[NSMutableDictionary alloc] init];
        
        _allLibraries = [[NSMutableArray alloc] init];
        _allArchives = [[NSMutableArray alloc] init];
        
        _allOpenLibraries = [[NSMutableArray alloc] init];
        //_allOpenArchives = [[NSMutableArray alloc] init];
        
        _schedulesByLibID = [[NSMutableDictionary alloc] init];
        
        [self updateLibraryList];
    }
    return self;
}

- (void)updateLibraryList {
    
    // fetch objects from core data
    NSDate *librariesDate = [[NSUserDefaults standardUserDefaults] objectForKey:LibrariesLastUpdatedKey];
    NSDate *archivesDate = [[NSUserDefaults standardUserDefaults] objectForKey:ArchivesLastUpdatedKey];
    
    if (librariesDate && -[librariesDate timeIntervalSinceNow] <= 24 * 60 * 60) {
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"library.type like 'library'"];
        NSArray *tempArray = [CoreDataManager objectsForEntity:LibraryAliasEntityName matchingPredicate:pred];
        for (LibraryAlias *alias in tempArray) {
            [_allLibraries addObject:alias];
        }
        [_allLibraries sortUsingFunction:libraryNameSort context:nil];
    } else {
        // get rid of library items that aren't bookmarked
        NSPredicate *notBookmarked = [NSPredicate predicateWithFormat:@"type like 'library' AND isBookmarked != YES"];
        NSArray *discardLibItems = [CoreDataManager objectsForEntity:LibraryEntityName matchingPredicate:notBookmarked];
        [CoreDataManager deleteObjects:discardLibItems];
    }
    
    if (archivesDate && -[archivesDate timeIntervalSinceNow] <= 24 * 60 * 60) {
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"library.type like 'archive'"];
        NSArray *tempArray = [CoreDataManager objectsForEntity:LibraryAliasEntityName matchingPredicate:pred];
        for (LibraryAlias *alias in tempArray) {
            [_allArchives addObject:alias];
        }
        [_allArchives sortUsingFunction:libraryNameSort context:nil];
    } else {
        NSPredicate *notBookmarked = [NSPredicate predicateWithFormat:@"type like 'archive' AND isBookmarked != YES"];
        NSArray *discardLibItems = [CoreDataManager objectsForEntity:LibraryEntityName matchingPredicate:notBookmarked];
        [CoreDataManager deleteObjects:discardLibItems];
    }
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

//- (NSArray *)allOpenArchives {
//    return _allOpenArchives;
//}

- (NSDictionary *)scheduleForLibID:(NSString *)libID {
    return [_schedulesByLibID objectForKey:libID];
}

#pragma mark Database methods

- (Library *)libraryWithID:(NSString *)libID type:(NSString *)type primaryName:(NSString *)primaryName {
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"identityTag like %@ AND type like %@", libID, type];
    Library *library = [[CoreDataManager objectsForEntity:LibraryEntityName matchingPredicate:pred] lastObject];
    BOOL needToSave = NO;
    if (!library) {
        library = [CoreDataManager insertNewObjectForEntityForName:LibraryEntityName];
        library.identityTag = libID;
        library.type = type;
        library.isBookmarked = [NSNumber numberWithBool:NO];
        needToSave = YES;
    }
    
    if (primaryName) {
        if (!library.primaryName) {
            needToSave = YES;
            library.primaryName = primaryName;
        }
        
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"name like %@", primaryName];
        LibraryAlias *primaryAlias = [[library.aliases filteredSetUsingPredicate:pred] anyObject];
        if (!primaryAlias) {
            needToSave = YES;
            // make sure there is an alias whose display name is the primary name
            primaryAlias = [CoreDataManager insertNewObjectForEntityForName:LibraryAliasEntityName];
            primaryAlias.library = library;
            primaryAlias.name = library.primaryName;
        }
    }
    
    if (needToSave) {
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

#pragma mark Request methods

- (void)makeOneTimeRequestWithCommand:(NSString *)command {
    JSONAPIRequest *api = [activeRequests objectForKey:command];
    if (api) {
        [api abortRequest];
    }
    api = [JSONAPIRequest requestWithJSONAPIDelegate:self];
    api.userData = command;
    
    if ([api requestObjectFromModule:@"libraries" command:command parameters:nil]) {
        [activeRequests setObject:api forKey:command];
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

- (void)requestDetailsForLibType:(NSString *)libOrArchive libID:(NSString *)libID libName:(NSString *)libName {
    if ([libOrArchive isEqualToString:@"library"])
        libOrArchive = LibraryDataRequestLibraryDetail;
    else if ([libOrArchive isEqualToString:@"archive"])
        libOrArchive = LibraryDataRequestArchiveDetail;
    
    JSONAPIRequest *api = [activeRequests objectForKey:libOrArchive];
    if (api) {
        [api abortRequest];
    }
    
    api = [JSONAPIRequest requestWithJSONAPIDelegate:self];
    api.userData = libOrArchive;

    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:libID, @"id", libName, @"name", nil];
    if ([api requestObjectFromModule:@"libraries" command:libOrArchive parameters:params]) {
        [activeRequests setObject:api forKey:libOrArchive];
    }
}

- (void)requestDetailsForItem:(LibraryItem *)item {
    JSONAPIRequest *api = [activeRequests objectForKey:LibraryDataRequestItemDetail];
    if (api) {
        [api abortRequest];
    }
    
    api = [JSONAPIRequest requestWithJSONAPIDelegate:self];
    api.userData = LibraryDataRequestItemDetail;
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:item.itemId, @"itemId", nil];
    if ([api requestObjectFromModule:@"libraries" command:LibraryDataRequestItemDetail parameters:params]) {
        [activeRequests setObject:api forKey:LibraryDataRequestItemDetail];
    }
}
/*
- (void)requestOldAvailabilityForItem:(NSString *)itemID {
    JSONAPIRequest *api = [activeRequests objectForKey:LibraryDataRequestOldAvailability];
    if (api) {
        [api abortRequest];
    }
    
    api = [JSONAPIRequest requestWithJSONAPIDelegate:self];
    api.userData = LibraryDataRequestOldAvailability;
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:itemID, @"itemId", nil];
    if ([api requestObjectFromModule:@"libraries" command:LibraryDataRequestOldAvailability parameters:params]) {
        [activeRequests setObject:api forKey:LibraryDataRequestOldAvailability];
    }
}
*/
- (void)requestAvailabilityForItem:(NSString *)itemID {
    JSONAPIRequest *api = [activeRequests objectForKey:LibraryDataRequestAvailability];
    if (api) {
        [api abortRequest];
    }
    
    api = [JSONAPIRequest requestWithJSONAPIDelegate:self];
    api.userData = LibraryDataRequestAvailability;
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:itemID, @"itemId", nil];
    if ([api requestObjectFromModule:@"libraries" command:LibraryDataRequestAvailability parameters:params]) {
        [activeRequests setObject:api forKey:LibraryDataRequestAvailability];
    }
}

- (void)requestFullAvailabilityForItem:(NSString *)itemID {
    JSONAPIRequest *api = [activeRequests objectForKey:LibraryDataRequestFullAvailability];
    if (api) {
        [api abortRequest];
    }
    
    api = [JSONAPIRequest requestWithJSONAPIDelegate:self];
    api.userData = LibraryDataRequestFullAvailability;
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:itemID, @"itemId", nil];
    if ([api requestObjectFromModule:@"libraries" command:LibraryDataRequestFullAvailability parameters:params]) {
        [activeRequests setObject:api forKey:LibraryDataRequestFullAvailability];
    }
}

- (void)requestThumbnailForItem:(NSString *)itemID {
    JSONAPIRequest *api = [activeRequests objectForKey:LibraryDataRequestThumbnail];
    if (api) {
        [api abortRequest];
    }
    
    api = [JSONAPIRequest requestWithJSONAPIDelegate:self];
    api.userData = LibraryDataRequestThumbnail;
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:itemID, @"itemId", nil];
    if ([api requestObjectFromModule:@"libraries" command:LibraryDataRequestThumbnail parameters:params]) {
        [activeRequests setObject:api forKey:LibraryDataRequestThumbnail];
    }
}

- (void)searchLibraries:(NSString *)searchTerms {
    JSONAPIRequest *api = [activeRequests objectForKey:LibraryDataRequestSearch];
    if (api) {
        [api abortRequest];
    }
    
    api = [JSONAPIRequest requestWithJSONAPIDelegate:self];
    api.userData = LibraryDataRequestSearch;
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:searchTerms, @"q", nil];
    if ([api requestObjectFromModule:@"libraries" command:LibraryDataRequestSearch parameters:params]) {
        [activeRequests setObject:api forKey:LibraryDataRequestSearch];
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
                    }// else {
                    //    [_allOpenArchives addObject:alias];
                    //}
                }
                
            }
            
            if ([command isEqualToString:LibraryDataRequestLibraries]) {
                [_allLibraries sortUsingFunction:libraryNameSort context:nil];
                [_allOpenLibraries sortUsingFunction:libraryNameSort context:nil];
            } else {
                [_allArchives sortUsingFunction:libraryNameSort context:nil];
                //[_allOpenArchives sortUsingFunction:libraryNameSort context:nil];
            }
        }
        
        if ([command isEqualToString:LibraryDataRequestLibraries]) {
            [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:LibrariesLastUpdatedKey];
        } else {
            [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:ArchivesLastUpdatedKey];
        }
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [activeRequests removeObjectForKey:command];
        
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
                    }// else if ([type isEqualToString:@"archive"]) {
                    //    [_allOpenArchives addObject:alias];
                    //}
                }
            }
            
            [_allOpenLibraries sortUsingFunction:libraryNameSort context:self];
            //[_allOpenArchives sortUsingFunction:libraryNameSort context:self];
            
            [activeRequests removeObjectForKey:command];
            
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
        
        [activeRequests removeObjectForKey:command];

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
            
            [self.libDelegate detailsDidLoadForLibrary:identityTag type:type];
        }
        
        [activeRequests removeObjectForKey:command];
        
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
            
            NSArray *identifier = [result objectForKey:@"identifier"];
            for (NSDictionary *aDict in identifier) {
                if ([[aDict objectForKey:@"type"] isEqualToString:@"NET"]) {
                    libItem.onlineLink = [aDict objectForKey:@"typeDetail"];
                }
            }
            
            [CoreDataManager saveData];
            
            [self.itemDelegate detailsDidLoadForItem:libItem];
		}
        
        [activeRequests removeObjectForKey:command];
        
    }
    /*
#pragma mark Success - Item Availability (old)
    else if ([command isEqualToString:LibraryDataRequestOldAvailability]) {
        
        NSMutableArray *filteredResults = [NSMutableArray array];

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
                
                if (![displayName isEqualToString:@"Networked Resource"]) {
                    [filteredResults addObject:tempDict];
                }
			}
            
            NSString *itemID = [request.params objectForKey:@"itemId"];
            
            for (id<LibraryItemDetailDelegate> aDelegate in itemDelegates) {
                [aDelegate availabilityDidLoadForItemID:itemID result:filteredResults];
            }
        }
        
        [activeRequests removeObjectForKey:command];

    }
    */
#pragma mark Success - Full Availability
    else if ([command isEqualToString:LibraryDataRequestFullAvailability]) {
        
        NSMutableArray *filteredResults = [NSMutableArray array];
        
		if ([JSONObject isKindOfClass:[NSDictionary class]]) {
            NSString *itemID = [(NSDictionary *)JSONObject objectForKey:@"id"];
            NSArray *institutions = [(NSDictionary *)JSONObject objectForKey:@"institutions"];
            
            for (NSDictionary *institutionData in institutions) {
				NSString * displayName = [institutionData objectForKey:@"name"];
                NSString * identityTag = [institutionData objectForKey:@"id"];
                NSString * type        = [institutionData objectForKey:@"type"];
                
                Library *lib = [self libraryWithID:identityTag type:type primaryName:nil];
                [self libraryAliasWithID:identityTag type:type name:displayName];
                
                if ([lib.lat doubleValue] == 0) {
                    [self requestDetailsForLibType:type libID:identityTag libName:displayName];
                }
                
                if (![displayName isEqualToString:@"Networked Resource"]) {
                    [filteredResults addObject:institutionData];
                }
			}
            
            [self.availabilityDelegate fullAvailabilityDidLoadForItemID:itemID result:filteredResults];
        }    
        
    }
#pragma mark Success - Availability Summary
    else if ([command isEqualToString:LibraryDataRequestAvailability]) {
        
        // TODO: check whether "Networked Resource" comes in here as something we need to suppress
        
		if ([JSONObject isKindOfClass:[NSDictionary class]]) {
            NSString *itemID = [(NSDictionary *)JSONObject objectForKey:@"id"];
            NSArray *institutions = [(NSDictionary *)JSONObject objectForKey:@"institutions"];
            
            [self.itemDelegate availabilityDidLoadForItemID:itemID result:institutions];
        }
    }
    /*
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
		}
        
        [activeRequests removeObjectForKey:command];

    }
    */
#pragma mark Success - Search
    else if ([command isEqualToString:LibraryDataRequestSearch]) {
        
        [activeRequests removeObjectForKey:command];
    } else {
        
        return;
    }
    
    
    // notify observers of success
    
    NSNotification *success = [NSNotification notificationWithName:LibraryRequestDidCompleteNotification object:command];
    [[NSNotificationCenter defaultCenter] postNotification:success];
}

- (BOOL)request:(JSONAPIRequest *)request shouldDisplayAlertForError:(NSError *)error {
    if ([request.userData isEqualToString:LibraryDataRequestArchives]) {
        // since we request libraries and archives at the same time, only display one error message
        return NO;
    }
    return YES;
}


- (void)request:(JSONAPIRequest *)request handleConnectionError:(NSError *)error {
    NSString *command = request.userData;
    /*
#pragma mark Failure - Item Availability (old)
    if ([command isEqualToString:LibraryDataRequestAvailability]) {
        NSString *itemID = [request.params objectForKey:@"itemId"];
        [self.itemDelegate availabilityFailedToLoadForItemID:itemID];
    }
    */
#pragma mark Failure - Full Availability
    if ([command isEqualToString:LibraryDataRequestFullAvailability]) {
        NSString *itemID = [request.params objectForKey:@"itemId"];
        [self.availabilityDelegate fullAvailabilityFailedToLoadForItemID:itemID];
    }
#pragma mark Failure - Availability Summary
    else if ([command isEqualToString:LibraryDataRequestAvailability]) {
        NSString *itemID = [request.params objectForKey:@"itemId"];            
        [self.itemDelegate availabilityFailedToLoadForItemID:itemID];
    }
    /*
#pragma mark Failure - Image Thumbnail
    else if ([command isEqualToString:LibraryDataRequestThumbnail]) {
        //NSString *itemID = [request.params objectForKey:@"itemid"];
        
        //for (id<LibraryItemDetailDelegate> aDelegate in itemDelegates) {
        //    [aDelegate thumbnailFailedToLoadForItemID:itemID];
        //}
    */
#pragma mark Failure - Item Detail
    else if ([command isEqualToString:LibraryDataRequestItemDetail]) {
        NSString *itemID = [request.params objectForKey:@"itemId"];
        [self.itemDelegate detailsFailedToLoadForItemID:itemID];
    }
    else if ([command isEqualToString:LibraryDataRequestLibraries]
        || [command isEqualToString:LibraryDataRequestOpenLibraries]
        || [command isEqualToString:LibraryDataRequestSearchCodes])
    {
        [activeRequests removeObjectForKey:command];
        
    }
#pragma mark Failure - Library Detail
    else if ([command isEqualToString:LibraryDataRequestLibraryDetail]) {
        NSString *identityTag = [request.params objectForKey:@"id"];
        [self.libDelegate detailsDidFailToLoadForLibrary:identityTag type:@"library"];
    }
#pragma mark Failure - Archive Detail
    else if ([command isEqualToString:LibraryDataRequestArchiveDetail]) {
        NSString *identityTag = [request.params objectForKey:@"id"];
        [self.libDelegate detailsDidFailToLoadForLibrary:identityTag type:@"archive"];
    }
#pragma mark Failure - Search
    else if ([command isEqualToString:LibraryDataRequestSearch]) {
        [activeRequests removeObjectForKey:command];
        
    } else {
        
        return;
    }
    
    NSNotification *failure = [NSNotification notificationWithName:LibraryRequestDidFailNotification object:command];
    [[NSNotificationCenter defaultCenter] postNotification:failure];
}

- (void)dealloc {
    for (JSONAPIRequest *api in [activeRequests allValues]) {
        api.jsonDelegate = nil;
    }
    [activeRequests release];

    self.itemDelegate = nil;
    self.libDelegate = nil;
    self.availabilityDelegate = nil;

    [_schedulesByLibID release];
    //[_allOpenArchives release];
    [_allOpenLibraries release];
    [super dealloc];
}

@end
