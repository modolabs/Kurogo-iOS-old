#import "CoreDataManager.h"
#import "MITBuildInfo.h"
#import "KGOAppDelegate.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import <objc/runtime.h>

// not sure what to call this, just a placeholder for now, still hard coding file name below
#define SQLLITE_PREFIX @"CoreDataXML."


@implementation CoreDataManager

@synthesize managedObjectModel;
@synthesize managedObjectContext;
@synthesize persistentStoreCoordinator;

#pragma mark -
#pragma mark Class methods

+ (CoreDataManager *)sharedManager {
	static CoreDataManager *sharedInstance = nil;
	if (!sharedInstance) {
		sharedInstance = [CoreDataManager new];
	}
	return sharedInstance;
}

#pragma mark -
#pragma mark CoreData object methods

- (NSArray *)fetchDataForAttribute:(NSString *)attributeName {
	NSFetchRequest *request = [[NSFetchRequest alloc] init];	// make a request object
	NSEntityDescription *entity = [NSEntityDescription entityForName:attributeName inManagedObjectContext:self.managedObjectContext];	// tell the request what to look for
	[request setEntity:entity];
	
	NSError *error;
    NSArray *result = [self.managedObjectContext executeFetchRequest:request error:&error];
    // TODO: handle errors when Core Data calls fail
    [request release];
    
	return result;
}

- (NSArray *)fetchDataForAttribute:(NSString *)attributeName sortDescriptor:(NSSortDescriptor *)sortDescriptor {
	NSFetchRequest *request = [[NSFetchRequest alloc] init];	// make a request object
	[request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
	NSEntityDescription *entity = [NSEntityDescription entityForName:attributeName inManagedObjectContext:self.managedObjectContext];	// tell the request what to look for
	[request setEntity:entity];
	
	NSError *error;
    NSArray *result = [self.managedObjectContext executeFetchRequest:request error:&error];
    [request release];
    
	return result;
}

- (void)clearDataForAttribute:(NSString *)attributeName {
	for (id object in [self fetchDataForAttribute:attributeName]) {
		[self deleteObject:(NSManagedObject *)object];
	}
	[self saveData];
}

- (void)deleteObjects:(NSArray *)objects {
    for (NSManagedObject *object in objects) {
        [self.managedObjectContext deleteObject:object];
    }
}

- (void)deleteObject:(NSManagedObject *)object {
	[self.managedObjectContext deleteObject:object];
}

// TODO: consider using initWithEntity:insertIntoManagedObjectContext instead
- (id)insertNewObjectForEntityForName:(NSString *)entityName {
	return [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:self.managedObjectContext];
}

- (id)insertNewObjectForEntityForName:(NSString *)entityName context:(NSManagedObjectContext *)aManagedObjectContext {
    DLog(@"inserting new %@ object", entityName);
    if (self.managedObjectContext) {
        NSEntityDescription *entityDescription = [[managedObjectModel entitiesByName] objectForKey:entityName];
        return [[[NSManagedObject alloc] initWithEntity:entityDescription
                         insertIntoManagedObjectContext:aManagedObjectContext] autorelease];
    }
    return nil;
}

- (id)insertNewObjectWithNoContextForEntity:(NSString *)entityName {
	return [self insertNewObjectForEntityForName:entityName context:nil];
}

- (id)objectsForEntity:(NSString *)entityName matchingPredicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors {
	NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:self.managedObjectContext];
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:entity];
    if (predicate) {
        [request setPredicate:predicate];
    }
    if (sortDescriptors) {
        [request setSortDescriptors:sortDescriptors];
    }
	NSError *error = nil;
	NSArray *objects = [self.managedObjectContext executeFetchRequest:request error:&error];
    if (error) {
        NSLog(@"error fetching objects for %@: predicate: %@, error: %@", entityName, predicate, [error description]);
    }
    return ([objects count] > 0) ? objects : nil;
}

- (id)objectsForEntity:(NSString *)entityName matchingPredicate:(NSPredicate *)predicate {
    return [self objectsForEntity:entityName matchingPredicate:predicate sortDescriptors:nil];
}

- (id)getObjectForEntity:(NSString *)entityName attribute:(NSString *)attributeName value:(id)value {	
	NSString *predicateFormat = [attributeName stringByAppendingString:@" like %@"];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateFormat, value];
    NSArray *objects = [self objectsForEntity:entityName matchingPredicate:predicate];
    return ([objects count] > 0) ? [objects lastObject] : nil;
}

- (void)saveData {
    NSLog(@"saving: %@", self.managedObjectContext);
	NSError *error;
	if (![self.managedObjectContext save:&error]) {
        DLog(@"Failed to save to data store: %@", [error localizedDescription]);
        NSArray* detailedErrors = [[error userInfo] objectForKey:NSDetailedErrorsKey];
        if(detailedErrors != nil && [detailedErrors count] > 0) {
            for(NSError* detailedError in detailedErrors) {
                DLog(@"  DetailedError: %@", [detailedError userInfo]);
            }
        }
        else {
            DLog(@"  %@", [error userInfo]);
        }
	}	
}

- (void)saveDataWithTemporaryMergePolicy:(id)temporaryMergePolicy {
    NSManagedObjectContext *context = [self managedObjectContext];
    id originalMergePolicy = [context mergePolicy];
    [context setMergePolicy:temporaryMergePolicy];
	[self saveData];
	[context setMergePolicy:originalMergePolicy];
}

#pragma mark -
#pragma mark Core Data stack

// modified to allow safe multithreaded Core Data use
- (NSManagedObjectContext *)managedObjectContext {
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];

    NSMutableDictionary *threadDict = [[NSThread currentThread] threadDictionary];
    NSManagedObjectContext *localContext = [threadDict objectForKey:@"MITCoreDataManagedObjectContext"];
    if (localContext) {
        if (![localContext persistentStoreCoordinator]) {
            [localContext setPersistentStoreCoordinator:coordinator];
        }
        
        return localContext;
    }
    
    if (coordinator != nil) {
        localContext = [[[NSManagedObjectContext alloc] init] autorelease];
        [localContext setPersistentStoreCoordinator: coordinator];
        [threadDict setObject:localContext forKey:@"MITCoreDataManagedObjectContext"];
        
        NSLog(@"current thread: %@", [NSThread currentThread]);
        
        if ([NSThread currentThread] != [NSThread mainThread]) {
            [self performSelectorOnMainThread:@selector(observeSaveForContext:) withObject:localContext waitUntilDone:NO];
        }
    }
    return localContext;
}

- (void)observeSaveForContext:(NSManagedObjectContext *)aContext
{
    NSLog(@"observing saves for new context: %@", aContext);
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(mergeChanges:)
                                                 name:NSManagedObjectContextDidSaveNotification
                                               object:aContext];
}

- (void)mergeChanges:(NSNotification *)aNotification
{
    NSLog(@"local context did save %@", aNotification);
    
    if ([NSThread currentThread] == [NSThread mainThread]) {
        NSLog(@"saving changes on main thread %@, context %@", [NSThread currentThread], [self managedObjectContext]);
        [[self managedObjectContext] mergeChangesFromContextDidSaveNotification:aNotification];
        
    } else {
        NSLog(@"saving changes on remote thread %@, context %@", [NSThread currentThread], [self managedObjectContext]);
        //[[self managedObjectContext] performSelectorOnMainThread:@selector(mergeChangesFromContextDidSaveNotification:)
        //                                              withObject:aNotification
        //                                           waitUntilDone:YES];
        [self performSelectorOnMainThread:@selector(mergeChanges:) withObject:aNotification waitUntilDone:YES];
    }
}

# pragma mark Everything below here is auto-generated

- (NSManagedObjectModel *)managedObjectModel {
	if (!managedObjectModel) {
        // override the autogenerated method -- see http://iphonedevelopment.blogspot.com/2009/09/core-data-migration-problems.html
        NSArray *modelNames = [KGO_SHARED_APP_DELEGATE() coreDataModelNames];
        NSMutableArray *models = [NSMutableArray arrayWithCapacity:modelNames.count];
        for (NSString *modelName in modelNames) {
            NSString *path = [[NSBundle mainBundle] pathForResource:modelName ofType:@"momd"];
            NSManagedObjectModel *aModel = [[[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path]] autorelease];
            [models addObject:aModel];
        }
        
        managedObjectModel = [NSManagedObjectModel modelByMergingModels:models];
    }
    
    return managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	
    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }
	
	NSURL *storeURL = [NSURL fileURLWithPath:[self storeFileName]];
	
	NSError *error;
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
	
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];

    NSPersistentStore *store = [persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                                        configuration:nil
                                                                                  URL:storeURL
                                                                              options:options
                                                                                error:&error];
    if (!store) {
        BOOL tryAgain = [self migrateData];
        
		DLog(@"CoreDataManager failed to create or access the persistent store: %@", [error userInfo]);
        if (tryAgain) {
            storeURL = [NSURL fileURLWithPath:[self storeFileName]];
            
        } else {
            DLog(@"Could not migrate data.  Wiping out data...");
#ifdef DEBUG
            // TODO: perhaps put an alertview here so devs remember to check
            // for failed data migrations
            NSString *backupFile = [NSString stringWithFormat:@"%@.bak", [self storeFileName]];
            if ([[NSFileManager defaultManager] moveItemAtPath:[self storeFileName] toPath:backupFile error:&error]) {                 NSLog(@"Old core data is stored at %@", backupFile);
                tryAgain = YES;
                
            } else {
                NSLog(@"Failed to move old core data to backup file: %@", [error description]);
                // try to just delete it so we can at least mimic production behavior
                if ([[NSFileManager defaultManager] removeItemAtPath:[self storeFileName] error:&error]) {
                    tryAgain = YES;
                    
                } else {
                    NSLog(@"Failed to delete old core data file: %@", [error description]);
                }
            }
#else
            if ([[NSFileManager defaultManager] removeItemAtPath:[self storeFileName] error:&error]) {
                tryAgain = YES;
                
            } else {
                NSLog(@"Failed to delete old core data file: %@", [error description]);
            }
#endif
        }
        
        if (tryAgain) {
            DLog(@"Attempting to recreate the persistent store");
            store = [persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType 
                                                             configuration:nil
                                                                       URL:storeURL
                                                                   options:options
                                                                     error:&error];
            if (!store) {
                NSLog(@"Still failed to create the persistent store: %@", [error description]);
            }
        }
    }
	
    return persistentStoreCoordinator;
}

- (BOOL)deleteStore
{
    BOOL success = NO;
    NSError *error = nil;

    @synchronized(self) {
        [persistentStoreCoordinator release];
        persistentStoreCoordinator = nil;
    }
    
    if ([[NSFileManager defaultManager] removeItemAtPath:[self storeFileName] error:&error]) {
        success = YES;
        
    } else {
        NSLog(@"could not delete store, %@", [error description]);
    }
    return success;
}

#pragma mark -
#pragma mark Application's documents directory

/**
 Returns the path to the application's documents directory.
 */
- (NSString *)applicationDocumentsDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

- (NSString *)storeFileName {
	NSString *currentFileName = [self currentStoreFileName];
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:currentFileName]) {
		NSInteger maxVersion = 0;
		NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self applicationDocumentsDirectory] error:NULL];
		// find all files like CoreDataXML.* and pick the latest one
		for (NSString *file in files) {
			if ([file hasPrefix:@"CoreDataXML."] && [file hasSuffix:@"sqlite"]) {
				// if version is something like 3:4M, this takes 3 to be the pre-existing version
				NSInteger version = [[[file componentsSeparatedByString:@"."] objectAtIndex:1] intValue];
				if (version >= maxVersion) {
					maxVersion = version;
					currentFileName = [[self applicationDocumentsDirectory] stringByAppendingPathComponent:file];
				}
			}
		}
	}
	DLog(@"Core Data stored at %@", currentFileName);
	return currentFileName;
}

- (NSString *)currentStoreFileName {
	return [[self applicationDocumentsDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"CoreDataXML.%@.sqlite", MITBuildNumber]];
}

#pragma mark -
#pragma mark Migration methods

- (BOOL)migrateData
{	
	NSError *error;
	
	NSString *sourcePath = [self storeFileName];
	NSURL *sourceURL = [NSURL fileURLWithPath:sourcePath];
	NSURL *destURL = [NSURL fileURLWithPath: [self currentStoreFileName]];
	
	DLog(@"Attempting to migrate from %@ to %@", [[self storeFileName] lastPathComponent], [[self currentStoreFileName] lastPathComponent]);
		  
	NSDictionary *sourceMetadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:NSSQLiteStoreType
																							  URL:sourceURL
																							error:&error];
	
	if (sourceMetadata == nil) {
		DLog(@"Failed to fetch metadata with error %d: %@", [error code], [error userInfo]);
		return NO;
	}
	
	NSManagedObjectModel *sourceModel = [NSManagedObjectModel mergedModelFromBundles:nil 
																	forStoreMetadata:sourceMetadata];
	
	if (sourceModel == nil) {
		DLog(@"Failed to create source model");
		return NO;
	}
	
	NSManagedObjectModel *destinationModel = [self managedObjectModel];

	if ([destinationModel isConfiguration:nil compatibleWithStoreMetadata:sourceMetadata]) {
		DLog(@"No persistent store incompatilibilities detected, cancelling");
		return YES;
	}
	
	DLog(@"source model entities: %@", [[sourceModel entityVersionHashesByName] description]);
	DLog(@"destination model entities: %@", [[destinationModel entityVersionHashesByName] description]);
	
	NSMappingModel *mappingModel;
	
	// try to get a mapping automatically first
	mappingModel = [NSMappingModel inferredMappingModelForSourceModel:sourceModel 
													 destinationModel:destinationModel 
																error:&error];

	if (mappingModel == nil) {
		DLog(@"Could not create inferred mapping model: %@", [error userInfo]);
		// try again with xcmappingmodel files we created
		mappingModel = [NSMappingModel mappingModelFromBundles:nil
												forSourceModel:sourceModel
										destinationModel:destinationModel];
		
		if (mappingModel == nil) {
			DLog(@"Failed to create mapping model");
			return NO;
		}
	}
	
	
	NSValue *classValue = [[NSPersistentStoreCoordinator registeredStoreTypes] objectForKey:NSSQLiteStoreType];
	Class sqliteStoreClass = (Class)[classValue pointerValue];
	Class sqliteStoreMigrationManagerClass = [sqliteStoreClass migrationManagerClass];
	
	NSMigrationManager *manager = [[[sqliteStoreMigrationManagerClass alloc]
								   initWithSourceModel:sourceModel destinationModel:destinationModel] autorelease];
	
	if (![manager migrateStoreFromURL:sourceURL type:NSSQLiteStoreType options:nil withMappingModel:mappingModel 
					 toDestinationURL:destURL destinationType:NSSQLiteStoreType destinationOptions:nil error:&error]) {
		DLog(@"Migration failed with error %d: %@", [error code], [error userInfo]);
		return NO;
	}
	
	if (![[NSFileManager defaultManager] removeItemAtPath:sourcePath error:&error]) {
		DLog(@"Failed to remove old store with error %d: %@", [error code], [error userInfo]);
	}
	
	DLog(@"Migration complete!");
	return YES;
	
}








#pragma mark -

-(void)dealloc {
	[managedObjectModel release];
	[managedObjectContext release];
	[persistentStoreCoordinator release];

	[super dealloc];
}

@end
