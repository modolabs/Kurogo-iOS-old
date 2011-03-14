#import "KGOSocialMediaController+FacebookAPI.h"
#import "FacebookModel.h"
#import "Foundation+KGOAdditions.h"
#import "CoreDataManager.h"

@interface FBRequestIdentifier : NSObject

@property (nonatomic, assign) SEL callback;
@property (nonatomic, assign) id receiver;

@end

@implementation FBRequestIdentifier

@synthesize callback, receiver;

@end

@interface KGOSocialMediaController (Private)

- (BOOL)queueFacebookRequest:(FBRequest *)request withReceiver:(id)receiver callback:(SEL)callback;

@end



@implementation KGOSocialMediaController (FacebookAPI)


- (BOOL)queueFacebookRequest:(FBRequest *)request withReceiver:(id)receiver callback:(SEL)callback {
    if ([receiver respondsToSelector:callback]) {
        NSLog(@"queueing request %@ params %@", request.url, request.params);
        FBRequestIdentifier *identifier = [[[FBRequestIdentifier alloc] init] autorelease];
        identifier.receiver = receiver;
        identifier.callback = callback;
        [_fbRequestIdentifiers addObject:identifier];
        [_fbRequestQueue addObject:request];
        return YES;
    }
    return NO;
}

- (FBRequest *)requestFacebookGraphPath:(NSString *)graphPath receiver:(id)receiver callback:(SEL)callback {
    DLog(@"requesting graph path: %@", graphPath);
    FBRequest *request = [_facebook requestWithGraphPath:graphPath andDelegate:self];
    if ([self queueFacebookRequest:request withReceiver:receiver callback:callback]) {
        return request;
    }
    return nil;
}

- (FBRequest *)requestFacebookFQL:(NSString *)query receiver:(id)receiver callback:(SEL)callback {
    DLog(@"requesting FQL: %@", query);
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:query forKey:@"query"];
    FBRequest *request = [_facebook requestWithMethodName:@"fql.query" andParams:params andHttpMethod:@"GET" andDelegate:self];
    if ([self queueFacebookRequest:request withReceiver:receiver callback:callback]) {
        [request connect];
        return request;
    }
    return nil;
}

- (FBRequest *)likeFacebookPost:(FacebookParentPost *)post receiver:(id)receiver callback:(SEL)callback {
    NSString *graphPath = [NSString stringWithFormat:@"%@/likes", post.identifier];
    // Facebook's internal method expects a NSMutableDictionary that it then
    // populates with access token and other boilerplate.  passing nil for
    // params causes all those populating steps to do nothing, resulting in an
    // access denied error.  this means we always have to pass an initialized
    // NSMutableDictionary even though it would be ridiculously simple for them
    // to check for nil.
    FBRequest *request = [_facebook requestWithGraphPath:graphPath
                                               andParams:[NSMutableDictionary dictionary]
                                           andHttpMethod:@"POST"
                                             andDelegate:self];
    if ([self queueFacebookRequest:request withReceiver:receiver callback:callback]) {
        return request;
    }
    return nil;
}

- (FBRequest *)unlikeFacebookPost:(FacebookParentPost *)post receiver:(id)receiver callback:(SEL)callback {
    NSString *graphPath = [NSString stringWithFormat:@"%@/likes", post.identifier];
    FBRequest *request = [_facebook requestWithGraphPath:graphPath
                                               andParams:[NSMutableDictionary dictionary] // see comment above.
                                           andHttpMethod:@"DELETE"
                                             andDelegate:self];
    if ([self queueFacebookRequest:request withReceiver:receiver callback:callback]) {
        return request;
    }
    return nil;
}

// TODO: consider handling the callback internally and just passing back the comment id
- (FBRequest *)addComment:(NSString *)comment toFacebookPost:(FacebookParentPost *)post receiver:(id)receiver callback:(SEL)callback {
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:comment, @"message", nil];
    NSString *graphPath = post.commentPath.length ? post.commentPath : post.identifier;
    FBRequest *request = [_facebook requestWithGraphPath:[NSString stringWithFormat:@"%@/comments", graphPath]
                                               andParams:params
                                           andHttpMethod:@"POST"
                                             andDelegate:self];
    if ([self queueFacebookRequest:request withReceiver:receiver callback:callback]) {
        return request;
    }
    return nil;
}

- (void)disconnectFacebookRequests:(id)receiver {
    NSArray *identifiers = [[_fbRequestIdentifiers copy] autorelease];
    for (FBRequestIdentifier *anIdentifier in identifiers) {
        if (anIdentifier.receiver == receiver) {
            anIdentifier.receiver = nil;
            NSInteger index = [_fbRequestIdentifiers indexOfObject:anIdentifier];
            if (index != NSNotFound) {
                FBRequest *request = [_fbRequestQueue objectAtIndex:index];
                request.delegate = nil;
                [_fbRequestIdentifiers removeObjectAtIndex:index];
                [_fbRequestQueue removeObjectAtIndex:index];
            }
        }
    }
}

- (void)didReceiveSelfInfo:(id)result {
    _fbSelfRequest.delegate = nil;
    _fbSelfRequest = nil;
    
    FacebookUser *user = [FacebookUser userWithDictionary:result];
    user.isSelf = [NSNumber numberWithBool:YES];
    [[CoreDataManager sharedManager] saveData];
}

- (FacebookUser *)currentFacebookUser {
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"isSelf = YES"];
    FacebookUser *user = [[[CoreDataManager sharedManager] objectsForEntity:FacebookUserEntityName matchingPredicate:pred] lastObject];
    DLog(@"cached facebook user: %@", [user description]);
    if (user && [_facebook isSessionValid]) {
        return user;
    } else if ([_facebook isSessionValid]) {
        if (!_fbSelfRequest) {
            NSLog(@"getting facebook profile info");
            _fbSelfRequest = [self requestFacebookGraphPath:@"me" receiver:self callback:@selector(didReceiveSelfInfo:)];
        }
        return nil;
    } else {
        DLog(@"have user but facebook session invalid");
        [self loginFacebook];
        return nil;
    }
}

#pragma mark FBRequestDelegate

/**
 * Called when a request returns and its response has been parsed into an object.
 * The resulting object may be a dictionary, an array, a string, or a number, depending
 * on the format of the API response.
 * If you need access to the raw response, use
 * (void)request:(FBRequest *)request didReceiveResponse:(NSURLResponse *)response.
 */
- (void)request:(FBRequest *)request didLoad:(id)result {
    DLog(@"request succeeded for url: %@ params: %@", request.url, request.params);
    //NSLog(@"%@", [result description]);
    NSInteger index = [_fbRequestQueue indexOfObject:request];
    
    if (index != NSNotFound) {
        FBRequestIdentifier *identifier = [_fbRequestIdentifiers objectAtIndex:index];
        if (identifier.receiver && identifier.callback) {
            [identifier.receiver performSelector:identifier.callback withObject:result];
        }
        [_fbRequestQueue removeObjectAtIndex:index];
        [_fbRequestIdentifiers removeObjectAtIndex:index];
    }
}


@end
