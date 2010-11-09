//
//  BindingsController.h
//  Pocket Gnome
//
//  Created by Josh on 1/28/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Controller;
@class BotController;
@class ChatController;
@class OffsetController;

#define BindingPrimaryHotkey            @"MULTIACTIONBAR1BUTTON1"
#define BindingPrimaryHotkeyBackup      @"ACTIONBUTTON1"
#define BindingPetAttack                @"PETATTACK"
#define BindingInteractMouseover        @"INTERACTMOUSEOVER"
#define BindingTargetLast               @"TARGETLASTTARGET"
#define BindingTurnLeft                 @"TURNLEFT"
#define BindingTurnRight				@"TURNRIGHT"
#define BindingMoveForward				@"MOVEFORWARD"
#define BindingStrafeRight				@"STRAFERIGHT"
#define BindingStrafeLeft				@"STRAFELEFT"

@interface BindingsController : NSObject {
	
	IBOutlet Controller			*controller;
	IBOutlet ChatController		*chatController;
	IBOutlet OffsetController	*offsetController;
	IBOutlet BotController		*botController;
	
	
	NSArray *_requiredBindings;
	NSArray *_optionalBindings;
	
	NSMutableDictionary *_bindings;
	NSMutableDictionary *_keyCodesWithCommands;
	
	NSDictionary *_commandToAscii;

	NSMutableDictionary *_bindingsToCodes;		// used w/the defines above

	GUID _guid;
}

// this will send the command to the client (use the above 3 keys - defines)
- (BOOL)executeBindingForKey:(NSString*)key;

// just tells us if a binding exists!
- (BOOL)bindingForKeyExists:(NSString*)key;

// only called on bot start
- (void)reloadBindings;

// returns the bar offset (where the spell should be written to)
- (int)castingBarOffset;
	
// validates that all required key bindings exist! returns an error message
- (NSString*)keyBindingsValid;

@end
