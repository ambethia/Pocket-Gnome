//
//  CombatController.m
//  Pocket Gnome
//
//  Created by Josh on 12/19/09.
//  Copyright 2009 Savory Software, LLC. All rights reserved.
//

#import "CombatController.h"
#import "PlayersController.h"
#import "AuraController.h"
#import "MobController.h"
#import "BotController.h"
#import "PlayerDataController.h"
#import "BlacklistController.h"
#import "MovementController.h"
#import "Controller.h"
#import "AuraController.h"
#import "MacroController.h"

#import "Unit.h"
#import "Rule.h"
#import "CombatProfile.h"
#import "Behavior.h"

#import "ImageAndTextCell.h"

@interface CombatController ()
@property (readwrite, retain) Unit *attackUnit;
@property (readwrite, retain) Unit *castingUnit;
@property (readwrite, retain) Unit *addUnit;

@end

@interface CombatController (Internal)
- (NSArray*)friendlyUnits;
- (NSRange)levelRange;
- (int)weight: (Unit*)unit PlayerPosition:(Position*)playerPosition;
- (void)stayWithUnit;
- (NSArray*)combatListValidated;
- (void)updateCombatTable;
- (void)monitorUnit: (Unit*)unit;
@end

@implementation CombatController

- (id) init{
    self = [super init];
    if (self == nil) return self;

	_attackUnit		= nil;
	_friendUnit		= nil;
	_addUnit		= nil;
	_castingUnit	= nil;

	_enteredCombat = nil;

	_inCombat = NO;
	_hasStepped = NO;

	_unitsAttackingMe = [[NSMutableArray array] retain];
	_unitsAllCombat = [[NSMutableArray array] retain];
	_unitLeftCombatCount = [[NSMutableDictionary dictionary] retain];
	_unitLeftCombatTargetCount = [[NSMutableDictionary dictionary] retain];
	_unitsDied = [[NSMutableArray array] retain];
	_unitsMonitoring = [[NSMutableArray array] retain];

	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(playerHasDied:) name: PlayerHasDiedNotification object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(playerEnteringCombat:) name: PlayerEnteringCombatNotification object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(playerLeavingCombat:) name: PlayerLeavingCombatNotification object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(invalidTarget:) name: ErrorInvalidTarget object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(haveNoTarget:) name: ErrorHaveNoTarget object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(targetOutOfRange:) name: ErrorTargetOutOfRange object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(targetNotInLOS:) name: ErrorTargetNotInLOS object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(targetNotInFront:) name: ErrorTargetNotInFront object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(morePowerfullSpellActive:) name: ErrorMorePowerfullSpellActive object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(unitDied:) name: UnitDiedNotification object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(unitTapped:) name: UnitTappedNotification object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(cantDoThatWhileStunned:) name: ErrorCantDoThatWhileStunned object: nil];

    return self;
}

- (void) dealloc
{
	[_unitsAttackingMe release];
	[_unitsAllCombat release];
	[_unitLeftCombatCount release];
	[_unitLeftCombatTargetCount release];
	[_unitsDied release];
	[_unitsMonitoring release];

	[_castingUnit release];
	[_attackUnit release];
	[_friendUnit release];
	[_addUnit release];
	
    [super dealloc];
}

@synthesize attackUnit = _attackUnit;
@synthesize castingUnit = _castingUnit;
@synthesize addUnit = _addUnit;
@synthesize inCombat = _inCombat;
@synthesize unitsAttackingMe = _unitsAttackingMe;
@synthesize unitsDied = _unitsDied;
@synthesize unitsMonitoring = _unitsMonitoring;

#pragma mark -

int DistFromPositionCompare(id <UnitPosition> unit1, id <UnitPosition> unit2, void *context) {
    
    //PlayerDataController *playerData = (PlayerDataController*)context; [playerData position];
    Position *position = (Position*)context; 
	
    float d1 = [position distanceToPosition: [unit1 position]];
    float d2 = [position distanceToPosition: [unit2 position]];
    if (d1 < d2)
        return NSOrderedAscending;
    else if (d1 > d2)
        return NSOrderedDescending;
    else
        return NSOrderedSame;
}

int WeightCompare(id unit1, id unit2, void *context) {
	
	NSDictionary *dict = (NSDictionary*)context;

	NSNumber *w1 = [dict objectForKey:[NSNumber numberWithLongLong:[unit1 cachedGUID]]];
	NSNumber *w2 = [dict objectForKey:[NSNumber numberWithLongLong:[unit2 cachedGUID]]];
	
	int weight1=0, weight2=0;
	
	if ( w1 )
		weight1 = [w1 intValue];
	if ( w2 )
		weight2 = [w2 intValue];
	
	log(LOG_DEV, @"WeightCompare: (%@)%d vs. (%@)%d", unit1, weight1, unit2, weight2);

    if (weight1 > weight2)
        return NSOrderedAscending;
    else if (weight1 < weight2)
        return NSOrderedDescending;
    else
        return NSOrderedSame;
	
	return NSOrderedSame;
}

#pragma mark [Input] Notifications

- (void)playerEnteringCombat: (NSNotification*)notification {
	if ( !botController.isBotting ) return;

    log(LOG_DEV, @"------ Player Entering Combat ------");
	
	_inCombat = YES;
}

- (void)playerLeavingCombat: (NSNotification*)notification {
	if ( !botController.isBotting ) return;

    log(LOG_DEV, @"------ Player Leaving Combat ------");

	_inCombat = NO;

//	[self resetAllCombat]; // It's possible that we've left combat as we're casting on a new target so this is bad.
}

- (void)playerHasDied: (NSNotification*)notification {
	if ( !botController.isBotting ) return;

	log(LOG_COMBAT, @"Player has died!");

	[self resetAllCombat];
	_inCombat = NO;
}

- (void)unitDied: (NSNotification*)notification {
	if ( !botController.isBotting ) return;

	Unit *unit = [notification object];
	log(LOG_DEV, @"%@ died, removing from combat list!", unit);

	BOOL wasCastingUnit = NO;
	if ( _castingUnit && [unit cachedGUID] == [_castingUnit cachedGUID] ) wasCastingUnit = YES;
	
	// Kill the monitoring if called from else where
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(monitorUnit:) object: unit];

	if ( [_unitsMonitoring containsObject: unit] )	[_unitsMonitoring removeObject: unit];

	if ( wasCastingUnit ) {
		[_castingUnit release];
		_castingUnit = nil;

		// Casting unit dead, reset!
		[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(stayWithUnit) object: nil];
		[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(monitorUnit:) object: unit];
		[botController cancelCurrentProcedure];
		[botController cancelCurrentEvaluation];
		[movementController resetMovementState];
	}

	// If this was our attacking unit
	if ( _attackUnit && [unit cachedGUID] == [_attackUnit cachedGUID] ) {
		[_attackUnit release];
		_attackUnit = nil;
	}

	// If this was our friend unit
	if ( _friendUnit && [unit cachedGUID] == [_friendUnit cachedGUID] ) {
		[_friendUnit release];
		_friendUnit = nil;
	}

	// If this was our add unit
	if ( _addUnit && [unit cachedGUID] == [_addUnit cachedGUID] ) {
		// Make sure our add is on the lists
		if ( ![_unitsAttackingMe containsObject: unit] ) [_unitsAttackingMe addObject: unit];
		if ( ![_unitsAllCombat containsObject: unit] ) [_unitsAllCombat addObject: unit];
		[_addUnit release]; _addUnit = nil;
	}

	if ( [_unitsAllCombat containsObject: unit] )	[_unitsAllCombat removeObject: unit];
	if ( [_unitsAttackingMe containsObject: unit] )	[_unitsAttackingMe removeObject: unit];

	// Add this to our internal list
	[_unitsDied addObject: unit];

	if ( _inCombat && [_unitsAttackingMe count] == 0 ) _inCombat = NO;

	// If this was our casting unit
	if ( wasCastingUnit ) [botController evaluateSituation];

}

// invalid target
- (void)invalidTarget: (NSNotification*)notification {
	if ( !botController.isBotting ) return;

	Unit *unit = [notification object];
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(monitorUnit:) object: unit];
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(stayWithUnit) object: nil];

//	log(LOG_COMBAT, @"%@ %@ is an Invalid Target, blacklisting.", [self unitHealthBar: unit], unit);
//	[blacklistController blacklistObject: unit withReason:Reason_InvalidTarget];

	[self cancelAllCombat];
}

// have no target
- (void)haveNoTarget: (NSNotification*)notification {
	if ( !botController.isBotting ) return;

	Unit *unit = [notification object];
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(monitorUnit:) object: unit];
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(stayWithUnit) object: nil];

	log(LOG_COMBAT, @"%@ %@ gave error You Have No Target!", [self unitHealthBar: unit], unit);
//	[blacklistController blacklistObject: unit withReason:Reason_InvalidTarget];

//	log(LOG_COMBAT, @"%@ %@ is an Invalid Target, blacklisting.", [self unitHealthBar: unit], unit);
//	[blacklistController blacklistObject: unit withReason:Reason_InvalidTarget];
	
	[self cancelAllCombat];
}

// not in LoS
- (void)targetNotInLOS: (NSNotification*)notification {
	if ( !botController.isBotting ) return;

	Unit *unit = [notification object];
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(monitorUnit:) object: unit];
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(stayWithUnit) object: nil];

	log(LOG_COMBAT, @"%@ %@ is not in LoS, blacklisting.", [self unitHealthBar: unit], unit);
	[blacklistController blacklistObject:unit withReason:Reason_NotInLoS];

	[self cancelAllCombat];

}

// target is out of range
- (void)targetOutOfRange: (NSNotification*)notification {
	if ( !botController.isBotting ) return;

	Unit *unit = [notification object];

	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(monitorUnit:) object: unit];
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(stayWithUnit) object: nil];

	[botController cancelCurrentProcedure];
	[botController cancelCurrentEvaluation];

	// if we can correct this error
	if ( ![playerData isFriendlyWithFaction: [unit factionTemplate]] && [unit isInCombat] && [unit isTargetingMe] && [movementController checkUnitOutOfRange: unit] ) {
		[botController actOnUnit: unit];
		return;
	}

	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(stayWithUnit) object: nil];
	[self cancelAllCombat];

	log(LOG_COMBAT, @"%@ %@ is out of range, disengaging.", [self unitHealthBar: unit], unit);
	[blacklistController blacklistObject:unit withReason:Reason_OutOfRange];
	[botController evaluateSituation];
}

- (void)morePowerfullSpellActive: (NSNotification*)notification {
	if ( !botController.isBotting ) return;

	Unit *unit = [notification object];
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(monitorUnit:) object: unit];
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(stayWithUnit) object: nil];

	[blacklistController blacklistObject: unit withReason:Reason_RecentlyHelpedFriend];
	[self cancelAllCombat];
}

- (void)cantDoThatWhileStunned: (NSNotification*)notification {
	if ( !botController.isBotting ) return;

	Unit *unit = [notification object];
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(monitorUnit:) object: unit];
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(stayWithUnit) object: nil];

	[self cancelAllCombat];
}

- (void)targetNotInFront: (NSNotification*)notification {
	if ( !botController.isBotting ) return;
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(stayWithUnit) object: nil];

	Unit *unit = [notification object];

	log(LOG_COMBAT, @"%@ %@ is not in front, adjusting.", [self unitHealthBar: unit] , unit);

	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(monitorUnit:) object: unit];
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(stayWithUnit) object: nil];

	[botController cancelCurrentProcedure];
	[botController cancelCurrentEvaluation];
	if ([movementController isActive] ) [movementController resetMovementState];

	[movementController turnTowardObject:unit];
	[movementController establishPlayerPosition];
	[botController actOnUnit: unit];

}

- (void)unitTapped: (NSNotification*)notification {
	if ( !botController.isBotting ) return;
	if ( botController.pvpIsInBG ) return;

	Unit *unit = [notification object];

	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(monitorUnit:) object: unit];
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(stayWithUnit) object: nil];

	log(LOG_COMBAT, @"%@ %@ tapped by another player, disengaging!", [self unitHealthBar: unit] ,unit);

	if ( unit == _castingUnit ) {
		[botController cancelCurrentProcedure];
		[self cancelAllCombat];
		[_unitsAllCombat removeObject: unit];
		[_unitsAttackingMe removeObject: unit];
		[botController evaluateSituation];
	}
}

#pragma mark Public

// list of units we're in combat with, XXX NO friendlies XXX
// This is now updated to include units attacking party members
- (NSArray*)combatList {

	// Looks like this is called from the PlayerConroller even the bot is off
	if ( !botController.isBotting ) return nil;

	if ( [playerData isDead] || [playerData percentHealth] == 0 ) return nil;

	//log(LOG_FUNCTION, @"combatList");

	// Seems this isn't upating so I'll stick it here for now?
	[self doCombatSearch];

	NSMutableArray *units = [NSMutableArray array];

	if ( [_unitsAttackingMe count] ) [units addObjectsFromArray:_unitsAttackingMe];

	// add the other units if we need to
	if ( _attackUnit!= nil && ![units containsObject:_attackUnit] && ![blacklistController isBlacklisted:_attackUnit] && ![_attackUnit isDead] && ![_unitsDied containsObject: _attackUnit] ) {
		[units addObject:(Unit*)_attackUnit];
		log(LOG_DEV, @"Adding attack unit: %@", _attackUnit);
	}

	// add our add
	if ( _addUnit != nil && ![units containsObject:_addUnit] && ![blacklistController isBlacklisted:_addUnit] && ![_addUnit isDead] && ![_unitsDied containsObject: _addUnit] ) {
		[units addObject:(Unit*)_addUnit];
		log(LOG_COMBAT, @"Adding add unit: %@", _addUnit);
	}

	float attackRange = [botController.theCombatProfile engageRange];
	if ( [botController.theCombatProfile attackRange] > [botController.theCombatProfile engageRange] )
		attackRange = [botController.theCombatProfile attackRange];

	UInt64 playerID;
	Player *player;	
	UInt64 targetID;
	Mob *targetMob;
	Player *targetPlayer;
	
	Position *playerPosition = [playerData position];
	float distanceToTarget = 0.0f;

	// Add our pets target
	if ( [botController.theBehavior usePet] && [playerData pet] && ![[playerData pet] isDead] && [[playerData pet] isInCombat] ) {

		targetID = [[playerData pet] targetID];
		if ( targetID > 0x0) {
			log(LOG_DEV, @"Pet has a target.");
			Mob *targetMob = [mobController mobWithGUID:targetID];
			if ( targetMob && ![targetMob isDead] && ![targetMob percentHealth] == 0 && ![_unitsDied containsObject: (Unit*)targetMob] && [targetMob isInCombat] ) {
				[units addObject:targetMob];
				log(LOG_DEV, @"Adding Pet's mob: %@", targetMob);
			} else {
				targetPlayer = [playersController playerWithGUID: targetID];
				if ( targetPlayer && ![targetPlayer isDead] && ![targetPlayer percentHealth] == 0 && ![_unitsDied containsObject: (Unit*)targetPlayer] && [targetPlayer isInCombat] && ![playerData isFriendlyWithFaction: [targetPlayer factionTemplate]] ) {
					log(LOG_DEV, @"Adding Pet's PvP target: %@", targetPlayer);
					[units addObject: (Unit*)targetPlayer];
				}
			}
		}
	}

	// If we're in party mode we'll add the units our party members are in combat with
	if ( botController.theCombatProfile.partyEnabled ) {

		// Check only party members
		int i;
		for (i=1;i<6;i++) {

			// If there are no more party members
			playerID = [playerData PartyMember: i];
			if ( playerID <= 0x0) break;

			player = [playersController playerWithGUID: playerID];
			if ( !player || ![player isValid] || [player isDead] || [player percentHealth] == 0  || ![player isInCombat] ) continue;

			targetID = [player targetID];

			if ( !targetID || targetID <= 0x0) continue;

			// Try player targets
			targetPlayer = [playersController playerWithGUID: targetID];
			if ( targetPlayer ) {
				if ( ![targetPlayer isValid] || [_unitsDied containsObject: (Unit*)targetPlayer] || [targetPlayer isDead] || [targetPlayer percentHealth] == 0 ) continue;
				if ( [units containsObject: (Unit*)targetPlayer] ) continue;
				if ( ![targetPlayer isInCombat] ) continue;
				if ( [playerData isFriendlyWithFaction: [targetPlayer factionTemplate]] ) continue;
				distanceToTarget = [playerPosition distanceToPosition:[(Unit*)targetPlayer position]];
				if ( distanceToTarget > attackRange ) continue;
				log(LOG_DEV, @"Adding Party members PvP target: %@ for %@", targetPlayer, player);
				[units addObject: (Unit*)targetPlayer];
				targetPlayer = nil;
				continue;
			}

			// Try mob targets
			targetMob = [mobController mobWithGUID: targetID];
			if ( targetMob ) {
				if ( ![targetMob isValid] || [_unitsDied containsObject: (Unit*)targetMob] || [targetMob isDead] || [targetMob percentHealth] == 0 ) continue;
				if ( [units containsObject: targetMob] ) continue;
				if ( ![targetMob isInCombat] ) continue;
				if ( [playerData isFriendlyWithFaction: [targetMob factionTemplate]] ) continue;

				distanceToTarget = [playerPosition distanceToPosition:[targetMob position]];
				if ( distanceToTarget > attackRange ) continue;
				log(LOG_DEV, @"Adding Party mob: %@ for %@", targetMob, player);
				[units addObject: targetMob];
				targetMob = nil;
				continue;
			}
		}

	} else

	// Get the assist players target
	if ( botController.assistUnit && [[botController assistUnit] isValid] && [[botController assistUnit] isInCombat] ) {

		targetID = [[botController assistUnit] targetID];
		if ( targetID > 0x0) {
			log(LOG_DEV, @"Assist has a target.");
			targetMob = [mobController mobWithGUID:targetID];
			if ( targetMob && ![targetMob isDead] && [targetMob percentHealth] != 0 && ![_unitsDied containsObject: (Unit*)targetMob] && [targetMob isInCombat] ) {
				distanceToTarget = [playerPosition distanceToPosition:[targetMob position]];
				if ( distanceToTarget <= attackRange ) {				
					[units addObject:targetMob];
					log(LOG_DEV, @"Adding Assit's mob: %@", targetMob);
				}
			}

			targetPlayer = [playersController playerWithGUID: targetID];
			if ( targetPlayer && ![targetPlayer isDead] && ![_unitsDied containsObject: (Unit*)targetPlayer] && [targetPlayer isInCombat] && ![playerData isFriendlyWithFaction: [targetPlayer factionTemplate]] ) {
				distanceToTarget = [playerPosition distanceToPosition:[(Unit*)targetPlayer position]];
				if ( distanceToTarget <= attackRange ) {				
					log(LOG_DEV, @"Adding Assist's PvP target: %@", player);
					[units addObject: (Unit*)targetPlayer];
				}
			}
		}
	}

	// sort
	NSMutableDictionary *dictOfWeights = [NSMutableDictionary dictionary];
	for ( Unit *unit in units ) {
		[dictOfWeights setObject: [NSNumber numberWithInt:[self weight:unit PlayerPosition:playerPosition]] forKey:[NSNumber numberWithUnsignedLongLong:[unit cachedGUID]]];
	}

	[units sortUsingFunction: WeightCompare context: dictOfWeights];

	//log(LOG_DEV, @"combatList has %d units.", [units count]);
	
	return [[units retain] autorelease];
}

// out of the units that are attacking us, which are valid for us to attack back?
- (NSArray*)combatListValidated{

	NSArray *units = [self combatList];
	NSMutableArray *validUnits = [NSMutableArray array];

	Position *playerPosition = [playerData position];
	float vertOffset = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"BlacklistVerticalOffset"] floatValue];

	// range changes if the unit is friendly or not
//	float distanceToTarget;
//	float attackRange = ( botController.theCombatProfile.attackRange > botController.theCombatProfile.engageRange ) ? botController.theCombatProfile.attackRange : botController.theCombatProfile.engageRange;
//	float range = ([playerData isFriendlyWithFaction: [unit factionTemplate]] ? botController.theCombatProfile.healingRange : attackRange);

	for ( Unit *unit in units ){

		if ( [blacklistController isBlacklisted:unit] ) {
			log(LOG_COMBAT, @"Not adding blacklisted unit to validated combat list: %@", unit);
			continue;
		}

		// ignore dead units
		if ( [unit isDead] || [unit percentHealth] == 0 || [_unitsDied containsObject: unit] ) continue;

		// Ignore not valid units
		if ( ![unit isValid] ) continue;

		// Ignore evading units
		if ( ![unit isPlayer] && [unit isEvading] ) continue;

		// Ignore if vertical distance is too great
		if ( [[unit position] verticalDistanceToPosition: playerPosition] > vertOffset ) continue;

//		distanceToTarget = [playerPosition distanceToPosition:[(Unit*)unit position]];
		
//		if ( distanceToTarget > range ) continue;

		[validUnits addObject:unit];		
	}	

	// sort
	NSMutableDictionary *dictOfWeights = [NSMutableDictionary dictionary];

	for ( Unit *unit in validUnits )
		[dictOfWeights setObject: [NSNumber numberWithInt:[self weight:unit PlayerPosition:playerPosition]] forKey:[NSNumber numberWithUnsignedLongLong:[unit cachedGUID]]];

	[validUnits sortUsingFunction: WeightCompare context: dictOfWeights];

	log(LOG_DEV, @"combatListValidated has %d units.", [validUnits count]);
	
	if ( _inCombat && [validUnits count] == 0 ) _inCombat = NO;

	return [[validUnits retain] autorelease];
}


- (BOOL)combatEnabled {
	return botController.theCombatProfile.combatEnabled;
}

// from performProcedureWithState 
// this will keep the unit targeted!
- (void)stayWithUnit:(Unit*)unit withType:(int)type {
	// Stop movement on our current castingUnit if need be
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(stayWithUnit) object: nil];

	if ( !unit || unit == nil ) return;

	if ( [unit isDead] ) return;

	Unit *oldTarget = [_castingUnit retain];

	[_castingUnit release]; _castingUnit = nil;
	_castingUnit = [unit retain];

	// enemy
	if ( type == TargetEnemy ){
		_attackUnit = [unit retain];
	}

	// add
	else if ( type == TargetAdd || type == TargetPat ) {
		_addUnit = [unit retain];
	}

	// friendly
	else if ( type == TargetFriend || type == TargetFriendlies || type == TargetPet ) {
		_friendUnit = [unit retain];
	}

	// otherwise lets clear our target (we're either targeting no one or ourself)
	else {
		[_castingUnit release];
		_castingUnit = nil;
	}

	// If we don't need to monitor or stay with this unit
	if ( type == TargetFriend || type == TargetFriendlies || type == TargetPet || type == TargetSelf || type == TargetNone || [playerData isFriendlyWithFaction: [unit factionTemplate]] ) return;

	// remember when we started w/this unit
	[_enteredCombat release]; _enteredCombat = [[NSDate date] retain];
	if ( !self.inCombat ) _inCombat = YES;

	// lets face our new unit!
//	if ( unit != oldTarget ) {
//		log(LOG_DEV, @"Facing new target! %@", unit);
//		[movementController turnTowardObject:unit];
//		[movementController establishPlayerPosition];	// already in botController 
//		[movementController correctDirectionByTurning];
//	}

	// stop monitoring our "old" unit - we ONLY want to do this in PvP as we'd like to know when the unit dies!
	if ( oldTarget && ( botController.pvpIsInBG || ![playerData isFriendlyWithFaction: [unit factionTemplate]] ) ) {
		[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(monitorUnit:) object: oldTarget];
		[oldTarget release];
	}

	log(LOG_DEV, @"Now staying with %@", unit);
	if ( ![_unitsMonitoring containsObject: unit] ) {
		[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(monitorUnit:) object: unit];
		[self monitorUnit: unit];
	}

	[self stayWithUnit];
}

- (void)stayWithUnit {
	// cancel other requests
	[NSObject cancelPreviousPerformRequestsWithTarget: self];

	log(LOG_DEV, @"Staying with %@ in procedure %@", _castingUnit, [botController procedureInProgress]);

	if ( _castingUnit == nil ) {
		log(LOG_COMBAT, @"No longer staying w/the unit");
		return;
	}

	// dead
	if ( [_castingUnit isDead] || [_castingUnit percentHealth] <= 0 ) {
		log(LOG_COMBAT, @"Unit is dead! %@", _castingUnit);
		return;
	}

	// sanity checks
	if ( ![_castingUnit isValid] || [blacklistController isBlacklisted:_castingUnit] ) {
		log(LOG_COMBAT, @"STOP ATTACK: Invalid? (%d) Blacklisted? (%d)", ![_castingUnit isValid], [blacklistController isBlacklisted:_castingUnit]);
		return;
	}

	// sanity checks
	if ( ![_castingUnit isPlayer] && [_castingUnit isEvading] ) {
		log(LOG_COMBAT, @"STOP ATTACK: Evading? (%d)", [_castingUnit isEvading]);
		return;
	}
	
	if ( [playerData isDead] ){
		log(LOG_COMBAT, @"You died, stopping attack.");
		return;
	}

	// no longer in combat procedure
	if ( botController.procedureInProgress != @"CombatProcedure" && botController.procedureInProgress != @"PreCombatProcedure" ) {
		log(LOG_COMBAT, @"No longer in combat procedure, no longer staying with unit");
		return;
	}

	float delay = 0.25f;

	// Let's not interfere if we're already moving
	if ( [movementController isMoving] ) {
		log(LOG_COMBAT, @"We've already moving so stay with unit will not interfere.");
		[self performSelector: @selector(stayWithUnit) withObject: nil afterDelay: delay];
		return;
	}

	BOOL isCasting = [playerData isCasting];

	// check player facing vs. unit position
	Position *playerPosition = [playerData position];
	float playerDirection = [playerData directionFacing];
	float distanceToCastingUnit = [[playerData position] distanceToPosition: [_castingUnit position]];
	float theAngle = [playerPosition angleTo: [_castingUnit position]];

	// compensate for the 2pi --> 0 crossover
	if(fabsf(theAngle - playerDirection) > M_PI) {
		if(theAngle < playerDirection)  theAngle        += (M_PI*2);
		else                            playerDirection += (M_PI*2);
	}

	// find the difference between the angles
	float angleTo = fabsf(theAngle - playerDirection);

	// ensure unit is our target if they feign
	UInt64 unitGUID = [_castingUnit cachedGUID];
	if ( ( [playerData targetID] != unitGUID) && [_castingUnit isFeignDeath] ) [playerData targetGuid:unitGUID];

	if( !isCasting ) {

		// if the difference is more than 90 degrees (pi/2) M_PI_2, reposition
		if( (angleTo > 0.785f) ) {  // changed to be ~45 degrees
			log(LOG_COMBAT, @"%@ is behind us (%.2f). Repositioning.", _castingUnit, angleTo);

			if ( [movementController movementType] == MovementType_CTM && !botController.theBehavior.meleeCombat && distanceToCastingUnit < 3.0f ) 
				if ( [movementController jumpForward] ) log(LOG_COMBAT, @"Lunge and spin.");

			[movementController turnTowardObject: _castingUnit];
			delay = 0.5f;
		}

		// move toward unit?
		if ( botController.theBehavior.meleeCombat ) {
			if ( [playerPosition distanceToPosition: [_castingUnit position]] > 5.0f ) {
				log(LOG_COMBAT, @"[Combat] Moving to %@", _castingUnit);
				if ( [movementController moveToObject:_castingUnit] ) {
//					[self performSelector: @selector(stayWithUnit) withObject: nil afterDelay: delay];
					return;
				}
			}
		}
	} else {

		if( (angleTo > 0.2f) ) {
			log(LOG_DEV, @"[Combat] Unit moving while casting (%.2f). Turning.", angleTo);
			// set player facing while casting
			[movementController turnTowardObject: _castingUnit];
		}
	}

	[self performSelector: @selector(stayWithUnit) withObject: nil afterDelay: delay];
}

- (void)monitorUnit: (Unit*)unit {

	if ( ![_unitsMonitoring containsObject: unit] )	[_unitsMonitoring addObject: unit];

	// invalid unit
	if ( !unit || ![unit isValid] ) {
		log(LOG_COMBAT, @"Unit isn't valid!?? %@", unit);
		return;
	}

	if ( [playerData isDead] ) {
		log(LOG_DEV, @"Player died, stopping monitoring.");
		return;
	}

	if ( !botController.isBotting ) {
		log(LOG_DEV, @"Bot no longer running, stopping monitoring.");
		return;
	}
	
//	if ( !self.inCombat ) {
//		log(LOG_COMBAT, @"%@ %@: player is no longer in combat, canceling monitor.", [self unitHealthBar: unit], unit);
//		return;
//	}

	// unit died, fire off notification
	if ( [unit isDead] || [unit percentHealth] <= 0 ) {
		log(LOG_DEV, @"Firing death notification for unit %@", unit);
		[[NSNotificationCenter defaultCenter] postNotificationName: UnitDiedNotification object: [[unit retain] autorelease]];
		return;
	}

	// unit has ghost aura (so is dead, fire off notification)
	NSArray *auras = [[AuraController sharedController] aurasForUnit: unit idsOnly: YES];
	if ( [auras containsObject: [NSNumber numberWithUnsignedInt: 8326]] || [auras containsObject: [NSNumber numberWithUnsignedInt: 20584]] ){
		log(LOG_COMBAT, @"%@ Firing death notification for player %@", [self unitHealthBar: unit], unit);
		[[NSNotificationCenter defaultCenter] postNotificationName: UnitDiedNotification object: [[unit retain] autorelease]];
		return;
	}

	// Tap check
	if ( !botController.theCombatProfile.partyEnabled && !botController.isPvPing && !botController.pvpIsInBG &&
		[unit isTappedByOther] && [unit targetID] != [[playerData player] cachedGUID] ) {
		
		// Only do this for mobs.
		Mob *mob = [mobController mobWithGUID:[unit cachedGUID]];
		if (mob && [mob isValid]) {
			// Mob has been tapped by another player
			log(LOG_DEV, @"Firing tapped notification for unit %@", unit);
			[[NSNotificationCenter defaultCenter] postNotificationName: UnitTappedNotification object: [[unit retain] autorelease]];
			return;
		}
	}

	// Unit not in combat check
	int leftCombatCount = [[_unitLeftCombatCount objectForKey:[NSNumber numberWithLongLong:[unit cachedGUID]]] intValue];

	if ( ![unit isInCombat] ) {

		float secondsInCombat = leftCombatCount/10;

		log(LOG_DEV, @"%@ %@ not in combat now for %0.2f seconds", [self unitHealthBar: unit], unit, secondsInCombat);
		leftCombatCount++;

		// If it's our target let's do some checks as we should be in combat
		if ( [unit cachedGUID] == [_castingUnit cachedGUID] ) {

			// This is to set timer if the unit actually our target vs being an add
			int leftCombatTargetCount = [[_unitLeftCombatTargetCount objectForKey:[NSNumber numberWithLongLong:[unit cachedGUID]]] intValue];

			secondsInCombat = leftCombatTargetCount/10;

			float combatBlacklistDelay = [[[NSUserDefaults standardUserDefaults] objectForKey: @"BlacklistTriggerNotInCombat"] floatValue];
			//			[[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"BlacklistTriggerNotInCombat"] floatValue];
			
			// not in combat after x seconds we blacklist for the short term, long enough to target something else or move
			if ( secondsInCombat >  combatBlacklistDelay ) {
				_hasStepped = NO;
				log(LOG_COMBAT, @"%@ Unit not in combat after %.2f seconds, blacklisting", [self unitHealthBar: unit], combatBlacklistDelay);
				[blacklistController blacklistObject:unit withReason:Reason_NotInCombat];
				[self cancelAllCombat];
				return;
			}
			
			leftCombatTargetCount++;
			[_unitLeftCombatTargetCount setObject:[NSNumber numberWithInt:leftCombatTargetCount] forKey:[NSNumber numberWithLongLong:[unit cachedGUID]]];
			//			log(LOG_DEV, @"%@ Monitoring %@", [self unitHealthBar: unit], unit);
		}
		
		// Unit is an add or not our primary target
		// after a minute stop monitoring
		if ( secondsInCombat > 60 ){
			_hasStepped = NO;
			log(LOG_COMBAT, @"%@ No longer monitoring %@, didn't enter combat after  %d seconds.", [self unitHealthBar: unit], unit, secondsInCombat);
			
			leftCombatCount = 0;
			[_unitLeftCombatCount setObject:[NSNumber numberWithInt:leftCombatCount] forKey:[NSNumber numberWithLongLong:[unit cachedGUID]]];
			
			return;
		}
		
	} else {
		//		log(LOG_DEV, @"%@ Monitoring %@", [self unitHealthBar: unit], unit);
		leftCombatCount = 0;
	}

	[_unitLeftCombatCount setObject:[NSNumber numberWithInt:leftCombatCount] forKey:[NSNumber numberWithLongLong:[unit cachedGUID]]];
	
	[self performSelector:@selector(monitorUnit:) withObject:unit afterDelay:0.1f];
}

- (void)cancelCombatAction {
	log(LOG_FUNCTION, @"cancelCombatAction");
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(stayWithUnit) object: nil];

	// reset our variables
	[_castingUnit release]; _castingUnit = nil;
	[_attackUnit release]; _attackUnit = nil;
	[_addUnit release]; _addUnit = nil;
	[_friendUnit release];	_friendUnit =  nil;
	
	
	[self performSelector:@selector(doCombatSearch) withObject:nil afterDelay:0.1f];
}

- (void)cancelAllCombat {
	log(LOG_FUNCTION, @"cancelAllCombat");

	// reset our variables
	[_castingUnit release]; _castingUnit = nil;
	[_attackUnit release]; _attackUnit = nil;
	[_addUnit release]; _addUnit = nil;
	[_friendUnit release];	_friendUnit =  nil;

	[_unitLeftCombatCount removeAllObjects];
	[_unitLeftCombatTargetCount removeAllObjects];
}

- (void)resetAllCombat {
	log(LOG_FUNCTION, @"resetAllCombat");
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(monitorUnit:) object: nil];
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(stayWithUnit) object: nil];

	[self cancelAllCombat];
	_inCombat = NO;

}

- (void)resetUnitsDied {
	log(LOG_FUNCTION, @"resetUnitsDied");
	[_unitsDied removeAllObjects];
	log(LOG_DEV, @"unitsDied reset.");
}

// units here will meet all conditions! Combat Profile WILL be checked
- (NSArray*)validUnitsWithFriendly:(BOOL)includeFriendly onlyHostilesInCombat:(BOOL)onlyHostilesInCombat {

	// *************************************************
	//	Find all available units!
	//		Add friendly units
	//		Add Assist unit if we're assisting!
	//		Add hostile/neutral units if we should
	//		Add units attacking us
	// *************************************************

	NSMutableArray *allPotentialUnits = [NSMutableArray array];

	// add friendly units w/in range
	if ( ( botController.theCombatProfile.healingEnabled || includeFriendly ) ) {
		log(LOG_DEV, @"Adding friendlies to the list of valid units");
		[allPotentialUnits addObjectsFromArray:[self friendlyUnits]];
	}

	float attackRange = botController.theCombatProfile.engageRange;
	if ( ( botController.isPvPing || botController.pvpIsInBG ) && botController.theCombatProfile.attackRange > botController.theCombatProfile.engageRange )
		attackRange = botController.theCombatProfile.attackRange;

	UInt64 targetID;
	Mob *targetMob;
	Player *targetPlayer;

	Position *playerPosition = [playerData position];
	float distanceToTarget = 0.0f;

	// Get the assist players target
	if ( botController.theCombatProfile.partyEnabled && botController.assistUnit && [[botController assistUnit] isValid] 
		&& ![[botController assistUnit] isDead] && [[botController assistUnit] percentHealth] != 0 
		&& [[botController assistUnit] isInCombat] ) {

		targetID = [[botController assistUnit] targetID];
		if ( targetID && targetID > 0x0) {
			log(LOG_DEV, @"Assist has a target.");

			// Check for PvP target
			targetPlayer = [playersController playerWithGUID: targetID];
			if ( targetPlayer ) {
				if ( ![targetPlayer isDead] && [targetPlayer percentHealth] != 0 && ![playerData isFriendlyWithFaction: [targetPlayer factionTemplate]] && [targetPlayer isInCombat] ) {
					distanceToTarget = [playerPosition distanceToPosition:[(Unit*)targetPlayer position]];
					if ( distanceToTarget <= attackRange ) {
						log(LOG_DEV, @"Adding my Assist's PvP target to the list of valid units: %@", targetPlayer);
						[allPotentialUnits addObject: (Unit*)targetPlayer];
					}
				}
			} else {
			// Check for mob target
				targetMob = [mobController mobWithGUID:targetID];
				if ( targetMob && ![targetMob isDead] && [targetMob percentHealth] != 0 && [targetMob isInCombat] ) {
						
					distanceToTarget = [playerPosition distanceToPosition:[targetMob position]];
					if ( distanceToTarget <= attackRange ) {
						[allPotentialUnits addObject:targetMob];
						log(LOG_DEV, @"Adding my Assist's target to list of valid units");
					}
				}
			}
		}
	}

	// Get the tanks target
	if ( botController.theCombatProfile.partyEnabled && botController.tankUnit && [[botController tankUnit] isValid] 
		&& ![[botController tankUnit] isDead] && [[botController tankUnit] percentHealth] != 0 
		&& [[botController tankUnit] isInCombat] ) {

		targetID = [[botController tankUnit] targetID];
		if ( targetID && targetID > 0x0) {
			log(LOG_DEV, @"Tank has a target.");
			
			// Check for PvP target
			targetPlayer = [playersController playerWithGUID: targetID];
			if ( targetPlayer) {
				if ( ![targetPlayer isDead] && [targetPlayer percentHealth] != 0 && ![playerData isFriendlyWithFaction: [targetPlayer factionTemplate]] && [targetPlayer isInCombat] ) {
					distanceToTarget = [playerPosition distanceToPosition:[(Unit*)targetPlayer position]];
					if ( distanceToTarget <= attackRange ) {
						log(LOG_DEV, @"Adding Tank's PvP target to the list of valid units: %@", targetPlayer);
						[allPotentialUnits addObject: (Unit*)targetPlayer];
					}
				}
			} else {
				targetMob = [mobController mobWithGUID:targetID];
				if ( targetMob && ![targetMob isDead] && [targetMob percentHealth] != 0 && [targetMob isInCombat] ) {
					
					distanceToTarget = [playerPosition distanceToPosition:[targetMob position]];
					if ( distanceToTarget <= attackRange ) {
						[allPotentialUnits addObject:targetMob];
						log(LOG_DEV, @"Adding Tank's target to list of valid units");
					}
				}
			}
		}
	}

	// Get the leaders target
	if ( botController.theCombatProfile.followEnabled && botController.followUnit && [[botController followUnit] isValid] 
		&& ![[botController followUnit] isDead] && [[botController followUnit] percentHealth] != 0 
		&& [[botController followUnit] isInCombat] ) {
		
		targetID = [[botController followUnit] targetID];
		if ( targetID && targetID > 0x0) {
			log(LOG_DEV, @"Leader has a target.");

			// Check for PvP target
			targetPlayer = [playersController playerWithGUID: targetID];
			if ( targetPlayer) {
				if ( ![targetPlayer isDead] && [targetPlayer percentHealth] != 0 && ![playerData isFriendlyWithFaction: [targetPlayer factionTemplate]] && [targetPlayer isInCombat] ) {
					distanceToTarget = [playerPosition distanceToPosition:[(Unit*)targetPlayer position]];
					if ( distanceToTarget <= attackRange ) {
						log(LOG_DEV, @"Adding Leaders's PvP target to the list of valid units: %@", targetPlayer);
						[allPotentialUnits addObject: (Unit*)targetPlayer];
					}
				}
			} else {
				targetMob = [mobController mobWithGUID:targetID];
				if ( targetMob && ![targetMob isDead] && [targetMob percentHealth] != 0 && [targetMob isInCombat] ) {
					
					distanceToTarget = [playerPosition distanceToPosition:[targetMob position]];
					if ( distanceToTarget <= attackRange ) {
						[allPotentialUnits addObject:targetMob];
						log(LOG_DEV, @"Adding Leader's target to list of valid units");
					}
				}
			}
		}
	}

	// add new units w/in range if we're not on assist
	if ( botController.theCombatProfile.combatEnabled && !botController.theCombatProfile.onlyRespond && !onlyHostilesInCombat ) {
		log(LOG_DEV, @"Adding ALL available combat units");

		[allPotentialUnits addObjectsFromArray:[self enemiesWithinRange:attackRange]];
	}

	// remove units attacking us from the list
	if ( [_unitsAttackingMe count] ) [allPotentialUnits removeObjectsInArray:_unitsAttackingMe];

	// add combat units that have been validated! (includes attack unit + add)
	NSArray *inCombatUnits = [self combatListValidated];
	if ( botController.theCombatProfile.combatEnabled && [inCombatUnits count] ) {
		log(LOG_DEV, @"Adding %d validated in combat units to list", [inCombatUnits count]);
		for ( Unit *unit in inCombatUnits ) if ( ![allPotentialUnits containsObject:unit] ) [allPotentialUnits addObject:unit];
	}

	log(LOG_DEV, @"Found %d potential units to validate", [allPotentialUnits count]);

	// *************************************************
	//	Validate all potential units - check for:
	//		Blacklisted
	//		Dead, evading, invalid
	//		Vertical distance
	//		Distance to target
	//		Ghost
	// *************************************************

	NSMutableArray *validUnits = [NSMutableArray array];
	
	if ( [allPotentialUnits count] ){
		float range = 0.0f;
		BOOL isFriendly = NO;

		for ( Unit *unit in allPotentialUnits ){

			if ( [blacklistController isBlacklisted:unit] ) {
				log(LOG_DEV, @":Ignoring blacklisted unit: %@", unit);
				continue;
			}

			if ( [unit isDead] || ![unit isValid] ) continue;

			if ( ![unit isPlayer] && [unit isEvading] ) continue;

			if ( [playerData isFriendlyWithFaction: [unit factionTemplate]] ) isFriendly = YES;
				else isFriendly = NO;

			// range changes if the unit is friendly or not
			distanceToTarget = [playerPosition distanceToPosition:[unit position]];
			range = ( isFriendly ? botController.theCombatProfile.healingRange : botController.theCombatProfile.attackRange);
			if ( distanceToTarget > range ) continue;

			// player: make sure they're not a ghost
			if ( [unit isPlayer] ) {
				NSArray *auras = [auraController aurasForUnit: unit idsOnly: YES];
				if ( [auras containsObject: [NSNumber numberWithUnsignedInt: 8326]] || [auras containsObject: [NSNumber numberWithUnsignedInt: 20584]] ) {
					continue;
				}
			}

			[validUnits addObject: unit];
		}
	}

	if ([validUnits count]) log(LOG_DEV, @"Found %d valid units", [validUnits count]);
	// sort
	NSMutableDictionary *dictOfWeights = [NSMutableDictionary dictionary];
	for ( Unit *unit in validUnits ) {
		[dictOfWeights setObject: [NSNumber numberWithInt:[self weight:unit PlayerPosition:playerPosition]] forKey:[NSNumber numberWithUnsignedLongLong:[unit cachedGUID]]];
	}

	[validUnits sortUsingFunction: WeightCompare context: dictOfWeights];
	return [[validUnits retain] autorelease];
}

// find a unit to attack, CC, or heal
- (Unit*)findUnitWithFriendly:(BOOL)includeFriendly onlyHostilesInCombat:(BOOL)onlyHostilesInCombat {

	log(LOG_FUNCTION, @"findCombatTarget called");

	// flying check?
	if ( botController.theCombatProfile.ignoreFlying ) if ( ![playerData isOnGround] ) return nil;

	// no combat or healing?
	if ( !botController.theCombatProfile.healingEnabled && !botController.theCombatProfile.combatEnabled ) return nil;

	NSArray *validUnits = [NSArray arrayWithArray:[self validUnitsWithFriendly:includeFriendly onlyHostilesInCombat:onlyHostilesInCombat]];

	if ( ![validUnits count] ) return nil;

	// Some weights can be pretty low so let's make sure we don't fail if comparing low weights

	for ( Unit *unit in validUnits ) {

		// Let's make sure we can even act on this unit before we consider it
		if ( ![botController combatProcedureValidForUnit:unit] ) continue;

		log(LOG_DEV, @"Best unit %@ found.", unit);
		return unit;
	}

	return nil;
}

// find a unit to attack, CC, or heal (this one is for engage range only... combat start vs combat continuation)
- (Unit*)findUnitWithFriendlyToEngage:(BOOL)includeFriendly onlyHostilesInCombat:(BOOL)onlyHostilesInCombat {
	
	log(LOG_FUNCTION, @"findCombatTarget called");
	
	// flying check?
	if ( botController.theCombatProfile.ignoreFlying ) if ( ![playerData isOnGround] ) return nil;
	
	// no combat or healing?
	if ( !botController.theCombatProfile.healingEnabled && !botController.theCombatProfile.combatEnabled ) return nil;
	
	NSArray *validUnits = [NSArray arrayWithArray:[self validUnitsWithFriendly:includeFriendly onlyHostilesInCombat:onlyHostilesInCombat]];
	
	if ( ![validUnits count] ) return nil;

	Position *playerPosition = [playerData position];
	float vertOffset = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"BlacklistVerticalOffset"] floatValue];

	for ( Unit *unit in validUnits ) {

		// Make sure it's within our Engage range
		if ( ![playerData isFriendlyWithFaction: [unit factionTemplate]] || !botController.theCombatProfile.healingEnabled ) {
			if ( [playerPosition distanceToPosition: [unit position]] > botController.theCombatProfile.engageRange ) continue;
		} else {
			if ( [playerPosition distanceToPosition: [unit position]] > botController.theCombatProfile.healingRange ) continue;
		}

		if ( [[unit position] verticalDistanceToPosition: playerPosition] > vertOffset ) continue;

		// Let's make sure we can even act on this unit before we consider it
		if ( ![botController combatProcedureValidForUnit:unit] ) continue;

		log(LOG_DEV, @"Best unit %@ found.", unit);
		return unit;
	}

	return nil;
}

- (NSArray*)allAdds {	
	NSMutableArray *allAdds = [NSMutableArray array];
	
	// loop through units that are attacking us!
	for ( Unit *unit in _unitsAttackingMe ) if ( unit != _attackUnit && ![unit isDead] && [unit percentHealth] != 0 ) [allAdds addObject:unit];
	
	return [[allAdds retain] autorelease];
}

// so, in a perfect world
// -) players before pets
// -) low health targets before high health targets
// -) closer before farther
// everything needs to be in combatProfile range

// assign 'weights' to each target based on current conditions/settings
// highest weight unit is our best target

// current target? +25
// player? +100 pet? +25
// hostile? +100, neutral? +100
// health: +(100-percentHealth)
// distance: 100*(attackRange - distance)/attackRange

#define SilverwingFlagSpellID	23335
#define WarsongFlagSpellID		23333
#define NetherstormFlagSpellID	34976

- (int)weight: (Unit*)unit PlayerPosition:(Position*)playerPosition {

	float attackRange = (botController.theCombatProfile.engageRange > botController.theCombatProfile.attackRange) ? botController.theCombatProfile.engageRange : botController.theCombatProfile.attackRange;
//	float healingRange = ( botController.theCombatProfile.healingRange > attackRange ) ? botController.theCombatProfile.healingRange : attackRange;

	float distanceToTarget = [playerPosition distanceToPosition:[unit position]];

	BOOL isFriendly = [playerData isFriendlyWithFaction: [unit factionTemplate]];

	// begin weight calculation
	int weight = 0;

	// player or pet?
	if ( [unit isPlayer] ) weight += 50;

	if ( [unit isPet] ) {
		// we kill pets!
		if ( botController.theCombatProfile.attackPets ) weight += 25;
			else weight -= 50;
	}

	// health left
	int healthLeft = [unit percentHealth];
	int healthWeight = 100-healthLeft;
	weight += healthWeight;

	// our add?
	if ( unit == _addUnit ) weight -= 25;

	int unitLevel = [unit level];

	// Give higher weight to the flag carrier if in a BG
	if ( botController.pvpIsInBG )
		if( [auraController unit: unit hasAura: SilverwingFlagSpellID] || [auraController unit: unit hasAura: WarsongFlagSpellID] || [auraController unit: unit hasAura: NetherstormFlagSpellID] ) 
			weight +=50;

	// non-friendly checks only
	if ( !isFriendly ) {

		if ( attackRange > 0 ) weight += ( 50 * ((attackRange-distanceToTarget)/attackRange));

		// The lower the enemy level the higher the weight
		int lvlWeight = ((100-unitLevel)/10);
		weight += lvlWeight;
		
		// current target
		if ( [playerData targetID] == [unit cachedGUID] ) weight += 25;

		// Hostile Players
		if ( [unit isPlayer] ) {

			// Assist mode - assists target
			if ( botController.theCombatProfile.partyEnabled && botController.assistUnit && [[botController assistUnit] isValid] ) {
				UInt64 targetGUID = [[botController assistUnit] targetID];
				if ( targetGUID > 0x0) {
					Player *assistsPlayer = [playersController playerWithGUID: targetGUID];
					if ( unit == (Unit*)assistsPlayer ) weight += 50;
				}
			}
			
			// Tanks target
			if ( botController.theCombatProfile.partyEnabled && botController.tankUnit && [[botController tankUnit] isValid] ) {
				UInt64 targetGUID = [[botController tankUnit] targetID];
				if ( targetGUID > 0x0) {
					Player *tanksPlayer = [playersController playerWithGUID: targetGUID];
					if ( unit == (Unit*)tanksPlayer ) weight += 50;
				}
			}
			
			// Leaders target
			if ( botController.theCombatProfile.followEnabled && botController.followUnit && [[botController followUnit] isValid] ) {
				UInt64 targetGUID = [[botController followUnit] targetID];
				if ( targetGUID > 0x0) {
					Player *leadersPlayer = [playersController playerWithGUID: targetGUID];
					if ( unit == (Unit*)leadersPlayer ) weight += 50;
				}
			}

		} else {
		// Mobs

			// Assist mode - assists target
			if ( botController.theCombatProfile.partyEnabled && botController.assistUnit && [[botController assistUnit] isValid] ) {
				UInt64 targetGUID = [[botController assistUnit] targetID];
				if ( targetGUID > 0x0) {
					Mob *assistMob = [mobController mobWithGUID:targetGUID];
					if ( unit == assistMob ) weight += 50;
				}
			}

			// Tanks target
			if ( botController.theCombatProfile.partyEnabled && botController.tankUnit && [[botController tankUnit] isValid] ) {
				UInt64 targetGUID = [[botController tankUnit] targetID];
				if ( targetGUID > 0x0) {
					Mob *tankMob = [mobController mobWithGUID:targetGUID];
					if ( unit == tankMob ) weight += 50;	// Still less than the assist just in case
				}
			}

			// Leaders target
			if ( botController.theCombatProfile.followEnabled && botController.followUnit && [[botController followUnit] isValid] ) {
				UInt64 targetGUID = [[botController followUnit] targetID];
				if ( targetGUID > 0x0) {
					Mob *leaderMob = [mobController mobWithGUID:targetGUID];
					if ( unit == leaderMob ) weight += 50;
				}
			}
		}

	} else {	
	// friendly?

		// The higher the friend level the higher the weight
		int lvlWeight = (unitLevel/10);
		weight += lvlWeight;

		// Friends come first when we're not being targeted
		if ( ![_unitsAttackingMe count] ) weight *= 1.5;

		// tank gets a pretty big weight @ all times
		if ( botController.theCombatProfile.partyEnabled && botController.tankUnit && [[botController tankUnit] cachedGUID] == [unit cachedGUID] )
			weight += healthWeight*2;

		// assist gets a pretty big weight @ all times
		if ( botController.theCombatProfile.partyEnabled && botController.assistUnit && [[botController assistUnit] cachedGUID] == [unit cachedGUID] )
			weight += healthWeight*2;

		// leader gets a pretty big weight @ all times
		if ( botController.theCombatProfile.followEnabled && botController.followUnit && [[botController followUnit] cachedGUID] == [unit cachedGUID] )
			weight += healthWeight*2;

	}
	return weight;
}

- (NSString*)unitHealthBar: (Unit*)unit {
	// lets build a log prefix that reflects units health
	NSString *logPrefix = nil;
	UInt32 unitPercentHealth = 0;
	if (unit) {
		unitPercentHealth = [unit percentHealth];
	} else {
		unitPercentHealth = [[playerData player] percentHealth];
	}
	if ( [[playerData player] cachedGUID] == [unit cachedGUID] || !unit) {
		// Ourselves
		if (unitPercentHealth == 100)		logPrefix = @"[OOOOOOOOOOO]";
		else if (unitPercentHealth >= 90)	logPrefix = @"[OOOOOOOOOO ]";
		else if (unitPercentHealth >= 80)	logPrefix = @"[OOOOOOOOO  ]";
		else if (unitPercentHealth >= 70)	logPrefix = @"[OOOOOOOO   ]";
		else if (unitPercentHealth >= 60)	logPrefix = @"[OOOOOOO    ]";
		else if (unitPercentHealth >= 50)	logPrefix = @"[OOOOOO     ]";
		else if (unitPercentHealth >= 40)	logPrefix = @"[OOOOO      ]";
		else if (unitPercentHealth >= 30)	logPrefix = @"[OOOO       ]";
		else if (unitPercentHealth >= 20)	logPrefix = @"[OOO        ]";
		else if (unitPercentHealth >= 10)	logPrefix = @"[OO         ]";
		else if (unitPercentHealth > 0)		logPrefix = @"[O          ]";
		else								logPrefix = @"[           ]";		
	} else
	if ( [botController isTank: (Unit*) unit] ) {
		// Tank
		if (unitPercentHealth == 100)		logPrefix = @"[-----------]";
		else if (unitPercentHealth >= 90)	logPrefix = @"[---------- ]";
		else if (unitPercentHealth >= 80)	logPrefix = @"[---------  ]";
		else if (unitPercentHealth >= 70)	logPrefix = @"[--------   ]";
		else if (unitPercentHealth >= 60)	logPrefix = @"[-------    ]";
		else if (unitPercentHealth >= 50)	logPrefix = @"[------     ]";
		else if (unitPercentHealth >= 40)	logPrefix = @"[-----      ]";
		else if (unitPercentHealth >= 30)	logPrefix = @"[----       ]";
		else if (unitPercentHealth >= 20)	logPrefix = @"[---        ]";
		else if (unitPercentHealth >= 10)	logPrefix = @"[--         ]";
		else if (unitPercentHealth > 0)		logPrefix = @"[-          ]";
		else								logPrefix = @"[ TANK DEAD ]";
	} else
	if ([playerData isFriendlyWithFaction: [unit factionTemplate]]) {
		// Friendly
		if (unitPercentHealth == 100)			logPrefix = @"[+++++++++++]";
			else if (unitPercentHealth >= 90)	logPrefix = @"[++++++++++ ]";
			else if (unitPercentHealth >= 80)	logPrefix = @"[+++++++++  ]";
			else if (unitPercentHealth >= 70)	logPrefix = @"[++++++++   ]";
			else if (unitPercentHealth >= 60)	logPrefix = @"[+++++++    ]";
			else if (unitPercentHealth >= 50)	logPrefix = @"[++++++     ]";
			else if (unitPercentHealth >= 40)	logPrefix = @"[+++++      ]";
			else if (unitPercentHealth >= 30)	logPrefix = @"[++++       ]";
			else if (unitPercentHealth >= 20)	logPrefix = @"[+++        ]";
			else if (unitPercentHealth >= 10)	logPrefix = @"[++         ]";
			else if (unitPercentHealth > 0)		logPrefix = @"[+          ]";
			else								logPrefix = @"[           ]";		
	} else {
		// Hostile
		if (unitPercentHealth == 100)			logPrefix = @"[***********]";
			else if (unitPercentHealth >= 90)	logPrefix = @"[********** ]";
			else if (unitPercentHealth >= 80)	logPrefix = @"[*********  ]";
			else if (unitPercentHealth >= 70)	logPrefix = @"[********   ]";
			else if (unitPercentHealth >= 60)	logPrefix = @"[*******    ]";
			else if (unitPercentHealth >= 50)	logPrefix = @"[******     ]";
			else if (unitPercentHealth >= 40)	logPrefix = @"[*****      ]";
			else if (unitPercentHealth >= 30)	logPrefix = @"[****       ]";
			else if (unitPercentHealth >= 20)	logPrefix = @"[***        ]";
			else if (unitPercentHealth >= 10)	logPrefix = @"[**         ]";
			else if (unitPercentHealth > 0)		logPrefix = @"[*          ]";
			else								logPrefix = @"[           ]";
	}
	 return logPrefix;
 }
		 
#pragma mark Enemy

- (int)weight: (Unit*)unit {
	return [self weight:unit PlayerPosition:[playerData position]];
}

// find available hostile targets
- (NSArray*)enemiesWithinRange:(float)range {

    NSMutableArray *targetsWithinRange = [NSMutableArray array];
	NSRange levelRange = [self levelRange];

	 // check for mobs?
	 if ( botController.theCombatProfile.attackNeutralNPCs || botController.theCombatProfile.attackHostileNPCs ) {
		 log(LOG_DEV, @"[Combat] Checking for mobs.");

		 [targetsWithinRange addObjectsFromArray: [mobController mobsWithinDistance: range
																		 levelRange: levelRange
																	   includeElite: !(botController.theCombatProfile.ignoreElite)
																	includeFriendly: NO
																	 includeNeutral: botController.theCombatProfile.attackNeutralNPCs
																	 includeHostile: botController.theCombatProfile.attackHostileNPCs]];
	 }

	 // check for players?
	 if ( botController.theCombatProfile.attackPlayers ) {
		 log(LOG_DEV, @"[Combat] Checking for Players.");
		 [targetsWithinRange addObjectsFromArray: [playersController playersWithinDistance: range
																				levelRange: levelRange
																		   includeFriendly: NO
																			includeNeutral: NO
																			includeHostile: YES]];
	 }

	log(LOG_DEV, @"[Combat] Found %d targets within range: %0.2f", [targetsWithinRange count], range);

	return targetsWithinRange;
}

#pragma mark Friendly

- (BOOL)validFriendlyUnit: (Unit*)unit{

	if ( !unit ) return NO;

	NSArray *auras = [auraController aurasForUnit: unit idsOnly: YES];
	// regular dead - night elf ghost
	if ( [auras containsObject: [NSNumber numberWithUnsignedInt: 8326]] || [auras containsObject: [NSNumber numberWithUnsignedInt: 20584]] )
		return NO;

	// We need to check:
	//	Not dead
	//	Friendly
	//	Could check position + health threshold + if they are moving away!
	if ( [unit isDead] || [unit percentHealth] == 0 ) return NO;

	if ( ![unit isValid] ) return NO;

	if ( ![playerData isFriendlyWithFaction: [unit factionTemplate]] ) {
		log(LOG_DEV, @"validFriendlyUnit: %@ is not Friendly with Faction!", unit);
		return NO;
	}

	if ( !botController.theCombatProfile.attackAnyLevel ) {
		int unitLevel = [unit level];
		if ( unitLevel < botController.theCombatProfile.attackLevelMin ) return NO;
		if ( unitLevel > botController.theCombatProfile.attackLevelMax ) return NO;
	}

	return YES;
}

- (NSArray*)friendlyUnits{

	// get list of all targets
    NSMutableArray *friendliesWithinRange = [NSMutableArray array];
	NSMutableArray *friendliesNotInRange = [NSMutableArray array];
	NSMutableArray *friendlyTargets = [NSMutableArray array];
	
	// If we're in party mode and only supposed to help party members
	if ( botController.theCombatProfile.partyEnabled && botController.theCombatProfile.partyIgnoreOtherFriendlies ) {

		Player *player;
		UInt64 playerID;

		// Check only party members
		int i;
		for (i=1;i<6;i++) {
			
			playerID = [playerData PartyMember: i];
			if ( playerID <= 0x0) break;

			player = [playersController playerWithGUID: playerID];

			if ( ![player isValid] ) continue;

			[friendliesWithinRange addObject: player];
		}

	} else {

		// Check all friendlies
		if ( !botController.waitForPvPQueue ) [friendliesWithinRange addObjectsFromArray: [playersController allPlayers]];

	}

	// Parse the list to remove out of range units
	// if we have some targets
	float range = (botController.theCombatProfile.healingRange > botController.theCombatProfile.attackRange) ? botController.theCombatProfile.healingRange : botController.theCombatProfile.attackRange;
	Position *playerPosition = [playerData position];

    if ( [friendliesWithinRange count] ) 
        for ( Unit *unit in friendliesWithinRange ) 
			if ( [playerPosition distanceToPosition: [unit position]] > range ) [friendliesNotInRange addObject: unit];

	// Remove out of range units before we sort this list in case it's massive
	if ( [friendliesNotInRange count] ) 
		for ( Unit *unit in friendliesNotInRange ) 
			[friendliesWithinRange removeObject: unit];

	// sort by range
    [friendliesWithinRange sortUsingFunction: DistFromPositionCompare context: playerPosition];

	// if we have some targets
    if ( [friendliesWithinRange count] ) {
        for ( Unit *unit in friendliesWithinRange ) {
			// Skip if the target is ourself
			if ( [unit cachedGUID] == [[playerData player] cachedGUID] ) continue;

//			log(LOG_DEV, @"Friendly - Checking %@", unit);
			if ( [self validFriendlyUnit:unit] ) {
				log(LOG_DEV, @"Valid friendly %@", unit);
				[friendlyTargets addObject: unit];
			}
        }
    }

	log(LOG_DEV, @"Total friendlies: %d", [friendlyTargets count]);

	return friendlyTargets;
}

- (NSArray*)friendlyCorpses{
	


	// get list of all targets
    NSMutableArray *friendliesWithinRange = [NSMutableArray array];
	NSMutableArray *friendlyTargets = [NSMutableArray array];

	// If we're in party mode and only supposed to help party members
	if ( botController.theCombatProfile.partyEnabled && botController.theCombatProfile.partyIgnoreOtherFriendlies ) {
		
		Player *player;
		UInt64 playerID;
		
		// Check only party members
		int i;
		for (i=1;i<6;i++) {
			
			playerID = [playerData PartyMember: i];
			if ( playerID <= 0x0) break;

			player = [playersController playerWithGUID: playerID];
			
			if ( ![player isValid] ) continue;

			[friendliesWithinRange addObject: player];
		}
		
	} else {
		// Check all friendlies
		[friendliesWithinRange addObjectsFromArray: [playersController allPlayers]];
	}
	
	// sort by range
    Position *playerPosition = [playerData position];
    [friendliesWithinRange sortUsingFunction: DistFromPositionCompare context: playerPosition];
	
	// if we have some targets
    if ( [friendliesWithinRange count] ) {
        for ( Unit *unit in friendliesWithinRange ) {
//			log(LOG_DEV, @"Friendly Corpse - Checking %@", unit);

			if ( ![unit isDead] || ![playerData isFriendlyWithFaction: [unit factionTemplate]] ) continue;

				log(LOG_DEV, @"Valid friendly corpse.");
				[friendlyTargets addObject: unit];
        }
    }

	log(LOG_DEV, @"Total friendly corpses: %d", [friendlyTargets count]);
	
	return friendlyTargets;
}

#pragma mark Internal

// find all units we are in combat with
- (void)doCombatSearch {

	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: _cmd object: nil];

	if ( !botController.isBotting ) return;

	if ( [[playerData player] isDead] || [[playerData player] percentHealth] == 0 ) {
		log(LOG_DEV, @"Dead, removing all objects!");

		[_unitsAttackingMe removeAllObjects];
		self.attackUnit = nil;
		self.addUnit = nil;
		self.castingUnit = nil;
		_inCombat = NO;
		return;
	}

	// If we're not in combat then lets skip this altogether
	if ( ![[playerData player] isInCombat] ) {

		if ( [_unitsAttackingMe count] ) [_unitsAttackingMe removeAllObjects];
		self.addUnit = nil;
		if ( botController.procedureInProgress != @"CombatProcedure") {
			self.attackUnit = nil;
			self.castingUnit = nil;
			_inCombat = NO;
		}
		return;
	}

	// add all mobs + players
	NSArray *mobs = [mobController allMobs];

	UInt64 playerGUID = [[playerData player] cachedGUID];
	UInt64 unitTarget = 0;
	BOOL playerHasPet = [[playerData player] hasPet];
	UInt64 petGUID;
	if (playerHasPet) petGUID = [[playerData pet] cachedGUID];

	BOOL addMob;
	for ( Mob *mob in mobs ) {
		unitTarget = [mob targetID];
		addMob = YES;

		if ( addMob && ( ![mob isValid] || [_unitsDied containsObject: (Unit*)mob] || [mob isDead] || [mob percentHealth] == 0 ) ) addMob = NO;
		if ( addMob && ![mob isInCombat] ) addMob = NO;
		if ( addMob && ( ![mob isSelectable] || ![mob isAttackable] ) ) addMob = NO;
		if ( addMob && !botController.isPvPing && !botController.pvpIsInBG && !botController.theCombatProfile.partyEnabled && [mob isTappedByOther] ) addMob = NO;
		if ( addMob &&  botController.theCombatProfile.ignoreLevelOne && [mob level] == 1 ) addMob = NO;
		if ( addMob && unitTarget != playerGUID ) {
			if ( playerHasPet ) {
				if ( unitTarget != petGUID ) addMob = NO;
			} else {
				addMob = NO;
			}
		}

		// add mob!
		if ( addMob && ![_unitsAttackingMe containsObject:(Unit*)mob] ) {
			log(LOG_DEV, @"Adding mob %@", mob);
			[_unitsAttackingMe addObject:(Unit*)mob];
			[[NSNotificationCenter defaultCenter] postNotificationName: UnitEnteredCombat object: [[(Unit*)mob retain] autorelease]];
		}

		if ( !addMob && [_unitsAttackingMe containsObject:(Unit*)mob] && ![mob isFleeing] ) {
			log(LOG_DEV, @"Removing mob %@", mob);
			[_unitsAttackingMe removeObject:(Unit*)mob];
		}
	}

	NSArray *players = [playersController allPlayers];
	BOOL addPlayer;
	for ( Player *player in players ) {

		if ( [playerData isFriendlyWithFaction: [player factionTemplate]] ) continue;

		unitTarget = [player targetID];
		addPlayer = YES;

		if ( addPlayer && ( ![player isValid] || [_unitsDied containsObject: (Unit*)player] || [player isDead] || [player percentHealth] == 0 ) ) addPlayer = NO;
		if ( addPlayer && ![player isInCombat] ) addPlayer = NO;
		if ( addPlayer && ( ![player isSelectable] || ![player isAttackable] ) ) addPlayer = NO;
		if ( addPlayer && unitTarget != playerGUID ) {

			if ( playerHasPet ) {
				if ( unitTarget != petGUID ) addPlayer = NO;
			} else {
				addPlayer = NO;
			}
		}

		// add player!
		if ( addPlayer && ![_unitsAttackingMe containsObject:(Unit*)player] ) {
			log(LOG_DEV, @"Adding Player %@", player);
			[_unitsAttackingMe addObject:(Unit*)player];
			[[NSNotificationCenter defaultCenter] postNotificationName: UnitEnteredCombat object: [[(Unit*)player retain] autorelease]];
		}

		if ( !addPlayer && [_unitsAttackingMe containsObject:(Unit*)player] && ![player isFleeing] && ![player isEvading] && ![player isFeignDeath] ) {
			log(LOG_DEV, @"Removing player %@", player);
			[_unitsAttackingMe removeObject:(Unit*)player];
		}
	}

	Position *playerPosition = [playerData position];

	// double check to see if we should remove any!
	NSMutableArray *unitsToRemove = [NSMutableArray array];
	for ( Unit *unit in _unitsAttackingMe ){
		if ( !unit || ![unit isValid] || [unit isDead]  || [unit percentHealth] == 0 || ![unit isInCombat] || ![unit isSelectable] || ![unit isAttackable] ) {
			log(LOG_DEV, @"[Combat] Removing unit: %@", unit);
			[unitsToRemove addObject:unit];
		} else 
		// Just a safety check
		if ( [playerPosition distanceToPosition: [unit position]] > 45.0f ) {
			log(LOG_DEV, @"[Combat] Removing out of range unit: %@", unit);
			[unitsToRemove addObject:unit];
		}
	}

	if ( [unitsToRemove count] ) [_unitsAttackingMe removeObjectsInArray:unitsToRemove];

	log(LOG_DEV, @"doCombatSearch: In combat with %d units", [_unitsAttackingMe count]);

	if ( [_unitsAttackingMe count] ) {
		_inCombat = YES;
	} else {
		self.addUnit = nil;
		if ( botController.procedureInProgress != @"CombatProcedure") {
			self.attackUnit = nil;
			self.castingUnit = nil;
			_inCombat = NO;
		}
	}
}

// this will return the level range of mobs we are attacking!
- (NSRange)levelRange{
	
	// set the level of mobs/players we are attacking!
	NSRange range = NSMakeRange(0, 0);
	
	// any level
	if ( botController.theCombatProfile.attackAnyLevel ){
		range.length = 200;	// in theory this would be 83, but just making it a high value to be safe
		
		// ignore level one?
		if ( botController.theCombatProfile.ignoreLevelOne ){
			range.location = 2;
		}
		else{
			range.location = 1;
		}
	}
	// we have level requirements!
	else{
		range.location = botController.theCombatProfile.attackLevelMin;
		range.length = botController.theCombatProfile.attackLevelMax - botController.theCombatProfile.attackLevelMin;
	}
	
	return range;
}

#pragma mark UI

- (void)showCombatPanel{
	[combatPanel makeKeyAndOrderFront: self];
}

- (void)updateCombatTable{
	
	if ( [combatPanel isVisible] ){

		[_unitsAllCombat removeAllObjects];
		
		NSArray *allUnits = [self validUnitsWithFriendly:YES onlyHostilesInCombat:NO];
		NSMutableArray *allAndSelf = [NSMutableArray array];
		
		if ( [allUnits count] ){
			[allAndSelf addObjectsFromArray:allUnits];
		}
		[allAndSelf addObject:[playerData player]];
		
		Position *playerPosition = [playerData position];
		
		for(Unit *unit in allAndSelf) {
			if( ![unit isValid] )
				continue;
			
			float distance = [playerPosition distanceToPosition: [unit position]];
			unsigned level = [unit level];
			if(level > 100) level = 0;
			int weight = [self weight: unit PlayerPosition:playerPosition];
			
			NSString *name = [unit name];
			if ( (name == nil || [name length] == 0) && ![unit isNPC] ){
				[name release]; name = nil;
				name = [playersController playerNameWithGUID:[unit cachedGUID]];
			}
			
			if ( [unit cachedGUID] == [[playerData player] cachedGUID] ){
				weight = 0;
			}
			
			[_unitsAllCombat addObject: [NSDictionary dictionaryWithObjectsAndKeys: 
										 unit,                                                                @"Player",
										 name,																  @"Name",
										 [NSString stringWithFormat: @"0x%X", [unit lowGUID]],                @"ID",
										 [NSString stringWithFormat: @"%@%@", [unit isPet] ? @"[Pet] " : @"", [Unit stringForClass: [unit unitClass]]],                             @"Class",
										 [Unit stringForRace: [unit race]],                                   @"Race",
										 [NSString stringWithFormat: @"%d%%", [unit percentHealth]],          @"Health",
										 [NSNumber numberWithUnsignedInt: level],                             @"Level",
										 [NSNumber numberWithFloat: distance],                                @"Distance", 
										 [NSNumber numberWithInt:weight],									  @"Weight",
										 nil]];
		}
		
		// Update our combat table!
		[_unitsAllCombat sortUsingDescriptors: [combatTable sortDescriptors]];
		[combatTable reloadData];
	}
	
}

#pragma mark -
#pragma mark TableView Delegate & Datasource

- (void)tableView:(NSTableView *)aTableView sortDescriptorsDidChange:(NSArray *)oldDescriptors {
	[aTableView reloadData];
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView {
	if ( aTableView == combatTable ){
		return [_unitsAllCombat count];
	}
	
	return 0;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
	if ( aTableView == combatTable ){
		if(rowIndex == -1 || rowIndex >= [_unitsAllCombat count]) return nil;
		
		if([[aTableColumn identifier] isEqualToString: @"Distance"])
			return [NSString stringWithFormat: @"%.2f", [[[_unitsAllCombat objectAtIndex: rowIndex] objectForKey: @"Distance"] floatValue]];
		
		if([[aTableColumn identifier] isEqualToString: @"Status"]) {
			NSString *status = [[_unitsAllCombat objectAtIndex: rowIndex] objectForKey: @"Status"];
			if([status isEqualToString: @"1"])  status = @"Combat";
			if([status isEqualToString: @"2"])  status = @"Hostile";
			if([status isEqualToString: @"3"])  status = @"Dead";
			if([status isEqualToString: @"4"])  status = @"Neutral";
			if([status isEqualToString: @"5"])  status = @"Friendly";
			return [NSImage imageNamed: status];
		}
		
		return [[_unitsAllCombat objectAtIndex: rowIndex] objectForKey: [aTableColumn identifier]];
	}
	
	return nil;
}

- (void)tableView: (NSTableView *)aTableView willDisplayCell: (id)aCell forTableColumn: (NSTableColumn *)aTableColumn row: (int)aRowIndex{
	
	if ( aTableView == combatTable ){
		if( aRowIndex == -1 || aRowIndex >= [_unitsAllCombat count]) return;
		
		if ([[aTableColumn identifier] isEqualToString: @"Race"]) {
			[(ImageAndTextCell*)aCell setImage: [[_unitsAllCombat objectAtIndex: aRowIndex] objectForKey: @"RaceIcon"]];
		}
		if ([[aTableColumn identifier] isEqualToString: @"Class"]) {
			[(ImageAndTextCell*)aCell setImage: [[_unitsAllCombat objectAtIndex: aRowIndex] objectForKey: @"ClassIcon"]];
		}
		
		// do text color
		if( ![aCell respondsToSelector: @selector(setTextColor:)] ){
			return;
		}
		
		Unit *unit = [[_unitsAllCombat objectAtIndex: aRowIndex] objectForKey: @"Player"];
		
		// casting unit
		if ( unit == _castingUnit ){
			[aCell setTextColor: [NSColor blueColor]];
		}
		else if ( unit == _addUnit ){
			[aCell setTextColor: [NSColor purpleColor]];
		}
		// all others
		else{
			if ( [playerData isFriendlyWithFaction:[unit factionTemplate]] || [unit cachedGUID] == [[playerData player] cachedGUID] ){
				[aCell setTextColor: [NSColor greenColor]];
			}
			else{
				[aCell setTextColor: [NSColor redColor]];
			}
		}
	}
	
	return;
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    return NO;
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectTableColumn:(NSTableColumn *)aTableColumn {
    if( [[aTableColumn identifier] isEqualToString: @"RaceIcon"])
        return NO;
    if( [[aTableColumn identifier] isEqualToString: @"ClassIcon"])
        return NO;
    return YES;
}

@end
