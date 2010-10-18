//
//  SpellActionController.h
//  Pocket Gnome
//
//  Created by Josh on 1/15/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "ActionController.h"

@interface SpellActionController : ActionController {
	IBOutlet NSPopUpButton	*spellPopUp;
	IBOutlet NSButton		*spellInstantButton;
	
	NSArray *_spells;
}

+ (id)spellActionControllerWithSpells: (NSArray*)spells;

@property (readwrite, copy) NSArray *spells;

@end
