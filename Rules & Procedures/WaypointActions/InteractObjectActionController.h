//
//  InteractObjectActionController.h
//  Pocket Gnome
//
//  Created by Josh on 1/19/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ActionController.h"

@interface InteractObjectActionController : ActionController {
	IBOutlet NSPopUpButton	*objectsPopUp;
	
	NSArray *_objects;
}

+ (id)interactObjectActionControllerWithObjects: (NSArray*)objects;

@property (readwrite, copy) NSArray *objects;

@end
