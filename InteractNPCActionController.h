//
//  InteractNPCActionController.h
//  Pocket Gnome
//
//  Created by Josh on 1/19/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ActionController.h"

@interface InteractNPCActionController : ActionController {
	IBOutlet NSPopUpButton	*unitsPopUp;
	
	NSArray *_units;
}

+ (id)interactNPCActionControllerWithUnits: (NSArray*)units;

@property (readwrite, copy) NSArray *units;

@end
