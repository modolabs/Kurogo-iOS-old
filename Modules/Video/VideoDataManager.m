#import "VideoDataManager.h"
#import "CoreDataManager.h"
#import "Foundation+KGOAdditions.h"
#import "Video.h"
#import "VideoTag.h"

#pragma mark Private methods

@interface VideoDataManager (Private)

- (void)storeResult:(id)result forRequest:(KGORequest *)request;
- (BOOL)requestManagerIsReachable;
- (BOOL)isRequestInProgressForPath:(NSString *)path;

@end

@implementation VideoDataManager (Private)

- (void)storeResult:(id)result forRequest:(KGORequest *)request {
    if ([request.path isEqualToString:@"sections"]) {
        self.sections = result;
    }
    else if ([request.path isEqualToString:@"videos"]) {
        [self.videos removeAllObjects];
        if ([result isKindOfClass:[NSArray class]]) {
            for (NSDictionary *dict in result) {
                Video *video = [[CoreDataManager sharedManager]
                                insertNewObjectForEntityForName:@"Video"];
                [video setUpWithDictionary:dict];
                [self.videos addObject:video];
            }
            [[CoreDataManager sharedManager] saveData];
        }        
    }
    else if ([request.path isEqualToString:@"search"]) {
        // TODO: Don't store these entities. Delete them when they're 
        // done being used.
        [self.videosFromCurrentSearch removeAllObjects];
        if ([result isKindOfClass:[NSArray class]]) {
            for (NSDictionary *dict in result) {
                Video *video = [[CoreDataManager sharedManager]
                                insertNewObjectForEntityForName:@"Video"];                             
                [video setUpWithDictionary:dict];
                [self.videosFromCurrentSearch addObject:video];
            }
        }
    }
}

- (BOOL)requestManagerIsReachable {
#if TARGET_IPHONE_SIMULATOR
    return YES;
#else
//    if ([self.reachability currentReachabilityStatus] == NotReachable) {
//        return NO;
//    }
    return YES;
#endif
}

- (BOOL)isRequestInProgressForPath:(NSString *)path {
    if ([self.responseBlocksForRequestPaths objectForKey:path])
    {
        return YES;
    }
    return NO;
}

@end


@implementation VideoDataManager

@synthesize responseBlocksForRequestPaths;
@synthesize moduleTag;
@synthesize sections;
@synthesize pendingRequests;
@synthesize videos;
@synthesize reachability;
@synthesize videosFromCurrentSearch;

#pragma mark NSObject

- (id)init
{
    self = [super init];
	if (self)
	{
        self.responseBlocksForRequestPaths = 
        [NSMutableDictionary dictionaryWithCapacity:3];
        self.pendingRequests = [NSMutableSet setWithCapacity:3];
        self.videos = [NSMutableArray arrayWithCapacity:30];
        self.videosFromCurrentSearch = [NSMutableArray arrayWithCapacity:30];
        self.reachability = [Reachability reachabilityWithHostName:
                             [KGORequestManager sharedManager].host];
        self.moduleTag = VideoModuleTag;
	}
	return self;
}

- (void)dealloc {    
    [videosFromCurrentSearch release];
    [reachability release];
    [videos release];
    [responseBlocksForRequestPaths release];
    [moduleTag release];
    [sections release];
    [pendingRequests release];
    [super dealloc];
}

#pragma mark Public

- (BOOL)requestSectionsThenRunBlock:(VideoDataRequestResponse)responseBlock {
    BOOL succeeded = NO;
    
    if ([self isRequestInProgressForPath:@"sections"] || 
        ![self requestManagerIsReachable]) {
        responseBlock(self.sections);
    }    
    else {
        KGORequest *request = 
        [[KGORequestManager sharedManager] 
         requestWithDelegate:self module:self.moduleTag path:@"sections" 
         params:nil];
        request.expectedResponseType = [NSArray class];
        [self.responseBlocksForRequestPaths 
         setObject:[[responseBlock copy] autorelease] 
         forKey:request.path];
        [self.pendingRequests addObject:request];
        [request connect];
        succeeded = YES;
    } 

    return succeeded;
}

- (BOOL)requestVideosForSection:(NSString *)section 
                   thenRunBlock:(VideoDataRequestResponse)responseBlock {
    BOOL succeeded = NO;
    if ([self isRequestInProgressForPath:@"videos"] ||
        ![self requestManagerIsReachable]) {
        // Give responseBlock cached sections.
        // TODO: Check update self.videos with store.
        responseBlock(self.videos);
    }    
    else {
        KGORequest *request = 
        [[KGORequestManager sharedManager] 
         requestWithDelegate:self 
         module:self.moduleTag 
         path:@"videos" 
         params:[NSDictionary dictionaryWithObject:section forKey:@"section"]];
        request.expectedResponseType = [NSArray class];
        
        [self.responseBlocksForRequestPaths 
         setObject:[[responseBlock copy] autorelease] forKey:request.path];
        [self.pendingRequests addObject:request];
        [request connect];
        succeeded = YES;
    }    
    
    return succeeded;
}

- (BOOL)requestSearchOfSection:(NSString *)section 
                         query:(NSString *)query 
                  thenRunBlock:(VideoDataRequestResponse)responseBlock {
    BOOL succeeded = NO;
    
    if ([self isRequestInProgressForPath:@"search"] ||
        ![self requestManagerIsReachable]) {
        // Give responseBlock cached sections.
        // TODO: Check update self.videos with store.
        responseBlock(self.videos);
    }    
    else {
        KGORequest *request = 
        [[KGORequestManager sharedManager] 
         requestWithDelegate:self 
         module:self.moduleTag 
         path:@"search" 
         params:[NSDictionary dictionaryWithObjectsAndKeys:
                 query, @"q",
                 section, @"section",
                 nil]];
        request.expectedResponseType = [NSArray class];
        
        [self.responseBlocksForRequestPaths 
         setObject:[[responseBlock copy] autorelease] forKey:request.path];
        [self.pendingRequests addObject:request];
        [request connect];
        succeeded = YES;
    } 
    return succeeded;
}

#pragma mark KGORequestDelegate
- (void)requestWillTerminate:(KGORequest *)request
{
    [self.responseBlocksForRequestPaths removeObjectForKey:request.path];
    [self.pendingRequests removeObject:request];
}

- (void)request:(KGORequest *)request didFailWithError:(NSError *)error
{
    [[KGORequestManager sharedManager] showAlertForError:error];
}

- (void)request:(KGORequest *)request didReceiveResult:(id)result
{
    //NSLog(@"%@", [result description]);
    [self storeResult:result forRequest:request];
    
    VideoDataRequestResponse responseBlock = 
    [self.responseBlocksForRequestPaths objectForKey:request.path];
    if (responseBlock) {        
        if ([request.path isEqualToString:@"sections"]) {
            responseBlock(result);
        }
        else if ([request.path isEqualToString:@"videos"]) {
            responseBlock(self.videos);
        }
        else if ([request.path isEqualToString:@"search"]) {
            responseBlock(self.videosFromCurrentSearch);
        }        
    }
}

@end
