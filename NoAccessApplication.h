//
//  NoAccessApplication.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 6/21/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NoAccessApplication : NSApplication {
    BOOL allowAccessibility;
}

@property BOOL allowAccessibility;

@end
