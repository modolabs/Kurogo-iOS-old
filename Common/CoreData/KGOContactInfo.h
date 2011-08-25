#import <CoreData/CoreData.h>


@interface KGOContactInfo : NSManagedObject {

}

@property (nonatomic, retain) NSString *identifier;
@property (nonatomic, retain) NSString *label;
@property (nonatomic, retain) NSString *value;
@property (nonatomic, retain) NSString *type; // e.g. phone, group
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *subtitle;
@property (nonatomic, retain) NSString *url;
@property (nonatomic, retain) NSString *group;

@end
