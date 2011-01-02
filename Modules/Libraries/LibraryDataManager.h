#import <Foundation/Foundation.h>
#import "JSONAPIRequest.h"

// TODO: change these to delegate methods later since each class is doing the same subscriptions

// api names

extern NSString * const LibraryDataRequestLibraries;
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

@interface LibraryDataManager : NSObject <JSONAPIDelegate> {
    
    NSMutableDictionary *oneTimeRequests;
    NSMutableArray *anytimeRequests;
    
    NSMutableSet *delegates;
	
	NSMutableDictionary *_librariesByID;
	NSMutableArray *_allOpenLibraries;
	NSMutableDictionary *_archivesByID;
    NSMutableArray *_allOpenArchives;
    NSMutableDictionary *_schedulesByLibID;
}

+ (LibraryDataManager *)sharedManager;

- (void)registerDelegate:(id<LibraryDataManagerDelegate>)aDelegate;
- (void)unregisterDelegate:(id<LibraryDataManagerDelegate>)aDelegate;

- (void)requestLibraries;
- (void)requestOpenLibraries;
- (void)requestSearchCodes;
- (void)requestDetailsForLibType:(NSString *)libOrArchive libID:(NSString *)libID libName:(NSString *)libName;
- (void)requestFullAvailabilityForItem:(NSString *)itemID;
- (void)requestThumbnailForItem:(NSString *)itemID;
- (void)searchLibraries:(NSString *)searchTerms;

- (NSDictionary *)scheduleForLibID:(NSString *)libID;
- (Library *)libraryWithID:(NSString *)libID;

@property (nonatomic, readonly) NSArray *allLibraries;
@property (nonatomic, readonly) NSArray *allOpenLibraries;
@property (nonatomic, readonly) NSArray *allArchives;
@property (nonatomic, readonly) NSArray *allOpenArchives;

@end
