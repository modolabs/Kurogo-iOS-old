#import "KGOTableViewController.h"
#import <MapKit/MKMapView.h>

@interface MapSettingsViewController : KGOTableViewController {
    
    NSNumber *_mapTypePreference;

}

- (NSString *)mapTypeTitleForRow:(NSInteger)row;
- (MKMapType)mapTypeForRow:(NSInteger)row;

@end
