#import "MapKit+KGOAdditions.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "Foundation+KGOAdditions.h"

@implementation MKMapView (KGOAdditions)

- (void)centerAndZoomToDefaultRegion {
    // TODO: remove this thing about NSUserDefaults if we aren't actually
    // going to use it
    NSDictionary *locationPreferences = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"Location"];
    if (!locationPreferences) {    
        KGOAppDelegate *appDelegate = KGO_SHARED_APP_DELEGATE();
        locationPreferences = [[appDelegate appConfig] dictionaryForKey:@"Location"];
    }
    MKCoordinateRegion region = self.region;
    
    NSString *latLonString = [locationPreferences nonemptyStringForKey:@"DefaultCenter"];
    if (latLonString) {
        NSArray *parts = [latLonString componentsSeparatedByString:@","];
        if (parts.count == 2) {
            NSString *lat = [parts objectAtIndex:0];
            NSString *lon = [parts objectAtIndex:1];
            region.center = CLLocationCoordinate2DMake([lat floatValue], [lon floatValue]);
        }
    }
    CGFloat zoom = [locationPreferences floatForKey:@"DefaultZoom"];
    if (zoom) {
        region.span = [MKMapView coordinateSpanForZoomLevel:zoom];
    }
    self.region = region;
}

- (CGFloat)zoomLevel {
    return [MKMapView zoomLevelForCoordinateSpan:self.region.span];
}

- (void)setZoomLevel:(CGFloat)zoomLevel {
    MKCoordinateRegion region = self.region;
    region.span = [MKMapView coordinateSpanForZoomLevel:zoomLevel];
    self.region = region;
}

+ (MKCoordinateSpan)coordinateSpanForZoomLevel:(CGFloat)zoomLevel {
    double numberOfSpansToFillEquator = pow(2, zoomLevel - 1);
    CGFloat lonDelta = 360.0 / numberOfSpansToFillEquator;
    return MKCoordinateSpanMake(lonDelta, lonDelta);
}

+ (CGFloat)zoomLevelForCoordinateSpan:(MKCoordinateSpan)coordinateSpan {
    double numberOfSpansToFillEquator = 360.0 / coordinateSpan.longitudeDelta;
    return (CGFloat) log(numberOfSpansToFillEquator) / log(2) + 1;
}

@end
