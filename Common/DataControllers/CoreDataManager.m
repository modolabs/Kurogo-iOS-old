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
    self.managedObjectContext;
	NSEntityDescription *entityDescription = [[managedObjectModel entitiesByName] objectForKey:entityName];
	return [[[NSManagedObject alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:aManagedObjectContext] autorelease];
}

- (id)insertNewObjectWithNoContextForEntity:(NSString *)entityName {
	return [self insertNewObjectForEntityForName:entityName context:nil];
}

- (id)objectsForEntity:(NSString *)entityName matchingPredicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors {
	NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:self.managedObjectContext];
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:entity];
	[request setPredicate:predicate];
    if (sortDescriptors) {
        [request setSortDescriptors:sortDescriptors];
    }
	
	NSError *error = nil;
	NSArray *objects = [self.managedObjectContext executeFetchRequest:request error:&error];

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
    [context setMergePolicy:NSOverwriteMergePolicy];
	[self saveData];
	[context setMergePolicy:originalMergePolicy];
}

#pragma mark -
#pragma mark Core Data stack

// modified to allow safe multithreaded Core Data use
-(NSManagedObjectContext *)managedObjectContext {
    NSMutableDictionary *threadDict = [[NSThread currentThread] threadDictionary];
    NSManagedObjectContext *localContext = [threadDict objectForKey:@"MITCoreDataManagedObjectContext"];
    if (localContext) {
        return localContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        localContext = [[NSManagedObjectContext alloc] init];
        [localContext setPersistentStoreCoordinator: coordinator];
        [threadDict setObject:localContext forKey:@"MITCoreDataManagedObjectContext"];
        [localContext release];
    }
    return localContext;
}

# pragma mark Everything below here is auto-generated

- (NSManagedObjectModel *)managedObjectModel {
	if (!managedObjectModel) {
        // override the autogenerated method -- see http://iphonedevelopment.blogspot.com/2009/09/core-data-migration-problems.html
        NSArray *modelNames = [(KGOAppDelegate *)[[UIApplication sharedApplication] delegate] coreDataModelsNames];
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
	
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error])  {
		DLog(@"CoreDataManager failed to create or access the persistent store: %@", [error userInfo]);
		
		// see if we failed because of changes to the db
		//if (![[self storeFileName] isEqualToString:[self currentStoreFileName]]) {
		//	NSLog(@"This app has been upgraded since last use of Core Data. If it crashes on launch, reinstalling should fix it.");
			if ([self migrateData]) {
				DLog(@"Attempting to recreate the persistent store...");
				storeURL = [NSURL fileURLWithPath:[self storeFileName]];
				if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType 
															  configuration:nil URL:storeURL options:options error:&error]) {
					DLog(@"Failed to recreate the persistent store: %@", [error userInfo]);
				}
			} else {
				DLog(@"Could not migrate data.  Wiping out data...");
#ifdef DEBUG
                NSString *backupFile = [NSString stringWithFormat:@"%@.bak", [self storeFileName]];
                NSError *error = nil;
                if ([[NSFileManager defaultManager] moveItemAtPath:[self storeFileName] toPath:backupFile error:&error]) {
                    NSLog(@"Old core data is stored at %@", backupFile);
                } else {
                    NSLog(@"Could not move old file.  Error %d: %@ %@\nApp will now crash.", [error code], [error domain], [error userInfo]);
                }
#else
                if ([[NSFileManager defaultManager] removeItemAtPath:[self storeFileName] error:&error]) {
                    DLog(@"Could not delete old file.  App will now crash.");
                }                
#endif
			}
		//}
    }
	
    return persistentStoreCoordinator;
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
