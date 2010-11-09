//
//  NSString+Extras.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 7/13/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import "NSString+Extras.h"


@implementation NSString (Trash)

- (BOOL)moveToTrash {
    log(LOG_GENERAL, @"Deleting: \"%s\"", [self fileSystemRepresentation]);
    FSRef fileRef;
    if(FSPathMakeRef( (const UInt8 *)[self fileSystemRepresentation], &fileRef, NULL ) == noErr) {
        if(FSMoveObjectToTrashSync(&fileRef, NULL, kFSFileOperationDefaultOptions) == noErr) {
            return YES;
        }
    }
    return NO;
}

@end

