#import <Foundation/Foundation.h>
#import "KGORequestManager.h"

typedef void (^VideoDataRequestResponse)(id result);

@interface VideoDataManager : NSObject<KGORequestDelegate> {
    
}

#pragma mark Public
- (BOOL)requestSectionsThenRunBlock:(VideoDataRequestResponse)responseBlock;

- (BOOL)requestVideosForSection:(NSString *)section 
                   thenRunBlock:(VideoDataRequestResponse)responseBlock;

- (BOOL)requestSearchOfSection:(NSString *)section 
                         query:(NSString *)query
                  thenRunBlock:(VideoDataRequestResponse)responseBlock;

// Key: KGORequest. Value: VideoDataRequestResponse.
@property (nonatomic, retain) NSMutableDictionary *responseBlocksForRequestPaths; 
@property (nonatomic, retain) NSMutableSet *pendingRequests; 
@property (nonatomic, retain) NSString *moduleTag;
@property (nonatomic, retain) NSArray *sections;
// TODO: Make this dict of arrays per section.
@property (nonatomic, retain) NSArray *videos; 

@end
