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
- (void)photoDidUpload:(id)result;

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

- (BOOL)requestFacebookGraphPath:(NSString *)graphPath receiver:(id)receiver callback:(SEL)callback {
    DLog(@"requesting graph path: %@", graphPath);
    FBRequest *request = [_facebook requestWithGraphPath:graphPath andDelegate:self];
    if ([self queueFacebookRequest:request withReceiver:receiver callback:callback]) {
        return YES;
    }
    return NO;
}

- (BOOL)requestFacebookFQL:(NSString *)query receiver:(id)receiver callback:(SEL)callback {
    DLog(@"requesting FQL: %@", query);
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:query forKey:@"query"];
    FBRequest *request = [_facebook requestWithMethodName:@"fql.query" andParams:params andHttpMethod:@"GET" andDelegate:self];
    if ([self queueFacebookRequest:request withReceiver:receiver callback:callback]) {
        [request connect];
        return YES;
    }
    return NO;
}

- (BOOL)likeFacebookPost:(FacebookParentPost *)post receiver:(id)receiver callback:(SEL)callback {
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
        return YES;
    }
    return NO;
}

- (BOOL)unlikeFacebookPost:(FacebookParentPost *)post receiver:(id)receiver callback:(SEL)callback {
    NSString *graphPath = [NSString stringWithFormat:@"%@/likes", post.identifier];
    FBRequest *request = [_facebook requestWithGraphPath:graphPath
                                               andParams:[NSMutableDictionary dictionary] // see comment above.
                                           andHttpMethod:@"DELETE"
                                             andDelegate:self];
    if ([self queueFacebookRequest:request withReceiver:receiver callback:callback]) {
        return YES;
    }
    return NO;
}

- (BOOL)addComment:(NSString *)comment toFacebookPost:(FacebookParentPost *)post delegate:(id<FacebookUploadDelegate>)delegate {
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:comment, @"message", nil];
    NSString *graphPath = post.postIdentifier.length ? post.postIdentifier : post.identifier;
    FBRequest *request = [_facebook requestWithGraphPath:[NSString stringWithFormat:@"%@/comments", graphPath]
                                               andParams:params
                                           andHttpMethod:@"POST"
                                             andDelegate:self];
    
    // TODO: clean this this fragile dictionary structure
    NSMutableDictionary *tempData = [[params mutableCopy] autorelease];
    [tempData setObject:@"comment" forKey:@"type"];
    [tempData setObject:delegate forKey:@"delegate"];
    
    [_fbUploadQueue addObject:request];
    [_fbUploadData addObject:tempData];
    
    return YES;
}

- (BOOL)uploadPhoto:(UIImage *)photo
  toFacebookProfile:(NSString *)profile
            message:(NSString *)caption
           delegate:(id<FacebookUploadDelegate>)delegate
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   caption, @"message",
                                   photo, @"image",
                                   nil];
    
    FBRequest *request = [_facebook requestWithGraphPath:[NSString stringWithFormat:@"%@/photos", profile]
                                               andParams:params
                                           andHttpMethod:@"POST"
                                             andDelegate:self];

    // TODO: clean this this fragile dictionary structure
    NSMutableDictionary *tempData = [[params mutableCopy] autorelease];
    [tempData setObject:@"photo" forKey:@"type"];
    [tempData setObject:delegate forKey:@"delegate"];
    
    [_fbUploadQueue addObject:request];
    [_fbUploadData addObject:tempData];
    
    return YES;
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
    
    NSArray *uploadDicts = [[_fbUploadData copy] autorelease];
    for (NSDictionary *aDict in uploadDicts) {
        if ([aDict objectForKey:@"delegate"] == receiver) {
            NSInteger index = [_fbUploadData indexOfObject:aDict];
            if (index != NSNotFound) {
                FBRequest *request = [_fbUploadQueue objectAtIndex:index];
                request.delegate = nil;
                [_fbUploadData removeObjectAtIndex:index];
                [_fbUploadQueue removeObjectAtIndex:index];
            }
        }
    }
}

#pragma mark -

- (void)didReceiveSelfInfo:(id)result {
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
        NSLog(@"getting facebook profile info");
        [self requestFacebookGraphPath:@"me" receiver:self callback:@selector(didReceiveSelfInfo:)];
        return nil;
    } else {
        DLog(@"have user but facebook session invalid");
        if (user) {
            user.isSelf = nil;
            [[CoreDataManager sharedManager] saveData];
        }
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
        return;
    }
    
    index = [_fbUploadQueue indexOfObject:request];
    if (index != NSNotFound) {
        FacebookPost *aPost = nil;
        
        NSDictionary *dictionary = [_fbUploadData objectAtIndex:index];
        NSString *type = [dictionary objectForKey:@"type"];
        if ([type isEqualToString:@"comment"] && [result isKindOfClass:[NSDictionary class]]) {
            NSString *identifier = [result stringForKey:@"id" nilIfEmpty:YES];
            FacebookComment *aComment = [FacebookComment commentWithID:identifier];
            if (aComment) {
                aComment.text = [dictionary stringForKey:@"message" nilIfEmpty:YES];
                aPost = aComment;
            }

        } else if ([type isEqualToString:@"photo"]) {
            NSString *identifier = [result stringForKey:@"id" nilIfEmpty:YES];
            FacebookPhoto *photo = [FacebookPhoto photoWithID:identifier];
            if (photo) {
                UIImage *image = [dictionary objectForKey:@"image"];
                photo.title = [dictionary objectForKey:@"message"];
                photo.height = [NSNumber numberWithFloat:image.size.height];
                photo.width = [NSNumber numberWithFloat:image.size.width];
                photo.data = UIImageJPEGRepresentation(image, 0.8);
            }
            aPost = photo;
        }
        if (aPost) {
            aPost.date = [NSDate date]; // may not be totally accurate but it will be within one network roundtrip (~1 min)
            aPost.owner = [self currentFacebookUser];
            id <FacebookUploadDelegate> delegate = [dictionary objectForKey:@"delegate"];
            
            [delegate uploadDidComplete:aPost];
        }
        
        [_fbUploadData removeObjectAtIndex:index];
        [_fbUploadQueue removeObjectAtIndex:index];
    }
}

// TODO: pass on errors to delegates
- (void)request:(FBRequest *)request didFailWithError:(NSError *)error {
    DLog(@"failed to request facebook url: %@ params: %@", request.url, request.params);
    NSLog(@"%@", [error description]);
    NSDictionary *userInfo = [error userInfo];
    if ([[userInfo stringForKey:@"type" nilIfEmpty:YES] isEqualToString:@"OAuthException"]) {
        [self logoutFacebook];
    }
    NSInteger index = [_fbRequestQueue indexOfObject:request];
    
    if (index != NSNotFound) {
        [_fbRequestQueue removeObjectAtIndex:index];
        [_fbRequestIdentifiers removeObjectAtIndex:index];
        return;
    }
    
    index = [_fbUploadQueue indexOfObject:request];
    if (index != NSNotFound) {
        [_fbUploadData removeObjectAtIndex:index];
        [_fbUploadQueue removeObjectAtIndex:index];
    }
}


@end
