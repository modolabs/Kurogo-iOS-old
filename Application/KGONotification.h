#import <Foundation/Foundation.h>


@interface KGONotification : NSNotification {

}

@property (nonatomic, readonly) NSString *moduleName;

+ (KGONotification *)notificationWithDictionary:(NSDictionary *)userInfo;

- (void)markAsRead;

@end
