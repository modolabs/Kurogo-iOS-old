#import <CoreData/CoreData.h>


@interface KGOContactInfo : NSManagedObject {

}

@property (nonatomic, retain) NSString *identifier;
@property (nonatomic, retain) NSString *label; // e.g. work, home

// e.g. 6175551234. usually used to construct a url for openURL:
// url property may be used instead.
@property (nonatomic, retain) NSString *value;
@property (nonatomic, retain) NSString *type;  // e.g. phone, group
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *subtitle;
@property (nonatomic, retain) NSString *url;

@end
