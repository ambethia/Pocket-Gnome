//
//  BlacklistController.h
//  Pocket Gnome
//
//  Created by Josh on 12/13/09.
//  Copyright 2009 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// created a controller for this, as I don't want to implement the exact same versions for Combat and for nodes

@class WoWObject;
@class Unit;
@class MobController;
@class PlayersController;

@interface BlacklistController : NSObject {
	
	IBOutlet MobController		*mobController;
	IBOutlet PlayersController	*playersController;

	NSMutableDictionary *_blacklist;
	NSMutableDictionary *_attemptList;

}

// reasons to be blacklisted!
enum{
	Reason_None					= 0,
	Reason_NotInLoS				= 1,
	Reason_NodeMadeMeFall		= 2,
	Reason_CantReachObject		= 3,
	Reason_NotInCombat			= 4,
	Reason_RecentlyResurrected	= 5,
	Reason_RecentlyHelpedFriend = 6,
	Reason_InvalidTarget		= 7,
	Reason_OutOfRange			= 8,
	Reason_RecentlySkinned		= 9,
	Reason_NodeMadeMeDie		= 10,

};

- (void)blacklistObject:(WoWObject *)obj withReason:(int)reason;
- (void)blacklistObject: (WoWObject*)obj;
- (BOOL)isBlacklisted: (WoWObject*)obj;
- (void)removeAllUnits;
- (void)removeUnit: (Unit*)unit;

// sick of putting more dictionaries in bot controller, will just use this
- (int)attemptsForObject:(WoWObject*)obj;
- (void)incrementAttemptForObject:(WoWObject*)obj;
- (void)clearAttemptsForObject:(WoWObject*)obj;
- (void)clearAttempts;

- (void)clearAll;

@end
