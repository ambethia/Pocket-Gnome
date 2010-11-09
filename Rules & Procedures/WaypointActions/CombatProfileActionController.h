//
//  CombatProfileActionController.h
//  Pocket Gnome
//
//  Created by Josh on 1/19/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ActionController.h"

@interface CombatProfileActionController : ActionController {
	IBOutlet NSPopUpButton	*profilePopUp;
	
	NSArray *_profiles;
}

+ (id)combatProfileActionControllerWithProfiles: (NSArray*)profiles;

@property (readwrite, copy) NSArray *profiles;

@end
