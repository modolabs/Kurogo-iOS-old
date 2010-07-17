#import <CoreData/CoreData.h>


@interface PersonDetails :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * telephoneNumber;
@property (nonatomic, retain) NSString * uid;
@property (nonatomic, retain) NSString * facsimileTelephoneNumber;
@property (nonatomic, retain) NSString * postalAddress;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * mail;
@property (nonatomic, retain) NSDate * lastUpdate;
@property (nonatomic, retain) NSString * sn;
@property (nonatomic, retain) NSString * ou;
@property (nonatomic, retain) NSString * givenname;

@end



