#import "KGOMapCategory.h"
#import "KGOPlacemark.h"

@implementation KGOMapCategory

@dynamic title;
@dynamic identifier;
@dynamic sortOrder;
@dynamic places;
@dynamic subcategories;
@dynamic parentCategory;

- (NSArray *)items {
	return [self.places allObjects];
}

- (KGOMapCategory *)parent {
	return self.parentCategory;
}

- (NSArray *)children {
	return [self.subcategories allObjects];
}

@end
