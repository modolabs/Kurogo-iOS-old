#import <CoreData/CoreData.h>

@class PersonDetails;

@interface PersonDetail :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * DisplayName;
@property (nonatomic, retain) NSString * Value;
@property (nonatomic, retain) PersonDetails * mailParent;
@property (nonatomic, retain) PersonDetails * cnParent;
@property (nonatomic, retain) PersonDetails * titleParent;
@property (nonatomic, retain) PersonDetails * facsimiletelephonenumberParent;
@property (nonatomic, retain) PersonDetails * postaladdressParent;
@property (nonatomic, retain) PersonDetails * snParent;
@property (nonatomic, retain) PersonDetails * givennameParent;
@property (nonatomic, retain) PersonDetails * ouParent;
@property (nonatomic, retain) PersonDetails * telephonenumberParent;
@property (nonatomic, retain) PersonDetails * uidParent;

@end



