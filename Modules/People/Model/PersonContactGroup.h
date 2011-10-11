#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "KGOSearchModel.h"

@class PersonContact;

@interface PersonContactGroup : NSManagedObject <KGOCategory> {
@private
}
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * sortOrder;
@property (nonatomic, retain) NSSet* contacts;

+ (PersonContactGroup *)contactGroupWithDict:(NSDictionary *)dict;

+ (PersonContactGroup *)contactGroupWithID:(NSString *)groupID;

@end
