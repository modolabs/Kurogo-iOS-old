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

// notification names

extern NSString * const LibraryRequestDidCompleteNotification;
extern NSString * const LibraryRequestDidFailNotification;

// singleton protocol. TODO: redesign this

@protocol LibraryDataManagerDelegate

@optional

- (void)requestDidSucceedForCommand:(NSString *)command;
- (void)requestDidFailForCommand:(NSString *)command;

@end

// sorting function for library lists

NSInteger libraryNameSort(id lib1, id lib2, void *context);

@class Library;
@class LibraryAlias;

@interface LibraryDataManager : NSObject <JSONAPIDelegate> {
    
    NSMutableDictionary *oneTimeRequests;
    NSMutableArray *anytimeRequests;
    
    NSMutableSet *delegates;

    NSMutableArray *_allLibraries;
    NSMutableArray *_allArchives;
    
	NSMutableArray *_allOpenLibraries;
    NSMutableArray *_allOpenArchives;
    
    NSMutableDictionary *_schedulesByLibID;
}

+ (LibraryDataManager *)sharedManager;

- (void)registerDelegate:(id<LibraryDataManagerDelegate>)aDelegate;
- (void)unregisterDelegate:(id<LibraryDataManagerDelegate>)aDelegate;

#pragma mark Data retrieval methods

- (NSDictionary *)scheduleForLibID:(NSString *)libID;

// these two methods create core data objects as a side effect
- (Library *)libraryWithID:(NSString *)libID primaryName:(NSString *)primaryName;
- (LibraryAlias *)libraryAliasWithID:(NSString *)libID name:(NSString *)name;

#pragma mark API requests

- (void)requestLibraries;
- (void)requestArchives;
- (void)requestOpenLibraries;
- (void)requestSearchCodes;
- (void)requestDetailsForLibType:(NSString *)libOrArchive libID:(NSString *)libID libName:(NSString *)libName;
- (void)requestFullAvailabilityForItem:(NSString *)itemID;
- (void)requestThumbnailForItem:(NSString *)itemID;
- (void)searchLibraries:(NSString *)searchTerms;

@property (nonatomic, readonly) NSArray *allLibraries;
@property (nonatomic, readonly) NSArray *allOpenLibraries;
@property (nonatomic, readonly) NSArray *allArchives;
@property (nonatomic, readonly) NSArray *allOpenArchives;

@end
