#import <CoreData/CoreData.h>

@class PersonDetail;

@interface PersonDetails :  NSManagedObject  
{
}

@property (nonatomic, retain) NSDate * lastUpdate;
@property (nonatomic, retain) PersonDetail * mail;
@property (nonatomic, retain) PersonDetail * cn;
@property (nonatomic, retain) PersonDetail * uid;
@property (nonatomic, retain) PersonDetail * facsimiletelephonenumber;
@property (nonatomic, retain) PersonDetail * title;
@property (nonatomic, retain) PersonDetail * telephonenumber;
@property (nonatomic, retain) PersonDetail * sn;
@property (nonatomic, retain) PersonDetail * postaladdress;
@property (nonatomic, retain) PersonDetail * ou;
@property (nonatomic, retain) PersonDetail * givenname;

@end



