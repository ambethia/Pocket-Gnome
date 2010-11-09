//
//  MacroActionController.h
//  Pocket Gnome
//
//  Created by Josh on 1/15/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ActionController.h"

@interface MacroActionController : ActionController {
	IBOutlet NSPopUpButton	*macroPopUp;
	IBOutlet NSButton		*instantButton;
	
	NSArray *_macros;
}

+ (id)macroActionControllerWithMacros: (NSArray*)macros;

@property (readwrite, copy) NSArray *macros;
@end
