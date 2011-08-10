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
        [[NSUserDefaults standardUserDefaults] setObject:self.sections
                                                  forKey:@"Kurogo video sections array"];
    }
    else if ([request.path isEqualToString:@"videos"]) {
        // Clear old stuff.
        [[CoreDataManager sharedManager] deleteObjects:self.videos];
        [self.videos removeAllObjects];
        
        if ([result isKindOfClass:[NSArray class]]) {
            for (NSDictionary *dict in result) {
                Video *video = [[CoreDataManager sharedManager] insertNewObjectForEntityForName:@"Video"];
                [video setUpWithDictionary:dict];
                video.source = [request.getParams objectForKey:@"section"];
                [self.videos addObject:video];
            }
            [[CoreDataManager sharedManager] saveData];
        }        
    }
    else if ([request.path isEqualToString:@"search"]) {
        // Clear old stuff.
        [[CoreDataManager sharedManager] deleteObjects:self.videosFromCurrentSearch];
        [self.videosFromCurrentSearch removeAllObjects];        
        
        if ([result isKindOfClass:[NSArray class]]) {
            for (NSDictionary *dict in result) {
                Video *video = [[CoreDataManager sharedManager] insertNewObjectForEntityForName:@"Video"];                             
                [video setUpWithDictionary:dict];                
                video.source = [NSString stringWithFormat:@"search: %@|%@", 
                                [request.getParams objectForKey:@"q"],
                                [request.getParams objectForKey:@"section"]];
                [self.videosFromCurrentSearch addObject:video];
            }
        }
    }
    else if ([request.path isEqualToString:@"detail"]) {
        // Clear old stuff.
        [[CoreDataManager sharedManager] deleteObjects:self.detailVideo];
        [self.detailVideo removeAllObjects];
        
        if ([result isKindOfClass:[NSDictionary class]]) {
            NSDictionary *dict = (NSDictionary *)result;
                Video *video = [[CoreDataManager sharedManager] insertNewObjectForEntityForName:@"Video"];
                [video setUpWithDictionary:dict];
                video.source = [request.getParams objectForKey:@"section"];
                [self.detailVideo addObject:video];
            [[CoreDataManager sharedManager] saveData];
        }        
    }
}

- (BOOL)requestManagerIsReachable {
    if ([self.reachability currentReachabilityStatus] == NotReachable) {
        return NO;
    }
    return YES;
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
@synthesize detailVideo; 

#pragma mark NSObject

- (id)init
{
    self = [super init];
	if (self)
	{
        self.responseBlocksForRequestPaths = [NSMutableDictionary dictionaryWithCapacity:3];
        self.pendingRequests = [NSMutableSet setWithCapacity:3];
        self.videos = [NSMutableArray arrayWithCapacity:30];
        self.videosFromCurrentSearch = [NSMutableArray arrayWithCapacity:30];
        self.detailVideo = [NSMutableArray arrayWithCapacity:30];
        self.reachability = [Reachability reachabilityForInternetConnection];
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
    
    if ([self isRequestInProgressForPath:@"sections"] || ![self requestManagerIsReachable]) {
        // Get last saved sections.
        self.sections = [[NSUserDefaults standardUserDefaults] objectForKey:@"Kurogo video sections array"];        
        responseBlock(self.sections);
    } else {
        KGORequest *request = [[KGORequestManager sharedManager] requestWithDelegate:self
                                                                              module:self.moduleTag
                                                                                path:@"sections" 
                                                                              params:nil];
        request.expectedResponseType = [NSArray class];
        [self.responseBlocksForRequestPaths setObject:[[responseBlock copy] autorelease] 
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
    if ([self isRequestInProgressForPath:@"videos"] || ![self requestManagerIsReachable]) {
        
        // Get last saved videos for this section.
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"source == %@", section];
        NSArray *fetchedVideos = [[CoreDataManager sharedManager] objectsForEntity:@"Video" 
                                                                 matchingPredicate:pred];
        if (fetchedVideos) {
            [self.videos addObjectsFromArray:fetchedVideos];
        }
        responseBlock(self.videos);
    }    
    else {
        NSDictionary *params = [NSDictionary dictionaryWithObject:section forKey:@"section"];
        KGORequest *request = [[KGORequestManager sharedManager] requestWithDelegate:self 
                                                                              module:self.moduleTag 
                                                                                path:@"videos" 
                                                                              params:params];
        request.expectedResponseType = [NSArray class];
        
        [self.responseBlocksForRequestPaths setObject:[[responseBlock copy] autorelease]
                                               forKey:request.path];
        [self.pendingRequests addObject:request];
        [request connect];
        succeeded = YES;
    }    
    
    return succeeded;
}

- (BOOL)requestVideoForDetailSection:(NSString *)section andVideoID:(NSString *)videoID 
                   thenRunBlock:(VideoDataRequestResponse)responseBlock {
    BOOL succeeded = NO;
    
    NSDictionary *params = [NSDictionary dictionaryWithObject:section forKey:@"section"];
    NSMutableDictionary *mutableParams = [[params mutableCopy] autorelease];
    if (mutableParams == nil) {
        // make sure this is not nil in case we want to auto-append parameters
        mutableParams = [NSMutableDictionary dictionary];
    }
    
    [mutableParams setObject:videoID forKey:@"videoid"];
    
    KGORequest *request = [[KGORequestManager sharedManager] requestWithDelegate:self 
                                                                          module:self.moduleTag 
                                                                            path:@"detail" 
                                                                          params:mutableParams];
    request.expectedResponseType = [NSDictionary class];
    [self.responseBlocksForRequestPaths setObject:[[responseBlock copy] autorelease]
                                           forKey:request.path];
    [self.pendingRequests addObject:request];
    if([request connect])
        succeeded = YES;
    
    return succeeded;
}

- (BOOL)requestSearchOfSection:(NSString *)section 
                         query:(NSString *)query 
                  thenRunBlock:(VideoDataRequestResponse)responseBlock {
    BOOL succeeded = NO;
    
    if ([self isRequestInProgressForPath:@"search"] || ![self requestManagerIsReachable]) {
        // Get last searched-for videos.
        NSPredicate *pred = [NSPredicate predicateWithFormat:
                             @"source == 'search: %@|%@'", query, section];
        NSArray *fetchedVideos = [[CoreDataManager sharedManager] objectsForEntity:@"Video" 
                                                                 matchingPredicate:pred];
        if (fetchedVideos) {
            [self.videosFromCurrentSearch addObjectsFromArray:fetchedVideos];
        }
        responseBlock(self.videosFromCurrentSearch);
    }    
    else {
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                query, @"q",
                                section, @"section",
                                nil];
        KGORequest *request = [[KGORequestManager sharedManager] requestWithDelegate:self 
                                                                              module:self.moduleTag 
                                                                                path:@"search" 
                                                                              params:params];
        request.expectedResponseType = [NSArray class];
        
        [self.responseBlocksForRequestPaths setObject:[[responseBlock copy] autorelease]
                                               forKey:request.path];
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
    [[KGORequestManager sharedManager] showAlertForError:error request:request];
}

- (void)request:(KGORequest *)request didReceiveResult:(id)result
{
    //NSLog(@"%@", [result description]);
    [self storeResult:result forRequest:request];
    
    VideoDataRequestResponse responseBlock = [self.responseBlocksForRequestPaths objectForKey:request.path];
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
        else if ([request.path isEqualToString:@"detail"]) {
            responseBlock(detailVideo);
        }
    }
}

@end
