#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

extern NSString * const CoreDataDidDeleteStoreNotification;

@interface CoreDataManager : NSObject {
	NSManagedObjectModel *managedObjectModel;
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
}

@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic, readonly) NSString *applicationDocumentsDirectory;

+ (CoreDataManager *)sharedManager;

- (void)mergeChanges:(NSNotification *)aNotification;
- (void)observeSaveForContext:(NSManagedObjectContext *)aContext;

- (NSArray *)fetchDataForAttribute:(NSString *)attributeName;
- (NSArray *)fetchDataForAttribute:(NSString *)attributeName sortDescriptor:(NSSortDescriptor *)sortDescriptor;
- (void)clearDataForAttribute:(NSString *)attributeName;

- (id)insertNewObjectForEntityForName:(NSString *)entityName;
- (id)insertNewObjectWithNoContextForEntity:(NSString *)entityName;
- (id)objectsForEntity:(NSString *)entityName matchingPredicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors;
- (id)objectsForEntity:(NSString *)entityName matchingPredicate:(NSPredicate *)predicate;
- (id)getObjectForEntity:(NSString *)entityName attribute:(NSString *)attributeName value:(id)value;

- (void)deleteObjects:(NSArray *)objects;
- (void)deleteObject:(NSManagedObject *)object;
- (void)saveData;
- (void)saveDataWithTemporaryMergePolicy:(id)temporaryMergePolicy;

// migration
- (NSString *)storeFileName;
- (NSString *)currentStoreFileName;
- (BOOL)migrateData;
- (BOOL)deleteStore;

@end
