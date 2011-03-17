#import "TwitterSearch.h"
#import "JSON.h"
#import "Foundation+KGOAdditions.h"

@implementation TwitterSearch

@synthesize delegate;

- (void)searchTwitterHashtag:(NSString *)hashtag {
    if (_connection) {
        return;
    }
    
    NSString *urlString = [NSString stringWithFormat:@"http://search.twitter.com/search.json?q=#%@", hashtag];
    urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    _connection = [[ConnectionWrapper alloc] initWithDelegate:self];
    [_connection requestDataFromURL:[NSURL URLWithString:urlString] allowCachedResponse:YES];
}

- (void)connection:(ConnectionWrapper *)wrapper handleData:(NSData *)data {
    SBJsonParser *parser = [[[SBJsonParser alloc] init] autorelease];
    id jsonObj = [parser objectWithData:data];
    if ([jsonObj isKindOfClass:[NSDictionary class]]) {
        NSArray *results = [jsonObj arrayForKey:@"results"];
        [self.delegate twitterSearch:self didReceiveSearchResults:results];
    }
}

- (void)connection:(ConnectionWrapper *)wrapper handleConnectionFailureWithError:(NSError *)error {
    [self.delegate twitterSearch:self didFailWithError:error];
}


@end
