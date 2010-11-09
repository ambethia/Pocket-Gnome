//
//  ItemActionController.h
//  Pocket Gnome
//
//  Created by Josh on 1/15/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "ActionController.h"

@interface ItemActionController : ActionController {
	IBOutlet NSPopUpButton	*itemPopUp;
	IBOutlet NSButton		*itemInstantButton;
	
	NSArray *_items;
}

+ (id)itemActionControllerWithItems: (NSArray*)items;

@property (readwrite, copy) NSArray *items;
@end
