#import "VideoDataManager.h"
#import "CoreDataManager.h"
#import "Foundation+KGOAdditions.h"
#import "Video.h"
#import "VideoTag.h"

NSString * const KurogoVideoSectionsArrayKey = @"Kurogo video sections array";

#pragma mark Private methods

@interface VideoDataManager (Private)

- (void)storeResult:(id)result forRequest:(KGORequest *)request;
- (BOOL)isRequestInProgressForPath:(NSString *)path;

@end

@implementation VideoDataManager (Private)

- (void)storeResult:(id)result forRequest:(KGORequest *)request {
    if ([request.path isEqualToString:@"sections"]) {
        self.sections = result;
        [[NSUserDefaults standardUserDefaults] setObject:self.sections
                                                  forKey:KurogoVideoSectionsArrayKey];
    }
    else if ([request.path isEqualToString:@"videos"]) {
        // queue unneeded videos to be deleted.
        // if new results still contain videos with the same id, we will take them out of the remove queue
        NSMutableDictionary *removedVideos = [NSMutableDictionary dictionary];
        [self.videos enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            Video *video = (Video *)obj;
            [removedVideos setObject:video forKey:video.videoID];
        }];
        self.videos = [NSMutableArray array];
        
        NSInteger order = 0;
        for (NSDictionary *dict in result) {
            Video *video = [Video videoWithDictionary:dict];
            if (video) {
                video.source = [request.getParams objectForKey:@"section"];
                [self.videos addObject:video];
                video.sortOrder = [NSNumber numberWithInt:order++];
                [removedVideos removeObjectForKey:video.videoID];
            }
        }
        
        [removedVideos enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [[CoreDataManager sharedManager] deleteObject:obj];
        }];
        
        [[CoreDataManager sharedManager] saveData];
    }
    else if ([request.path isEqualToString:@"search"]) {
        // Clear old stuff.
        [[CoreDataManager sharedManager] deleteObjects:self.videosFromCurrentSearch];
        [self.videosFromCurrentSearch removeAllObjects];
        
        for (NSDictionary *dict in result) {
            Video *video = [Video videoWithDictionary:dict];
            video.source = [NSString stringWithFormat:@"search: %@|%@", 
                            [request.getParams objectForKey:@"q"],
                            [request.getParams objectForKey:@"section"]];
            [self.videosFromCurrentSearch addObject:video];
        }
    }
    else if ([request.path isEqualToString:@"detail"]) {
        Video *video = [Video videoWithDictionary:result];
        video.source = [request.getParams objectForKey:@"section"];
        self.detailVideo = video;
        [[CoreDataManager sharedManager] saveData];
    }
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
        self.moduleTag = VideoModuleTag;
    }
	return self;
}

- (void)dealloc {    
    [videosFromCurrentSearch release];
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
    
    if ([self isRequestInProgressForPath:@"sections"] || ![[KGORequestManager sharedManager] isReachable]) {
        // Get last saved sections.
        self.sections = [[NSUserDefaults standardUserDefaults] objectForKey:KurogoVideoSectionsArrayKey];        
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

- (BOOL)requestVideosForSection:(NSString *)section thenRunBlock:(VideoDataRequestResponse)responseBlock {
    
    
    BOOL succeeded = NO;
    if ([self isRequestInProgressForPath:@"videos"] || ![[KGORequestManager sharedManager] isReachable]) {
        
        // Get last saved videos for this section.
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"source == %@", section];
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"sortOrder" ascending:YES];
        NSArray *fetchedVideos = [[CoreDataManager sharedManager] objectsForEntity:@"Video" 
                                                                 matchingPredicate:pred
                                                                   sortDescriptors:[NSArray arrayWithObject:sort]];
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
                        thenRunBlock:(VideoDataRequestResponse)responseBlock
{
    BOOL succeeded = NO;
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            section, @"section", videoID, @"videoid", nil];
    
    KGORequest *request = [[KGORequestManager sharedManager] requestWithDelegate:self 
                                                                          module:self.moduleTag 
                                                                            path:@"detail" 
                                                                          params:params];
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
    
    if ([self isRequestInProgressForPath:@"search"] || ![[KGORequestManager sharedManager] isReachable]) {
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

- (NSArray *)bookmarkedVideos
{
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"bookmarked == YES"];
    return [[CoreDataManager sharedManager] objectsForEntity:@"Video" matchingPredicate:pred];
}


- (void)pruneVideos
{
    NSPredicate *bookmarked = [NSPredicate predicateWithFormat:@"bookmarked == YES"];
    self.videos = [NSMutableArray arrayWithArray:[self.videos filteredArrayUsingPredicate:bookmarked]];
    
    NSPredicate *notBookmarked = [NSPredicate predicateWithFormat:@"bookmarked != YES"];
    NSArray *nonBookmarkedVideos = [[CoreDataManager sharedManager] objectsForEntity:@"Video"
                                                                   matchingPredicate:notBookmarked];

    [[CoreDataManager sharedManager] deleteObjects:nonBookmarkedVideos];
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
            responseBlock(self.detailVideo);
        }
    }
}

@end
