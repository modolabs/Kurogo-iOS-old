#import "LibraryItem.h"
#import "CoreDataManager.h"

@implementation LibraryItem 

@dynamic publisher;
@dynamic itemId;
@dynamic title;
@dynamic nonLatinTitle;
@dynamic workType;
@dynamic fullImageLink;
@dynamic formatDetail;
@dynamic onlineLink;
@dynamic callNumber;
@dynamic isBookmarked;
@dynamic typeDetail;
@dynamic edition;
@dynamic year;
@dynamic details;
@dynamic numberOfImages;
@dynamic catalogLink;
@dynamic thumbnailURL;
@dynamic figureLink;
@dynamic author;
@dynamic nonLatinAuthor;
@dynamic authorLink;
@dynamic thumbnailImage;

- (void)requestImage {
    if ([self.thumbnailURL length]) {
        NSError *error = nil;
        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:self.thumbnailURL] options:NSDataReadingUncached error:&error];
        if (!data) {
            NSLog(@"could not read data: %@", [error description]);
        } else {
            self.thumbnailImage = data;
            [CoreDataManager saveData];
        }
    }
}

@end
