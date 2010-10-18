//
//  CombatController.h
//  Pocket Gnome
//
//  Created by Josh on 12/19/09.
//  Copyright 2009 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Controller;
@class ChatController;
@class MobController;
@class BotController;
@class MovementController;
@class PlayerDataController;
@class PlayersController;
@class BlacklistController;
@class AuraController;
@class MacroController;
@class BindingsController;

@class Position;
@class Unit;

#define UnitDiedNotification		@"UnitDiedNotification"
#define UnitTappedNotification		@"UnitTappedNotification"
#define UnitEnteredCombat			@"UnitEnteredCombat"

@interface CombatController : NSObject {
    IBOutlet Controller				*controller;
    IBOutlet PlayerDataController	*playerData;
	IBOutlet PlayersController		*playersController;
    IBOutlet BotController			*botController;
    IBOutlet MobController			*mobController;
    IBOutlet ChatController			*chatController;
    IBOutlet MovementController		*movementController;
	IBOutlet BlacklistController	*blacklistController;
	IBOutlet AuraController			*auraController;
	IBOutlet MacroController		*macroController;
	IBOutlet BindingsController		*bindingsController;
	
	// three different types of units to be tracked at all times
	Unit *_attackUnit;
	Unit *_friendUnit;
	Unit *_addUnit;
	Unit *_castingUnit;		// the unit we're casting on!  This will be one of the above 3!
	
	IBOutlet NSPanel *combatPanel;
	IBOutlet NSTableView *combatTable;
	
	BOOL _inCombat;
	BOOL _hasStepped;
	
	NSDate *_enteredCombat;
	
	NSMutableArray *_unitsAttackingMe;
	NSMutableArray *_unitsAllCombat;		// meant for the display table ONLY!
	NSMutableArray *_unitsDied;
	NSMutableArray *_unitsMonitoring;
	
	NSMutableDictionary *_unitLeftCombatCount;
	NSMutableDictionary *_unitLeftCombatTargetCount;
}

@property BOOL inCombat;
@property (readonly, retain) Unit *attackUnit;
@property (readonly, retain) Unit *castingUnit;
@property (readonly, retain) Unit *addUnit;
@property (readonly, retain) NSMutableArray *unitsAttackingMe;
@property (readonly, retain) NSMutableArray *unitsDied;
@property (readonly, retain) NSMutableArray *unitsMonitoring;

// weighted units we're in combat with
- (NSArray*)combatList;

// OUTPUT: PerformProcedureWithState - used to determine which unit to act on!
//	Also used for Proximity Count check
- (NSArray*)validUnitsWithFriendly:(BOOL)includeFriendly onlyHostilesInCombat:(BOOL)onlyHostilesInCombat;

// OUTPUT: return all adds
- (NSArray*)allAdds;

// OUTPUT: find a unit to attack, or heal
-(Unit*)findUnitWithFriendly:(BOOL)includeFriendly onlyHostilesInCombat:(BOOL)onlyHostilesInCombat;
-(Unit*)findUnitWithFriendlyToEngage:(BOOL)includeFriendly onlyHostilesInCombat:(BOOL)onlyHostilesInCombat;

// INPUT: from CombatProcedure within PerformProcedureWithState
- (void)stayWithUnit:(Unit*)unit withType:(int)type;

// INPUT: called when combat should be over
- (void)cancelCombatAction;
- (void)cancelAllCombat;

// INPUT: called when we start/stop the bot
- (void)resetAllCombat;
- (void)resetUnitsDied;

// INPUT: from PlayerDataController when a user enters combat
- (void)doCombatSearch;

- (NSArray*)friendlyUnits;
- (NSArray*)friendlyCorpses;

// OUPUT: could also be using [playerController isInCombat]
- (BOOL)combatEnabled;

// OUPUT: returns the weight of a unit
- (int)weight: (Unit*)unit;
- (int)weight: (Unit*)unit PlayerPosition:(Position*)playerPosition;

// OUTPUT: valid targets in range based on combat profile
- (NSArray*)enemiesWithinRange:(float)range;

// UI
- (void)showCombatPanel;
- (void)updateCombatTable;

- (NSString*)unitHealthBar: (Unit*)unit;

@end
