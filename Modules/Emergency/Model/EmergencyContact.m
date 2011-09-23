#import "EmergencyContact.h"
#import "EmergencyContactsSection.h"

NSString * const EmergencyContactEntityName = @"EmergencyContact";

@implementation EmergencyContact
@dynamic title;
@dynamic subtitle;
@dynamic formattedPhone;
@dynamic dialablePhone;
@dynamic order;
@dynamic section;

- (NSString *)summary {
    if (self.subtitle) {
        return [NSString stringWithFormat:@"%@ (%@)", self.subtitle, self.formattedPhone];
    } else {
        return [NSString stringWithFormat:@"(%@)", self.formattedPhone];
    }
}

@end
