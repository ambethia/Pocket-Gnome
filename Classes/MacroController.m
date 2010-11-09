//
//  MacroController.m
//  Pocket Gnome
//
//  Created by Josh on 9/21/09.
//  Copyright 2009 Savory Software, LLC. All rights reserved.
//

#import <Carbon/Carbon.h>

#import "MacroController.h"
#import "Controller.h"
#import "BotController.h"
#import "ActionMenusController.h"
#import "PlayerDataController.h"
#import "AuraController.h"
#import "ChatController.h"
#import "OffsetController.h"

#import "Player.h"
#import "MemoryAccess.h"
#import "Macro.h"

@interface MacroController (Internal)
- (void)reloadMacros;
- (BOOL)executeMacro: (NSString*)key;
- (Macro*)findMacro: (NSString*)key;
- (BOOL)overwriteMacro: (NSString*)macroCommand;
@end

@implementation MacroController


- (id) init{
    self = [super init];
    if (self != nil) {

		_playerMacros = nil;
		_macroDictionary = [[NSDictionary dictionaryWithContentsOfFile: [[NSBundle mainBundle] pathForResource: @"Macros" ofType: @"plist"]] retain];
		
		 // Notifications
		 [[NSNotificationCenter defaultCenter] addObserver: self
		 selector: @selector(playerIsValid:) 
		 name: PlayerIsValidNotification 
		 object: nil];
    }
    return self;
}

- (void) dealloc{
	[_macroDictionary release];
    [super dealloc];
}

@synthesize playerMacros = _playerMacros;

#pragma mark Notifications

//	update our list of macros when the player is valid
- (void)playerIsValid: (NSNotification*)not {
	[self reloadMacros];
}

- (BOOL)useMacroWithCommand: (NSString*)macroCommand{
	return [self overwriteMacro:macroCommand];
}

- (BOOL)useMacro: (NSString*)key;{
	
	if ( _macroDictionary ){
		NSDictionary *macroData = [_macroDictionary valueForKey:key];
		NSString *macroCommand = [macroData valueForKey:@"Macro"];
	
		return [self overwriteMacro:macroCommand];
	}
	
	return NO;
}

- (BOOL)useMacroWithKey: (NSString*)key andInt:(int)param{
	
	// set up the command
	NSDictionary *macroData = [_macroDictionary valueForKey:key];
	NSString *macroCommand = [macroData valueForKey:@"Macro"];
	macroCommand = [NSString stringWithFormat:@"%@%d", macroCommand, param];

	return [self overwriteMacro:macroCommand];
}

// returns the macro command for a key!
- (NSString*)macroTextForKey:(NSString*)key{
	NSDictionary *macroData = [_macroDictionary valueForKey:key];
	NSString *macroCommand = [macroData valueForKey:@"Macro"];
	return [[macroCommand retain] autorelease];
}

// actually will take an action (macro or send command)
- (void)useMacroOrSendCmd: (NSString*)key{
	
	NSDictionary *macroData = [_macroDictionary valueForKey:key];
	NSString *macroCommand = [macroData valueForKey:@"Macro"];
	
	if ( !macroCommand || [macroCommand length] == 0 ) {
		log(LOG_MACRO, @"Using the key as a command!");
		macroCommand = key;
	}

	BOOL macroExecuted = [self overwriteMacro:macroCommand];
	
	// if we didn't find a macro, lets send the command!
	if ( !macroExecuted ){

		// hit escape to close the chat window if it's open
		if ( [controller isWoWChatBoxOpen] ){
			log(LOG_MACRO, @"Sending escape to close open chat!");
			[chatController sendKeySequence: [NSString stringWithFormat: @"%c", kEscapeCharCode]];
			usleep(100000);
		}
		
		// send the command
		[chatController enter];
		usleep(100000);
		[chatController sendKeySequence: [NSString stringWithFormat: @"%@%c", macroCommand, '\n']];
		
		log(LOG_MACRO, @"I just typed the '%@' command. I'm not really sure why.", key);
	}
}

// this function will pull player macros from memory!
- (void)reloadMacros{
	
	// technically the first release does nothing
	[_playerMacros release]; _playerMacros = nil;
	
	// this is where we will store everything
	NSMutableArray *macros = [NSMutableArray array];
	
	// + 0x10 from this ptr is a ptr to the macro object list (but we don't need this)
	UInt32 offset = [offsetController offset:@"MACRO_LIST_PTR"];
	
	MemoryAccess *memory = [controller wowMemoryAccess];
	if ( !memory )
		return;
	
	UInt32 objectPtr = 0, macroID = 0;
	[memory loadDataForObject:self atAddress:offset Buffer:(Byte *)&objectPtr BufLength:sizeof(objectPtr)];
	
	// while we have a valid ptr!
	while ( ( objectPtr & 0x1 ) == 0 ){
		
		//	0x0==0x18 macro ID
		//	0x10 next ptr
		//	0x20 macro name
		//	0x60 macro icon
		//	0x160 macro text
		// how to determine if it's a character macro: (macroID & 0x1000000) == 0x1000000
		
		// initialize variables
		char macroName[17], macroText[256];
		macroName[16] = 0;
		macroText[255] = 0;
		NSString *newMacroName = nil;
		NSString *newMacroText = nil;
		
		// get the macro name
		if ( [memory loadDataForObject: self atAddress: objectPtr+0x20 Buffer: (Byte *)&macroName BufLength: sizeof(macroName)-1] ) {
			newMacroName = [NSString stringWithUTF8String: macroName];
		}
		
		// get the macro text
		if ( [memory loadDataForObject: self atAddress: objectPtr+0x160 Buffer: (Byte *)&macroText BufLength: sizeof(macroText)-1] ) {
			newMacroText = [NSString stringWithUTF8String: macroText];
		}
		
		// get the macro ID
		[memory loadDataForObject:self atAddress:objectPtr Buffer:(Byte *)&macroID BufLength:sizeof(macroID)];
		
		// add it to our list	
		Macro *macro = [Macro macroWithName:newMacroName number:[NSNumber numberWithInt:macroID] body:newMacroText isCharacter:((macroID & 0x1000000) == 0x1000000)];
		[macros addObject:macro];

		// get the next object ptr
		[memory loadDataForObject:self atAddress:objectPtr+0x10 Buffer:(Byte *)&objectPtr BufLength:sizeof(objectPtr)];
	}

	_playerMacros = [macros retain];
}

// pass an identifier and the macro will be executed!
- (BOOL)executeMacro: (NSString*)key{
	
	Macro *macro = [self findMacro:key];
	
	if ( macro ){
		UInt32 macroID = [[macro number] unsignedIntValue];
		
		//log(LOG_MACRO, @"Executing macro '%@' with id 0x%X", key, macroID);
		
		[botController performAction:USE_MACRO_MASK + macroID];
		usleep(100000);
		
		return YES;
	}
	
	return NO;	
}

// find a macro given the key (check Macros.plist)
- (Macro*)findMacro: (NSString*)key{
	
	// update our internal macro list first!
	[self reloadMacros];
	
	if ( _macroDictionary && _playerMacros ){

		// grab the macro data! (macro and the description)
		NSDictionary *macroData = [_macroDictionary valueForKey:key];
			
		// the actual command
		NSString *macroCommand = [macroData valueForKey:@"Macro"];
			
		// now lets loop through all of our player macros!
		for ( Macro *macro in _playerMacros ){
				
			// match found! yay!
			if ( [[macro body] isEqualToString:[NSString stringWithFormat:@"%@%c", macroCommand, '\n']] ){
				return macro;
			}
			
			// search for partial match!
			NSRange range = [[macro body] rangeOfString : macroCommand];
			if ( range.location != NSNotFound ) {
				log(LOG_MACRO, @"Found partial match! '%@'", macroCommand);
				return macro;
			}
		}
	}
	
	return nil;
}

// return a macro's name based on the ID!
- (NSString*)nameForID:(UInt32)macroID{
	
	// update our internal macro list first!
	[self reloadMacros];
	
	if ( _playerMacros ){
		
		// now lets loop through all of our player macros!
		for ( Macro *macro in _playerMacros ){
			
			if ( [[macro number] unsignedIntValue] == macroID ){
				return [[[macro name] retain] autorelease];
			}
		}
	}
	
	return nil;
}

// check to see if a macro exists with the following command IN it
- (int)macroIDForCommand: (NSString*)command{
	
	// update our internal macro list first!
	[self reloadMacros];
	
	if ( _playerMacros ){
			
		// now lets loop through all of our player macros!
		for ( Macro *macro in _playerMacros ){
			
			// match found! yay!
			if ( [[macro body] isEqualToString:[NSString stringWithFormat:@"%@%c", command, '\n']] ){
				return [macro.number intValue];
			}
			
			// search for partial match!
			NSRange range = [[macro body] rangeOfString : command];
			if ( range.location != NSNotFound ) {
				log(LOG_MACRO, @"Found partial match! '%@'", command);
				return [macro.number intValue];
			}
		}
	}
	
	return -1;	
}

// complicated i know
- (void)useMacroByID: (int)macroID{
	[botController performAction:USE_MACRO_MASK + macroID];
}

// this function will over-write the first macro found, use it, then set it back!
- (BOOL)overwriteMacro: (NSString*)macroCommand{
	
	// + 0x10 from this ptr is a ptr to the macro object list (but we don't need this)
	UInt32 offset = [offsetController offset:@"MACRO_LIST_PTR"];
	
	MemoryAccess *memory = [controller wowMemoryAccess];
	if ( !memory )
		return NO;
	
	UInt32 objectPtr = 0;
	[memory loadDataForObject:self atAddress:offset Buffer:(Byte *)&objectPtr BufLength:sizeof(objectPtr)];
	
	// just use the first found macro
	if ( ( objectPtr & 0x1 ) == 0 && _macroDictionary ){
		
		if ( macroCommand ){
			
			UInt32 macroID = 0;
			char macroName[17], macroBody[256];
			macroName[16] = 0;
			macroBody[255] = 0;
			NSString *newMacroName = nil;
			NSString *oldMacroBody = nil;
			
			// get the macro ID
			[memory loadDataForObject:self atAddress:objectPtr Buffer:(Byte *)&macroID BufLength:sizeof(macroID)];
			
			// get the macro name
			if ( [memory loadDataForObject: self atAddress: objectPtr+0x20 Buffer: (Byte *)&macroName BufLength: sizeof(macroName)-1] ) {
				newMacroName = [NSString stringWithUTF8String: macroName];
			}

			// get the macro text
			if ( [memory loadDataForObject: self atAddress: objectPtr+0x160 Buffer: (Byte *)&macroBody BufLength: sizeof(macroBody)-1] ) {
				oldMacroBody = [NSString stringWithUTF8String: macroBody];
			}
			
			// over-write the text
			char newMacroBody[255];
			const char *body = [macroCommand UTF8String];
			
			// no reason it shouldn't be less than, but just in case some1 tries to buffer overflow our asses
			if ( strlen(body) < 255 ){
				strcpy( newMacroBody, body ); 
				
				// null-terminate our string
				newMacroBody[strlen(body)] = '\0';
			}
			else{
				newMacroBody[0] = '\0';
			}
			
			// write the new command
			[memory saveDataForAddress: objectPtr+0x160 Buffer: (Byte *)newMacroBody BufLength:sizeof(newMacroBody)];
			
			// probably not necessary
			usleep(100000);
			
			// execute macro
			[botController performAction:macroID + USE_MACRO_MASK];
			
			// probably not necessary
			usleep(100000);
			
			// set the text back
			const char *oldBody = [oldMacroBody UTF8String];
			strcpy( newMacroBody, oldBody );
			newMacroBody[strlen(oldBody)] = '\0';
			[memory saveDataForAddress: objectPtr+0x160 Buffer: (Byte *)newMacroBody BufLength:sizeof(newMacroBody)];
			
			log(LOG_MACRO, @"Completed execution of %@ using macro ID %d", macroCommand, macroID);
			
			return YES;
		}
		else{
			log(LOG_MACRO, @"Error, unable to find execute a null macro command!");
		}
	}
	
	return NO;
}

- (NSArray*)macros{
	return [[_playerMacros retain] autorelease];
}

@end
