// this is a temporary file that just searches a hash tag
// may evolve into a more complete twitter api controller

#import <Foundation/Foundation.h>
#import "ConnectionWrapper.h"

@class TwitterSearch;

@protocol TwitterSearchDelegate <NSObject>

- (void)twitterSearch:(TwitterSearch *)twitterSearch didReceiveSearchResults:(NSArray *)results;
- (void)twitterSearch:(TwitterSearch *)twitterSearch didFailWithError:(NSError *)error;

@end


@interface TwitterSearch : NSObject <ConnectionWrapperDelegate> {

    ConnectionWrapper *_connection;
    
}

@property(nonatomic, assign) id <TwitterSearchDelegate> delegate;

- (void)searchTwitterHashtag:(NSString *)hashtag;

@end
