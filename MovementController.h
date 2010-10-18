//
//  MovementController.h
//  Pocket Gnome
//
//  Created by Josh on 2/16/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Controller;
@class BotController;
@class CombatController;
@class OffsetController;
@class PlayerDataController;
@class AuraController;
@class MacroController;
@class BlacklistController;
@class WaypointController;
@class MobController;
@class StatisticsController;
@class ProfileController;
@class BindingsController;
@class InventoryController;
@class ProfileController;

@class Unit;
@class Route;
@class Waypoint;
@class RouteSet;
@class WoWObject;
@class Position;

#define ReachedObjectNotification      @"ReachedObjectNotification"
#define ReachedFollowUnitNotification      @"ReachedFollowUnitNotification"

// How close do we need to be to a node before we dismount?
#define DistanceUntilDismountByNode	2.0f

// how close do we need to be to a school to fish?
#define NODE_DISTANCE_UNTIL_FISH		17.0f

typedef enum MovementType {
	MovementType_Mouse		= 0,
	MovementType_Keyboard	= 1,
	MovementType_CTM		= 2,
} MovementType;

@interface MovementController : NSObject {
	
	IBOutlet Controller				*controller;
	IBOutlet BotController			*botController;
	IBOutlet CombatController		*combatController;
	IBOutlet OffsetController		*offsetController;
	IBOutlet PlayerDataController	*playerData;
	IBOutlet AuraController			*auraController;
	IBOutlet MacroController		*macroController;
	IBOutlet BlacklistController	*blacklistController;
	IBOutlet WaypointController		*waypointController;
	IBOutlet MobController			*mobController;
	IBOutlet StatisticsController	*statisticsController;
	IBOutlet BindingsController		*bindingsController;
	IBOutlet InventoryController	*itemController;
	IBOutlet ProfileController		*profileController;
	
	IBOutlet NSTextField	*logOutStuckAttemptsTextField;
	IBOutlet NSPopUpButton	*movementTypePopUp;

	NSMutableDictionary *_stuckDictionary;
	
	NSString *_currentRouteKey;
	RouteSet *_currentRouteSet;			// current route set
	Waypoint *_destinationWaypoint;
	Route *_currentRoute;				// current route we're running
	Route *_currentRouteHoldForFollow;
	
	int _movementState;
	
	WoWObject *_moveToObject;			// current object we're moving to
	Position *_moveToPosition;
	
	BOOL _isMovingFromKeyboard;
	
	NSTimer *_movementTimer;			// this just checks to see if we reached our position!
	
	// stuck checking
	Position	*_lastAttemptedPosition;
	Position	*_followNextPosition;
	NSDate		*_lastAttemptedPositionTime;
	NSDate		*_lastDirectionCorrection;
	Position	*_lastPlayerPosition;
	int			_positionCheck;
	float		_lastDistanceToDestination;
	int			_stuckCounter;
	id			_unstickifyTarget;
	int			_unstickifyTry;
	
	NSDate *_movementExpiration;
	NSDate *_lastJumpTime;
	
	int _jumpCooldown;
	int _jumpAttempt;
	
	BOOL _movingUp;
	BOOL _afkPressForward;
	BOOL _lastCorrectionForward;
	BOOL _lastCorrectionLeft;
	BOOL _performingActions;
	BOOL _isFollowing;
	BOOL _isActive;

	Waypoint *_destinationWaypointUI;
}

@property (readwrite, retain) RouteSet *currentRouteSet;
@property (readwrite, assign) BOOL isFollowing;
@property (readwrite, assign) BOOL isActive;
@property (readonly, assign) BOOL performingActions;

- (void)moveForwardStart;
- (void)moveForwardStop;

- (void)moveBackwardStart;
- (void)moveBackwardStop;

// move to an object (takes priority over a route)
- (BOOL)moveToObject: (WoWObject*)object;

// move to a position (I'd prefer we don't do this often, but it is sometimes needed :()
- (void)moveToPosition: (Position*)position;

// Start out follow
- (void)startFollow;

// the object we're moving to
- (WoWObject*)moveToObject;
- (Position*)moveToPosition;

// reset the move to object and returns true on success
- (BOOL)resetMoveToObject;

// begin patrolling with this routeset
- (void)setPatrolRouteSet: (RouteSet*)route;

// stop all movement
- (void)stopMovement;

// resume movement if we stopped
- (void)resumeMovement;
- (void)resumeMovementToClosestWaypoint;

// what type of movement are we operating in?  
- (int)movementType;

// turn toward the object
- (void)turnTowardObject:(WoWObject*)obj;

// check unit for range adjustments
- (BOOL)checkUnitOutOfRange: (Unit*)target;

// dismount the player
- (BOOL)dismount;

// is the player currently moving?
- (BOOL)isMoving;

// jump
- (void)jump;
- (void)jumpRaw;
- (BOOL)jumpTowardsPosition: (Position*)position;
- (BOOL)jumpForward;
- (BOOL)jumpBack;
- (void)raiseUpAfterAirMount;

// are we currently patrolling?
- (BOOL)isPatrolling;

// reset our movement state
- (void)resetMovementState;

// remove routes
- (void)resetRoutes;

// just presses forward or backward
- (void)antiAFK;

// establish the player's position
- (void)establishPlayerPosition;
- (void)correctDirectionByTurning;

// for now
- (float)averageSpeed;
- (float)averageDistance;
- (BOOL)shouldJump;

// move to waypoint
- (void)moveToWaypoint: (Waypoint*)waypoint;

// UI
- (void)moveToWaypointFromUI:(Waypoint*)wp;

- (void)moveUpStart;
- (void)moveUpStop;
@end
