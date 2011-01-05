// 
//  LibraryItem.m
//  Harvard Mobile
//
//  Created by sonya huang on 2011/1/5.
//  Copyright 2011 mit. All rights reserved.
//

#import "LibraryItem.h"


@implementation LibraryItem 

@dynamic publisher;
@dynamic itemId;
@dynamic title;
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

- (UIImage *)thumbnailImage {
    NSString *path = [self thumbnailImagePath];
    UIImage *image = nil;
    if (path && [[NSFileManager defaultManager] fileExistsAtPath:path]) {
        image = [UIImage imageWithContentsOfFile:path];
    }
    return image;
}

- (NSString *)thumbnailImagePath {
    NSString *result = nil;

    if ([self.thumbnailURL length]) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentPath = [paths objectAtIndex:0];
        NSString *libraryDir = [documentPath stringByAppendingPathComponent:@"library"];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:libraryDir]) {
            NSError* error = nil;
            [[NSFileManager defaultManager] createDirectoryAtPath:libraryDir
                                      withIntermediateDirectories:YES
                                                       attributes:nil
                                                            error:&error];
        }
        
        NSString *imageFileName = [NSString stringWithFormat:@"%d", [self.thumbnailURL hash]];
        result = [libraryDir stringByAppendingPathComponent:imageFileName];
    }
    return result;
}

- (void)requestImage {
    if ([self.thumbnailURL length]) {
        NSError *error = nil;
        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:self.thumbnailURL] options:NSDataReadingUncached error:&error];
        if (!data) {
            NSLog(@"could not read data: %@", [error description]);
        } else {
            [data writeToFile:[self thumbnailImagePath] atomically:YES];
        }
    }
}

@end
