#import <Foundation/Foundation.h>
#import "JSONAPIRequest.h"

// TODO: change these to delegate methods later since each class is doing the same subscriptions

// api names

extern NSString * const LibraryDataRequestLibraries;
extern NSString * const LibraryDataRequestArchives;
extern NSString * const LibraryDataRequestOpenLibraries;
extern NSString * const LibraryDataRequestSearchCodes;
extern NSString * const LibraryDataRequestLibraryDetail;
extern NSString * const LibraryDataRequestArchiveDetail;
extern NSString * const LibraryDataRequestAvailability;
extern NSString * const LibraryDataRequestThumbnail;
extern NSString * const LibraryDataRequestSearch;
extern NSString * const LibraryDataRequestItemDetail;

// notification names

extern NSString * const LibraryRequestDidCompleteNotification;
extern NSString * const LibraryRequestDidFailNotification;

@class Library;
@class LibraryAlias;
@class LibraryItem;

// singleton protocols

// TODO: redesign this
@protocol LibraryDataManagerDelegate

@optional

- (void)requestDidSucceedForCommand:(NSString *)command;
- (void)requestDidFailForCommand:(NSString *)command;

@end


@protocol LibraryItemDetailDelegate

- (void)availabilityDidLoadForItemID:(NSString *)itemID result:(NSArray *)availabilityData;
- (void)availabilityFailedToLoadForItemID:(NSString *)itemID;

//- (void)thumbnailDidLoadForItem:(LibraryItem *)libItem;
//- (void)thumbnailFailedToLoadForItemID:(NSString *)itemID;

- (void)detailsDidLoadForItem:(LibraryItem *)libItem;
- (void)detailsFailedToLoadForItemID:(NSString *)itemID;

@end


// sorting function for library lists

NSInteger libraryNameSort(id lib1, id lib2, void *context);

@interface LibraryDataManager : NSObject <JSONAPIDelegate> {
    
    NSMutableDictionary *activeRequests;
    
    NSMutableSet *delegates;
    NSMutableSet *itemDelegates;

    NSMutableArray *_allLibraries;
    NSMutableArray *_allArchives;
    
	NSMutableArray *_allOpenLibraries;
    NSMutableArray *_allOpenArchives;
    
    NSMutableDictionary *_schedulesByLibID;
}

+ (LibraryDataManager *)sharedManager;

- (void)registerDelegate:(id<LibraryDataManagerDelegate>)aDelegate;
- (void)unregisterDelegate:(id<LibraryDataManagerDelegate>)aDelegate;

- (void)registerItemDelegate:(id<LibraryItemDetailDelegate>)aDelegate;
- (void)unregisterItemDelegate:(id<LibraryItemDetailDelegate>)aDelegate;

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
- (void)requestFullAvailabilityForItem:(NSString *)itemID;
- (void)requestThumbnailForItem:(NSString *)itemID;
- (void)searchLibraries:(NSString *)searchTerms;

@property (nonatomic, readonly) NSArray *allLibraries;
@property (nonatomic, readonly) NSArray *allOpenLibraries;
@property (nonatomic, readonly) NSArray *allArchives;
@property (nonatomic, readonly) NSArray *allOpenArchives;

@end
