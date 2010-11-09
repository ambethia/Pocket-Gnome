//
//  TransparentWindow.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 3/31/07.
//  Copyright 2007 Savory Software, LLC. All rights reserved.
//

#import "TransparentWindow.h"


@implementation TransparentWindow

- (id)initWithContentRect: (NSRect)contentRect
				styleMask: (unsigned int)styleMask
				  backing: (NSBackingStoreType)bufferingType
					defer: (BOOL)deferCreation {
	
	if ((self = [super initWithContentRect: contentRect
								 styleMask: NSBorderlessWindowMask 
								   backing: bufferingType
								     defer: deferCreation])) {
										   
		[self setBackgroundColor: [NSColor clearColor]];
        [self setAlphaValue: 1.0];
		[self setOpaque: NO];
		[self setHasShadow: NO];
		[self setMovableByWindowBackground: NO];
	}
	
	return self;
}

@end
