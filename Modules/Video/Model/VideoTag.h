//
//  VideoTag.h
//  Universitas
//
//  Created by Jim Kang on 3/30/11.
//  Copyright 2011 Modo Labs. All rights reserved.
//

#import <CoreData/CoreData.h>

@class Video;

@interface VideoTag :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) Video * includedInVideos;

@end



