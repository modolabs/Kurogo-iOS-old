#import <Foundation/Foundation.h>

@protocol BitlyWrapperDelegate <NSObject>

- (void)didGetBitlyURL:(NSString *)url;

@optional

- (void)failedToGetBitlyURL;

@end
