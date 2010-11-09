//
//  IgnoreEntry.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 7/19/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum {
    IgnoreType_EntryID,
    IgnoreType_Name,
} IgnoreType;

@interface IgnoreEntry : NSObject <NSCoding, NSCopying> {
    NSNumber *_ignoreType;
    id _ignoreValue;
}

+ (id)entry;

- (IgnoreType)type;
@property (readwrite, assign) NSNumber *ignoreType;
@property (readwrite, retain) id ignoreValue;

@end
