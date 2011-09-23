#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class EmergencyContact;

@interface EmergencyContactsSection : NSManagedObject {
@private
}
@property (nonatomic, retain) ModuleTag * moduleTag;
@property (nonatomic, retain) NSString * sectionTag;
@property (nonatomic, retain) NSDate * lastUpdate;
@property (nonatomic, retain) NSSet* contacts;

@end
