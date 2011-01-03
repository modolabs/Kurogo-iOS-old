#import "LibraryAnnotation.h"
#import "LibraryAlias.h"

@implementation LibraryAnnotation
//@synthesize library = _library;
@synthesize subtitle = _subtitle;
@synthesize libAlias = _libAlias;

-(id) initWithLibrary:(LibraryAlias *)library
{
	if (self = [super init]) {
		_libAlias = [library retain];
	}
	
	return self;
}

-(void) dealloc
{
	[_libAlias release];
	
	[super dealloc];
}

-(CLLocationCoordinate2D) coordinate
{
	CLLocationCoordinate2D coordinate;
	coordinate.latitude = [_libAlias.library.lat doubleValue];
	coordinate.longitude = [_libAlias.library.lon doubleValue];
	
	return coordinate;
}

-(NSString*) title
{
	return _libAlias.name;
}

@end
