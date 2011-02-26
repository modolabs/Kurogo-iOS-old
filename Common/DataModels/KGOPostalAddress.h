#import <CoreData/CoreData.h>

@interface KGOPostalAddress : NSManagedObject {

}

@property (nonatomic, retain) NSString *displayAddress; // if it is not possible to parse out individual address fields
@property (nonatomic, retain) NSString *label; // what kind of address this is, e.g. home, work

@property (nonatomic, retain) NSString *street;
@property (nonatomic, retain) NSString *street2;
@property (nonatomic, retain) NSString *city;
@property (nonatomic, retain) NSString *state;
@property (nonatomic, retain) NSString *zip;
@property (nonatomic, retain) NSString *country;

@end
