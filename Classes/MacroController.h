//
//  MacroController.m
//  Pocket Gnome
//
//  Created by Josh on 9/21/09.
//  Copyright 2009 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Controller;
@class BotController;
@class PlayerDataController;
@class AuraController;
@class ChatController;
@class OffsetController;

@interface MacroController : NSObject {
	IBOutlet Controller				*controller;
	IBOutlet BotController			*botController;
	IBOutlet PlayerDataController	*playerData;
	IBOutlet AuraController			*auraController;
	IBOutlet ChatController			*chatController;
	IBOutlet OffsetController		*offsetController;
	
	NSArray *_playerMacros;
	NSDictionary *_macroDictionary;
	NSDictionary *_macroMap;
}

@property (readonly) NSArray *playerMacros;

// this will make us do something!
- (void)useMacroOrSendCmd: (NSString*)key;

// check to see if the macro exists + will return the key
- (int)macroIDForCommand: (NSString*)command;

// execute a macro by it's ID
- (void)useMacroByID: (int)macroID;

// only use the macro (it won't send the command)
- (BOOL)useMacro: (NSString*)key;

// use a macro with a parameter
- (BOOL)useMacroWithKey: (NSString*)key andInt:(int)param;

// use a macro
- (BOOL)useMacroWithCommand: (NSString*)macroCommand;

- (NSArray*)macros;

- (NSString*)nameForID:(UInt32)macroID;

- (NSString*)macroTextForKey:(NSString*)key;

/*
 "Swift Flight Form" >>> "Forme de vol rapide"
 "Flight Form" >>> "Forme de vol"
 */
@end
