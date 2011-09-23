#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface EmergencyNotice : NSManagedObject {
@private
}
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * html;
@property (nonatomic, retain) ModuleTag * moduleTag;
@property (nonatomic, retain) NSDate * pubDate;

@end
