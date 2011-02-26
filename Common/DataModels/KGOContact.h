#import <CoreData/CoreData.h>


@interface KGOContact : NSManagedObject {

}

@property (nonatomic, retain) NSString *identifier;
@property (nonatomic, retain) NSString *label;
@property (nonatomic, retain) NSString *value;
@property (nonatomic, retain) NSString *type; // e.g. phone, email, im, url

@end
