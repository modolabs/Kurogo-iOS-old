#import "FacebookPhotosViewController.h"
#import "Foundation+KGOAdditions.h"
#import "FacebookModel.h"
#import <QuartzCore/QuartzCore.h>
#import "CoreDataManager.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "PhotoUploadViewController.h"
#import "PhotosModule.h"
#import "FacebookModule.h"

@implementation FacebookPhotosViewController

- (void)getGroupPhotos {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FacebookGroupReceivedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FacebookFeedDidUpdateNotification object:nil];
    
    FacebookModule *fbModule = (FacebookModule *)[(KGOAppDelegate *)[[UIApplication sharedApplication] delegate] moduleForTag:@"facebook"];
    if (fbModule.groupID) {
        if (fbModule.latestFeedPosts) {
            for (NSDictionary *aPost in fbModule.latestFeedPosts) {
                NSString *type = [aPost stringForKey:@"type" nilIfEmpty:YES];
                if ([type isEqualToString:@"photo"]) {
                    NSString *pid = [aPost stringForKey:@"object_id" nilIfEmpty:YES];
                    if (pid && ![_photosByID objectForKey:pid]) {
                        FacebookPhoto *aPhoto = [FacebookPhoto photoWithDictionary:aPost];
                        if (aPhoto) {
                            aPhoto.postIdentifier = [aPost stringForKey:@"id" nilIfEmpty:YES];
                            NSLog(@"%@", [aPhoto description]);
                            [[CoreDataManager sharedManager] saveData];
                            [_photosByID setObject:aPhoto forKey:pid];
                            [self displayPhoto:aPhoto];
                        }
                        
                        DLog(@"requesting graph info for photo %@", pid);
                        [[KGOSocialMediaController sharedController] requestFacebookGraphPath:pid
                                                                                     receiver:self
                                                                                     callback:@selector(didReceivePhoto:)];
                    }
                }
            }

        } else {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(getGroupPhotos)
                                                         name:FacebookGroupReceivedNotification
                                                       object:nil];
        }
        
        // fql for photos
        NSString *query = [NSString stringWithFormat:@"SELECT pid FROM photo_tag WHERE subject=%@", fbModule.groupID];
        [[KGOSocialMediaController sharedController] requestFacebookFQL:query receiver:self callback:@selector(didReceivePhotoList:)];

    } else {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(getGroupPhotos)
                                                     name:FacebookFeedDidUpdateNotification
                                                   object:nil];
    }
}


// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Photos";
    
    CGRect frame = _scrollView.frame;
    frame.origin.y += _signedInUserView.frame.size.height;
    frame.size.height -= _signedInUserView.frame.size.height;
    _iconGrid = [[IconGrid alloc] initWithFrame:frame];
    _iconGrid.delegate = self;
    _iconGrid.spacing = GridSpacingMake(10, 10);
    _iconGrid.padding = GridPaddingMake(10, 10, 10, 10);
    _iconGrid.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _iconGrid.backgroundColor = [UIColor clearColor];
    
    [_scrollView addSubview:_iconGrid];
    
    _icons = [[NSMutableArray alloc] init];
    _photosByThumbSrc = [[NSMutableDictionary alloc] init];
    _photosByID = [[NSMutableDictionary alloc] init];
    _displayedPhotos = [[NSMutableSet alloc] init];
    
    [self loadThumbnailsFromCache];
    [self getGroupPhotos];
    
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Upload"
                                                                               style:UIBarButtonItemStyleBordered
                                                                              target:self
                                                                              action:@selector(showUploadPhotoController:)] autorelease];
}


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [[KGOSocialMediaController sharedController] disconnectFacebookRequests:self];

    [_iconGrid release];
    [_icons release];
    [_displayedPhotos release];
    [_photosByThumbSrc release];
    [_photosByID release];
    [super dealloc];
}

#pragma Icon grid delegate

- (void)iconGridFrameDidChange:(IconGrid *)iconGrid {
    CGSize size = _scrollView.contentSize;
    size.height = iconGrid.frame.size.height + _signedInUserView.frame.size.height;
    _scrollView.contentSize = size;
}

#pragma mark When we already have photos

- (void)loadThumbnailsFromCache {
    // TODO: sort by date or whatever
    NSArray *photos = [[CoreDataManager sharedManager] objectsForEntity:FacebookPhotoEntityName matchingPredicate:nil];
    for (FacebookPhoto *aPhoto in photos) {
        //[_photosByID setObject:aPhoto forKey:aPhoto.identifier];
        NSLog(@"found cached photo %@", aPhoto.identifier);
        //[self displayPhoto:aPhoto];
    }
    [[CoreDataManager sharedManager] deleteObjects:photos];
}

- (void)displayPhoto:(FacebookPhoto *)photo
{
    if ([_displayedPhotos containsObject:photo.identifier]) {
        return;
    }
    
    if (photo.thumbSrc || photo.thumbData || photo.data) { // omitting photo.src so we don't download full image until detail view
        FacebookThumbnail *thumbnail = [[[FacebookThumbnail alloc] initWithFrame:CGRectMake(0, 0, 90, 130)] autorelease];
        thumbnail.photo = photo;
        thumbnail.rotationAngle = (_icons.count % 2 == 0) ? M_PI/12 : -M_PI/12;
        [thumbnail addTarget:self action:@selector(thumbnailTapped:) forControlEvents:UIControlEventTouchUpInside];
        [_icons addObject:thumbnail];
        _iconGrid.icons = _icons;
        [_iconGrid setNeedsLayout];
        
        [_displayedPhotos addObject:photo.identifier];
    }
}

- (void)thumbnail:(MITThumbnailView *)thumbnail didLoadData:(NSData *)data {
    FacebookPhoto *photo = [_photosByThumbSrc objectForKey:thumbnail.imageURL];
    if (photo) {
        photo.thumbData = data;
    }
    [[CoreDataManager sharedManager] saveData];
}

- (void)thumbnailTapped:(FacebookThumbnail *)sender {
    FacebookPhoto *photo = sender.photo;
    NSMutableArray *photos = [NSMutableArray array];
    [_icons enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        FacebookThumbnail *thumbnail = (FacebookThumbnail *)obj;
        NSLog(@"adding photo with id %@", thumbnail.photo.identifier);
        [photos addObject:thumbnail.photo];
    }];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:photo, @"photo", photos, @"photos", nil];
    [(KGOAppDelegate *)[[UIApplication sharedApplication] delegate] showPage:LocalPathPageNameDetail forModuleTag:PhotosTag params:params];
}

#pragma mark Photo uploads

- (void)showUploadPhotoController:(id)sender
{
    UIImagePickerController *picker = [[[UIImagePickerController alloc] init] autorelease];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.delegate = self;
    [(KGOAppDelegate *)[[UIApplication sharedApplication] delegate] presentAppModalViewController:picker animated:YES];
}

- (void)imagePickerController:(UIImagePickerController *)picker
        didFinishPickingImage:(UIImage *)image
                  editingInfo:(NSDictionary *)editingInfo
{
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:image, @"photo", _gid, @"profile", self, @"parentVC", nil];
    [(KGOAppDelegate *)[[UIApplication sharedApplication] delegate] showPage:LocalPathPageNamePhotoUpload
                                                                forModuleTag:PhotosTag
                                                                      params:params];
}

- (void)uploadDidComplete:(FacebookPost *)result {
    [(KGOAppDelegate *)[[UIApplication sharedApplication] delegate] dismissAppModalViewControllerAnimated:YES];    
    
    FacebookPhoto *photo = (FacebookPhoto *)result;
    [_photosByID setObject:photo forKey:photo.identifier];
    
    [[KGOSocialMediaController sharedController] requestFacebookGraphPath:photo.identifier
                                                                 receiver:self
                                                                 callback:@selector(didReceivePhoto:)];
    
    [self displayPhoto:photo];
}

#pragma mark Facebook request callbacks
/*
- (void)didReceiveGroups:(id)result {
    
    NSArray *data = [result arrayForKey:@"data"];
    for (id aGroup in data) {
        if ([[aGroup objectForKey:@"name"] isEqualToString:@"Modo Labs UX"]) {
            _gid = [[aGroup objectForKey:@"id"] retain];

            // fql for photos
            NSString *query = [NSString stringWithFormat:@"SELECT pid FROM photo_tag WHERE subject=%@", _gid];
            [[KGOSocialMediaController sharedController] requestFacebookFQL:query receiver:self callback:@selector(didReceivePhotoList:)];

            // group feed
            NSString *feedPath = [NSString stringWithFormat:@"%@/feed", _gid];
            [[KGOSocialMediaController sharedController] requestFacebookGraphPath:feedPath receiver:self callback:@selector(didReceiveFeed:)];
        }
    }

}
*/
- (void)didReceivePhotoList:(id)result {
    
    if ([result isKindOfClass:[NSArray class]]) {
        
        for (NSDictionary *info in result) {
            NSString *pid = [info objectForKey:@"pid"];
            if (pid && ![_photosByID objectForKey:pid]) {
                DLog(@"received fql info for photo %@", pid);
                NSString *query = [NSString stringWithFormat:@"SELECT object_id, "
                                   "src_small, src_small_width, src_small_height, "
                                   "src, src_width, src_height, "
                                   "owner, caption, created, aid "
                                   "FROM photo WHERE pid=%@", pid];
                
                [[KGOSocialMediaController sharedController] requestFacebookFQL:query receiver:self callback:@selector(didReceivePhoto:)];
            }
        }
    }
}

- (void)didReceivePhoto:(id)result {
    DLog(@"info for photo: %@", [result description]);
    
    NSDictionary *photoInfo = nil;
    
    // TODO: check these requests against their origin rather than just checking type
    if ([result isKindOfClass:[NSDictionary class]]) {
        photoInfo = (NSDictionary *)result;
        
    } else if ([result isKindOfClass:[NSArray class]]) {
        // request came from fql
        photoInfo = [result lastObject];
    }
    
    NSString * identifier = [photoInfo objectForKey:@"object_id"]; // via feed or FQL
    if (!identifier) {
        identifier = [photoInfo objectForKey:@"id"]; // via Photo Graph API
    }
    identifier = [NSString stringWithFormat:@"%@", identifier];
    
    FacebookPhoto *photo = [_photosByID objectForKey:identifier];
    
    if (photo) {
        [photo updateWithDictionary:photoInfo];
        [self displayPhoto:photo];
        
    } else {
        photo = [FacebookPhoto photoWithDictionary:photoInfo];
        if (photo) {
            [_photosByID setObject:photo forKey:photo.identifier];
            [self displayPhoto:photo];
        }
    }
}

/*
- (void)didReceiveFeed:(id)result {
    
    NSArray *data = [result arrayForKey:@"data"];
    for (NSDictionary *aPost in data) {
        NSString *type = [aPost stringForKey:@"type" nilIfEmpty:YES];
        if ([type isEqualToString:@"photo"]) {
            NSString *pid = [aPost stringForKey:@"object_id" nilIfEmpty:YES];
            if (pid && ![_photosByID objectForKey:pid]) {
                FacebookPhoto *aPhoto = [FacebookPhoto photoWithDictionary:aPost];
                if (aPhoto) {
                    aPhoto.postIdentifier = [aPost stringForKey:@"id" nilIfEmpty:YES];
                    NSLog(@"%@", [aPhoto description]);
                    [[CoreDataManager sharedManager] saveData];
                    [_photosByID setObject:aPhoto forKey:pid];
                    [self displayPhoto:aPhoto];
                }

                DLog(@"requesting graph info for photo %@", pid);
                [[KGOSocialMediaController sharedController] requestFacebookGraphPath:pid
                                                                             receiver:self
                                                                             callback:@selector(didReceivePhoto:)];
            }
        }
    }
}
*/
@end

@implementation FacebookThumbnail

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        _label = [[UILabel alloc] initWithFrame:CGRectMake(0, 90, 90, 40)];
        _label.backgroundColor = [UIColor clearColor];
        _label.textColor = [UIColor whiteColor];
        _label.numberOfLines = 3;
        _label.font = [UIFont systemFontOfSize:10];
        _label.userInteractionEnabled = NO;
        
        _thumbnail = [[MITThumbnailView alloc] initWithFrame:CGRectMake(0, 0, 90, 90)];
        _thumbnail.contentMode = UIViewContentModeScaleAspectFit;
        _thumbnail.userInteractionEnabled = NO;

        [self addSubview:_thumbnail];
        [self addSubview:_label];
    }
    return self;
}

- (FacebookPhoto *)photo {
    return _photo;
}

- (void)setPhoto:(FacebookPhoto *)photo {
    [_photo release];
    _photo = [photo retain];
    
    _label.text = photo.title;
    if (photo.thumbData) {
        _thumbnail.imageData = photo.thumbData;
    } else if (photo.thumbSrc) {
        _thumbnail.imageURL = photo.thumbSrc;
    } else if (photo.data) {
        _thumbnail.imageData = photo.data;
    }
    [_thumbnail loadImage];
}

- (CGFloat)rotationAngle {
    return _rotationAngle;
}

- (void)setRotationAngle:(CGFloat)rotationAngle {
    _rotationAngle = rotationAngle;
    _thumbnail.transform = CGAffineTransformMakeRotation(rotationAngle);
}

- (void)dealloc {
    self.photo = nil;
    [_thumbnail release];
    [_label release];
    [super dealloc];
}

@end
