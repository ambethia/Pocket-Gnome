//
// LogController.h
// Pocket Gnome
//
// Created by benemorius on 12/17/09.
// Copyright 2009 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#define log(...) if([LogController canLog:__VA_ARGS__]) PGLog(@"%@", [LogController log: __VA_ARGS__]);

#define LOG_FUNCTION				"Function"
#define LOG_DEV						"Dev"
#define LOG_DEV1					"Dev1"
#define LOG_DEV2					"Dev2"
#define LOG_TARGET					"Target"
#define LOG_MOVEMENT_CORRECTION		"Movement_Correction"
#define LOG_MOVEMENT				"Movement"
#define LOG_RULE					"Rule"
#define LOG_CONDITION				"Condition"
#define LOG_BEHAVIOR				"Behavior"
#define LOG_LOOT					"Loot"
#define LOG_HEAL					"Heal"
#define LOG_COMBAT					"Combat"
#define LOG_GENERAL					"General"
#define LOG_MACRO					"Macro"
#define LOG_CHAT					"Chat"
#define LOG_ERROR					"Error"
#define LOG_PVP						"PvP"
#define LOG_NODE					"Node"
#define LOG_FISHING					"Fishing"
#define LOG_AFK						"AFK"
#define LOG_MEMORY					"Memory"
#define LOG_BLACKLIST				"Blacklist"
#define LOG_WAYPOINT				"Waypoint"
#define LOG_POSITION				"Position"
#define LOG_ACTION					"Action"
#define LOG_PARTY					"Party"
#define LOG_GHOST					"Ghost"
#define LOG_EVALUATE				"Evaluate"
#define LOG_STARTUP					"Startup"
#define LOG_REGEN					"Regen"
#define LOG_PROCEDURE				"Procedure"
#define LOG_MOUNT					"Mount"
#define LOG_CONTROLLER				"Controller"
#define LOG_STATISTICS				"Statistics"
#define LOG_BINDINGS				"Bindings"
#define LOG_FOLLOW					"Follow"
#define LOG_ITEM					"Item"
#define LOG_PROFILE					"Profile"
#define LOG_FILEMANAGER				"FileManager"

@interface LogController : NSObject {
		
}

+ (BOOL) canLog:(char*)type_s, ...;
+ (NSString*) log:(char*)type_s, ...;

@end