//
//  TransparentWindow.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 3/31/07.
//  Copyright 2007 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TransparentWindow : NSWindow
{
}
- (id)initWithContentRect: (NSRect)contentRect
				styleMask: (unsigned int)styleMask
				  backing: (NSBackingStoreType)bufferingType
					defer: (BOOL)deferCreation;
@end