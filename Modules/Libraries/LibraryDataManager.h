#import <Foundation/Foundation.h>
#import "JSONAPIRequest.h"

// api names

extern NSString * const LibraryDataRequestLibraries;
extern NSString * const LibraryDataRequestArchives;
extern NSString * const LibraryDataRequestOpenLibraries;
extern NSString * const LibraryDataRequestSearchCodes;
extern NSString * const LibraryDataRequestLibraryDetail;
extern NSString * const LibraryDataRequestArchiveDetail;
//extern NSString * const LibraryDataRequestOldAvailability;
extern NSString * const LibraryDataRequestThumbnail;
extern NSString * const LibraryDataRequestSearch;
extern NSString * const LibraryDataRequestItemDetail;
extern NSString * const LibraryDataRequestFullAvailability;
extern NSString * const LibraryDataRequestAvailability;

// notification names

extern NSString * const LibraryRequestDidCompleteNotification;
extern NSString * const LibraryRequestDidFailNotification;

@class Library;
@class LibraryAlias;
@class LibraryItem;

// singleton protocols

@protocol LibraryDetailDelegate <NSObject>

- (void)detailsDidLoadForLibrary:(NSString *)libID type:(NSString *)libType;
- (void)detailsDidFailToLoadForLibrary:(NSString *)libID type:(NSString *)libType;

@end

@protocol LibraryItemDetailDelegate <NSObject>

- (void)availabilityDidLoadForItemID:(NSString *)itemID result:(NSArray *)availabilityData;
- (void)availabilityFailedToLoadForItemID:(NSString *)itemID;

- (void)detailsDidLoadForItem:(LibraryItem *)libItem;
- (void)detailsFailedToLoadForItemID:(NSString *)itemID;

@end

@protocol LibraryAvailabilityDelegate <NSObject>

- (void)fullAvailabilityDidLoadForItemID:(NSString *)itemID result:(NSArray *)availabilityData;
- (void)fullAvailabilityFailedToLoadForItemID:(NSString *)itemID;

@end




// sorting function for library lists

NSInteger libraryNameSort(id lib1, id lib2, void *context);

@interface LibraryDataManager : NSObject <JSONAPIDelegate> {
    
    NSMutableDictionary *activeRequests;
    
    id<LibraryItemDetailDelegate> itemDelegate;
    id<LibraryAvailabilityDelegate> availabilityDelegate;
    id<LibraryDetailDelegate> libDelegate;
    
    NSMutableArray *_allLibraries;
    NSMutableArray *_allArchives;
    
	NSMutableArray *_allOpenLibraries;
    //NSMutableArray *_allOpenArchives;
    
    NSMutableDictionary *_schedulesByLibID;
}

@property (nonatomic, assign) id<LibraryItemDetailDelegate> itemDelegate;
@property (nonatomic, assign) id<LibraryAvailabilityDelegate> availabilityDelegate;
@property (nonatomic, assign) id<LibraryDetailDelegate> libDelegate;

+ (LibraryDataManager *)sharedManager;

- (void)updateLibraryList;

#pragma mark Data retrieval methods

- (NSDictionary *)scheduleForLibID:(NSString *)libID;

// these methods create core data objects as a side effect
- (Library *)libraryWithID:(NSString *)libID type:(NSString *)type primaryName:(NSString *)primaryName;
- (LibraryAlias *)libraryAliasWithID:(NSString *)libID type:(NSString *)type name:(NSString *)name;
- (LibraryItem *)libraryItemWithID:(NSString *)itemID;

#pragma mark API requests

- (void)requestLibraries;
- (void)requestArchives;
- (void)requestOpenLibraries;
- (void)requestSearchCodes;
- (void)requestDetailsForLibType:(NSString *)libOrArchive libID:(NSString *)libID libName:(NSString *)libName;
- (void)requestDetailsForItem:(LibraryItem *)item;
//- (void)requestOldAvailabilityForItem:(NSString *)itemID;
- (void)requestAvailabilityForItem:(NSString *)itemID;
- (void)requestFullAvailabilityForItem:(NSString *)itemID;
- (void)requestThumbnailForItem:(NSString *)itemID;
- (void)searchLibraries:(NSString *)searchTerms;

@property (nonatomic, readonly) NSArray *allLibraries;
@property (nonatomic, readonly) NSArray *allOpenLibraries;
@property (nonatomic, readonly) NSArray *allArchives;
//@property (nonatomic, readonly) NSArray *allOpenArchives;

@end
