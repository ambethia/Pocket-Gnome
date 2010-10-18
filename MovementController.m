//
//  MovementController2.m
//  Pocket Gnome
//
//  Created by Josh on 2/16/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "MovementController.h"

#import "Player.h"
#import "Node.h"
#import "Unit.h"
#import "Route.h"
#import "RouteSet.h"
#import "RouteCollection.h"
#import "Mob.h"
#import "CombatProfile.h"

#import "Controller.h"
#import "BotController.h"
#import "CombatController.h"
#import "OffsetController.h"
#import "PlayerDataController.h"
#import "AuraController.h"
#import "MacroController.h"
#import "BlacklistController.h"
#import "WaypointController.h"
#import "MobController.h"
#import "StatisticsController.h"
#import "ProfileController.h"
#import "BindingsController.h"
#import "InventoryController.h"
#import "Profile.h"
#import "ProfileController.h"
#import "MailActionProfile.h"

#import "Action.h"
#import "Rule.h"

#import "Offsets.h"

#import <ScreenSaver/ScreenSaver.h>
#import <Carbon/Carbon.h>

@interface MovementController ()
@property (readwrite, retain) WoWObject *moveToObject;
@property (readwrite, retain) Position *moveToPosition;
@property (readwrite, retain) Waypoint *destinationWaypoint;
@property (readwrite, retain) NSString *currentRouteKey;
@property (readwrite, retain) Route *currentRoute;
@property (readwrite, retain) Route *currentRouteHoldForFollow;

@property (readwrite, retain) Position *lastAttemptedPosition;
@property (readwrite, retain) NSDate *lastAttemptedPositionTime;
@property (readwrite, retain) Position *lastPlayerPosition;

@property (readwrite, retain) NSDate *movementExpiration;
@property (readwrite, retain) NSDate *lastJumpTime;

@property (readwrite, retain) id unstickifyTarget;

@property (readwrite, retain) NSDate *lastDirectionCorrection;

@property (readwrite, assign) int jumpCooldown;

@end

@interface MovementController (Internal)

- (void)setClickToMove:(Position*)position andType:(UInt32)type andGUID:(UInt64)guid;

- (void)moveToWaypoint: (Waypoint*)waypoint;
- (void)checkCurrentPosition: (NSTimer*)timer;

- (void)turnLeft: (BOOL)go;
- (void)turnRight: (BOOL)go;
- (void)moveForwardStart;
- (void)moveForwardStop;
- (void)moveUpStop;
- (void)moveUpStart;
- (void)backEstablishPosition;
- (void)establishPosition;

- (void)correctDirection: (BOOL)stopStartMovement;
- (void)turnToward: (Position*)position;

- (void)routeEnded;
- (void)performActions:(NSDictionary*)dict;

- (void)realMoveToNextWaypoint;

- (void)resetMovementTimer;

- (BOOL)isCTMActive;

- (void)turnTowardPosition: (Position*)position;

- (void)unStickify;

@end

@implementation MovementController

typedef enum MovementState{
	MovementState_MovingToObject	= 0,
	MovementState_Patrolling		= 1,
	MovementState_Stuck				= 1,
}MovementState;

+ (void)initialize {
   
	/*NSDictionary *defaultValues = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSNumber numberWithBool: YES],  @"MovementShouldJump",
                                   [NSNumber numberWithInt: 2],     @"MovementMinJumpTime",
                                   [NSNumber numberWithInt: 6],     @"MovementMaxJumpTime",
                                   nil];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults: defaultValues];
    [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues: defaultValues];*/
}

- (id) init{
    self = [super init];
    if ( self != nil ) {

		_stuckDictionary = [[NSMutableDictionary dictionary] retain];

		_currentRouteSet = nil;
		_currentRouteKey = nil;

		_moveToObject = nil;
		_moveToPosition = nil;
		_lastAttemptedPosition = nil;
		_destinationWaypoint = nil;
		_lastAttemptedPositionTime = nil;
		_lastPlayerPosition = nil;
//		_movementTimer = nil;
		
		_movementState = -1;
		
		_jumpAttempt = 0;
		
		_isMovingFromKeyboard = NO;
		_positionCheck = 0;
		_lastDistanceToDestination = 0.0f;
		_stuckCounter = 0;
		_unstickifyTry = 0;
		_unstickifyTarget = nil;
		_jumpCooldown = 3;
		
		self.lastJumpTime = [NSDate distantPast];
		self.lastDirectionCorrection = [NSDate distantPast];
		
		_movingUp = NO;
		_afkPressForward = NO;
		_lastCorrectionForward = NO;
		_lastCorrectionLeft = NO;
		_performingActions = NO;
		_isActive = NO;
		self.isFollowing = NO;

		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(playerHasDied:) name: PlayerHasDiedNotification object: nil];
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(playerHasRevived:) name: PlayerHasRevivedNotification object: nil];
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(applicationWillTerminate:) name: NSApplicationWillTerminateNotification object: nil];

		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(targetNotInLOS:) name: ErrorTargetNotInLOS object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(invalidTarget:) name: ErrorInvalidTarget object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(haveNoTarget:) name: ErrorHaveNoTarget object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(cantDoThatWhileStunned:) name: ErrorCantDoThatWhileStunned object: nil];

		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(reachedFollowUnit:) name: ReachedFollowUnitNotification object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(reachedObject:) name: ReachedObjectNotification object: nil];

    }
    return self;
}

- (void) dealloc{
	[_stuckDictionary release];
	[_moveToObject release];
    [super dealloc];
}

- (void)awakeFromNib {
   //self.shouldJump = [[[NSUserDefaults standardUserDefaults] objectForKey: @"MovementShouldJump"] boolValue];
}

@synthesize currentRouteSet = _currentRouteSet;
@synthesize currentRouteKey = _currentRouteKey;
@synthesize currentRoute = _currentRoute;
@synthesize currentRouteHoldForFollow = _currentRouteHoldForFollow;
@synthesize moveToObject = _moveToObject;
@synthesize moveToPosition = _moveToPosition;
@synthesize destinationWaypoint = _destinationWaypoint;
@synthesize lastAttemptedPosition = _lastAttemptedPosition;
@synthesize lastAttemptedPositionTime = _lastAttemptedPositionTime;
@synthesize lastPlayerPosition = _lastPlayerPosition;
@synthesize unstickifyTarget = _unstickifyTarget;
@synthesize lastDirectionCorrection = _lastDirectionCorrection;
@synthesize movementExpiration = _movementExpiration;
@synthesize jumpCooldown = _jumpCooldown;
@synthesize lastJumpTime = _lastJumpTime;
@synthesize performingActions = _performingActions;
@synthesize isFollowing = _isFollowing;
@synthesize isActive = _isActive;

// checks to see if the player is moving - duh!
- (BOOL)isMoving{

	UInt32 movementFlags = [playerData movementFlags];

	// moving forward or backward
	if ( movementFlags & MovementFlag_Forward || movementFlags & MovementFlag_Backward ){
		log(LOG_MOVEMENT, @"isMoving: Moving forward/backward");
		return YES;
	}

	// moving up or down
	else if ( movementFlags & MovementFlag_FlyUp || movementFlags & MovementFlag_FlyDown ){
		log(LOG_DEV, @"isMoving: Moving up/down");
		return YES;
	}

	// CTM active
	else if (	( [self movementType] == MovementType_CTM  || 
				 ( [self movementType] == MovementType_Keyboard && ( [[playerData player] isFlyingMounted] || [[playerData player] isSwimming] ) ) ) && 
			 [self isCTMActive] ) {
		log(LOG_DEV, @"isMoving: CTM Active");
		return YES;
	}

	else if ( [playerData speed] > 0 ){
		log(LOG_DEV, @"isMoving: Speed > 0");
		return YES;
	}
	
	log(LOG_DEV, @"isMoving: Not moving!");
	
	return NO;
}

- (BOOL)moveToObject: (WoWObject*)object{
	
	if ( !botController.isBotting ) {
		[self resetMovementState];
		return NO;
	}	
	
	if ( !object || ![object isValid] ) {
		[_moveToObject release];
		_moveToObject = nil;
		return NO;
	}

	// reset our timer
	[self resetMovementTimer];

	// save and move!
	self.moveToObject = object;

	// If this is a Node then let's change the position to one just above it and overshooting it a tad
	if ( [(Unit*)object isKindOfClass: [Node class]] && [[playerData player] isFlyingMounted] ) {
		float distance = [[playerData position] distanceToPosition: [object position]];
		float horizontalDistance = [[playerData position] distanceToPosition2D: [object position]];
		if ( distance > 10.0f && horizontalDistance > 5.0f ) {

			log(LOG_MOVEMENT, @"Over shooting the node for a nice drop in!");

			float newX = 0.0;
			float newY = 0.0;
			float newZ = 0.0;
			
			// We over shoot to adjust to give us a lil stop ahead distance
			Position *playerPosition = [[playerData player] position];
			Position *nodePosition = [_moveToObject position];
			
			// If we are higher than it is we aim to over shoot a tad n land right on top
			if ( [playerPosition zPosition] > ( [[_moveToObject position] zPosition]+5.0f ) ) {
				log(LOG_NODE, @"Above node so we're overshooting to drop in.");
				// If it's north of me
				if ( [nodePosition xPosition] > [playerPosition xPosition]) newX = [nodePosition xPosition]+0.5f;
				else newX = [[_moveToObject position] xPosition]-0.5f;

				// If it's west of me
				if ( [nodePosition yPosition] > [playerPosition yPosition]) newY = [nodePosition yPosition]+0.5f;
				else newY = [nodePosition yPosition]-0.5f;

				// Just Above it for a sweet drop in
				newZ = [nodePosition zPosition]+2.5f;

			} else {
				log(LOG_NODE, @"Under node so we'll try for a higher waypoint first.");
				
				// Since we're under our node we're gonna shoot way above it and to our near side of it so we go up then back down when the momement timers catches it
				// If it's north of me
				if ( [nodePosition xPosition] > [playerPosition xPosition]) newX = [nodePosition xPosition]-5.0f;
				else newX = [nodePosition xPosition]+5.0f;

				// If it's west of me
				if ( [nodePosition yPosition] > [playerPosition yPosition]) newY = [nodePosition yPosition]-5.0f;
				else newY = [[self.moveToObject position] yPosition]+5.0f;

				// Since we've comming from under let's aim higher
				newZ = [nodePosition zPosition]+20.0f;

			}

			self.moveToPosition = [[Position alloc] initWithX:newX Y:newY Z:newZ];

		} else {
			self.moveToPosition =[object position];
		}
	} else {

	  self.moveToPosition =[object position];
	}

	[self moveToPosition: self.moveToPosition];	

	if ( [object isKindOfClass:[Mob class]] || [object isKindOfClass:[Player class]] )
		[self performSelector:@selector(stayWithObject:) withObject: _moveToObject afterDelay:0.1f];

	return YES;
}

// in case the object moves
- (void)stayWithObject:(WoWObject*)obj{

	[NSObject cancelPreviousPerformRequestsWithTarget: self];
	if ( !botController.isBotting ) {
		[self resetMovementState];
		return;
	}	
	
	// to ensure we don't do this when we shouldn't!
	if ( ![obj isValid] || obj != self.moveToObject ){
		return;
	}

	float distance = [self.lastAttemptedPosition distanceToPosition:[obj position]];

	if ( distance > 2.5f ){
		log(LOG_MOVEMENT, @"%@ moved away, re-positioning %0.2f", obj, distance);
		[self moveToObject:obj];
		return;
	}

	[self performSelector:@selector(stayWithObject:) withObject:self.moveToObject afterDelay:0.1f];
}

- (WoWObject*)moveToObject{
	return [[_moveToObject retain] autorelease];
}

- (BOOL)resetMoveToObject {
	if ( _moveToObject ) return NO;
	self.moveToObject = nil;
	return YES;	
}

// set our patrolling routeset
- (void)setPatrolRouteSet: (RouteSet*)routeSet{
	log(LOG_MOVEMENT, @"Switching from route %@ to %@", _currentRouteSet, routeSet);

	self.currentRouteSet = routeSet;

	if ( botController.pvpIsInBG ) {
		self.currentRouteKey = PrimaryRoute;
		self.currentRoute = [self.currentRouteSet routeForKey:PrimaryRoute];
	} else

	if ( [playerData isGhost] || [playerData isDead] ) {
		// player is dead
		self.currentRouteKey = CorpseRunRoute;
		self.currentRoute = [self.currentRouteSet routeForKey:CorpseRunRoute];
	} else {
		// normal route
		self.currentRouteKey = PrimaryRoute;
		self.currentRoute = [self.currentRouteSet routeForKey:PrimaryRoute];
	}

	// reset destination waypoint to make sure we re-evaluate where to go
	self.destinationWaypoint = nil;

	// set our jump time
	self.lastJumpTime = [NSDate date];
}

- (void)stopMovement {

	log(LOG_MOVEMENT, @"Stop Movement.");

	[self resetMovementTimer];

	// check to make sure we are even moving!
	UInt32 movementFlags = [playerData movementFlags];

	// player is moving
	if ( movementFlags & MovementFlag_Forward || movementFlags & MovementFlag_Backward ) {
		log(LOG_MOVEMENT, @"Player is moving, stopping movement");
		[self moveForwardStop];
	} else 

	if ( movementFlags & MovementFlag_FlyUp || movementFlags & MovementFlag_FlyDown ) {
		log(LOG_MOVEMENT, @"Player is flying, stopping movment");
		[self moveUpStop];
	} else {
		log(LOG_MOVEMENT, @"Player is not moving! No reason to stop!? Flags: 0x%X", movementFlags);
	}
}

- (void)resumeMovement{

	if ( !botController.isBotting ) {
		[self resetMovementState];
		return;
	}

	// reset our timer
	[self resetMovementTimer];

	// we're moving!
	if ( [self isMoving] ) {

		log(LOG_MOVEMENT, @"We're already moving! Stopping before resume.");

		[self stopMovement];

		usleep( 100000 );
	}

	if ( _moveToObject ) {
		log(LOG_MOVEMENT, @"Moving to object in resumeMovement.");
		_movementState = MovementState_MovingToObject;
		[self moveToPosition:[self.moveToObject position]];
		return;
	}

	// Refresh the route if we're in follow
	if (self.isFollowing) self.currentRoute = botController.followRoute;

	// Previous waypoint to move to
	if ( self.destinationWaypoint ) {
		NSArray *waypoints = [self.currentRoute waypoints];
		int index = [waypoints indexOfObject: _destinationWaypoint];
		log(LOG_WAYPOINT, @"Moving to %@ with index %d", _destinationWaypoint, index);
		[self moveToPosition:[self.destinationWaypoint position]];
		return;
	}

	if ( !self.currentRouteSet ) {
		log(LOG_ERROR, @"We have no route or unit to move to in resumeMovement!");
		[self resetMovementState];
		[botController evaluateSituation];
		return;
	}

	_movementState = MovementState_Patrolling;

	// find the closest waypoint
	
	log(LOG_MOVEMENT, @"Finding the closest waypoint");
	
	Position *playerPosition = [playerData position];
	Waypoint *newWP = nil;

	// if the player is dead, find the closest WP based on both routes
	if ( [playerData isDead] && !self.isFollowing ){
		
		// we switched to a corpse route on death
		if ( [[self.currentRoute waypoints] count] == 0 ){
			log(LOG_GHOST, @"Unable to resume, we're dead and there is no corpse route!");
			return;
		}
		
		Waypoint *closestWaypointCorpseRoute	= [[self.currentRouteSet routeForKey:CorpseRunRoute] waypointClosestToPosition:playerPosition];
		Waypoint *closestWaypointPrimaryRoute	= [[self.currentRouteSet routeForKey:PrimaryRoute] waypointClosestToPosition:playerPosition];
		
		float corpseDistance = [playerPosition distanceToPosition:[closestWaypointCorpseRoute position]];
		float primaryDistance = [playerPosition distanceToPosition:[closestWaypointPrimaryRoute position]];
		
		// use corpse route
		if ( corpseDistance < primaryDistance ){
			self.currentRouteKey = CorpseRunRoute;
			self.currentRoute = [self.currentRouteSet routeForKey:CorpseRunRoute];
			newWP = closestWaypointCorpseRoute;
		}
		// use primary route
		else {
			self.currentRouteKey = PrimaryRoute;
			self.currentRoute = [self.currentRouteSet routeForKey:PrimaryRoute];
			newWP = closestWaypointPrimaryRoute;
		}
	} else {
		// find the closest waypoint in our primary route!
		newWP = [self.currentRoute waypointClosestToPosition:playerPosition];
	}
/*
	// Check to see if we're ion BG and this is the last waypoint
	if ( botController.pvpIsInBG && !self.isFollowing ) {
		NSArray *waypoints = [self.currentRoute waypoints];
		int index = [waypoints indexOfObject: newWP];

		// at the end of the route
		if ( index == [waypoints count] - 1 ) {
			log(LOG_WAYPOINT, @"Last waypoint on a PvP route so we're not resuming to it!");
			[botController performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.25f];
			return;
		}
	}
*/	
	// we have a waypoint to move to!
	if ( newWP ) {
		NSArray *waypoints = [self.currentRoute waypoints];
		int index = [waypoints indexOfObject: newWP];
		log(LOG_WAYPOINT, @"Resuming to %@ with index %d", newWP, index);
//		log(LOG_MOVEMENT, @"Found waypoint %@ to move to", newWP);

//		[self turnTowardPosition: [newWP position]];
//		usleep(10000);
		
		[self moveToWaypoint:newWP];
	} else {
		log(LOG_ERROR, @"Unable to find a position to resume movement to in resumeMovement!");
		[self resetMovementState];
		[botController evaluateSituation];
		return;
	}
}

- (void)resumeMovementToClosestWaypoint {

	if ( !botController.isBotting ) {
		[self resetMovementState];
		return;
	}

	log(LOG_MOVEMENT, @"resumeMovementToClosestWaypoint:");

	// reset our timer
	[self resetMovementTimer];

/*
	// we're moving!
	if ( [self isMoving] ) {

		log(LOG_MOVEMENT, @"We're already moving! Stopping before resume.");

		[self stopMovement];

//		usleep( [controller refreshDelay] );
	}
*/

	if ( !_currentRouteSet ) {
		log(LOG_ERROR, @"We have no route or unit to move to!");
		[self resetMovementState];
		[botController evaluateSituation];
		return;
	}

	_movementState = MovementState_Patrolling;

	log(LOG_MOVEMENT, @"Finding the closest waypoint");

	Position *playerPosition = [playerData position];
	Waypoint *newWaypoint;

	NSArray *waypoints = [self.currentRoute waypoints];

	// find the closest waypoint in our primary route!
	newWaypoint = [self.currentRoute waypointClosestToPosition: playerPosition];
	int newWaypointIndex = [waypoints indexOfObject: newWaypoint];

	log(LOG_DEV, @"Initial closest waypoint is %@ (%d)", newWaypoint, newWaypointIndex);
	RouteCollection *theRouteCollection;

	float distanceToWaypoint = [playerPosition distanceToPosition: [newWaypoint position]];

	if ( botController.pvpIsInBG ) 
		theRouteCollection =  botController.theRouteCollectionPvP;
			else theRouteCollection =  botController.theRouteCollection;

	if ( distanceToWaypoint > 80.0f  && theRouteCollection.routes.count > 1) {
		log(LOG_WAYPOINT, @"Looks like the next waypoint is very far, checking to see if we have a closer route.");

		float closestDistance = 0.0f;
		Waypoint *thisWaypoint = nil;
		Route *route = nil;
		RouteSet *routeSetFound = [RouteSet retain];

		for (RouteSet *routeSet in [theRouteCollection routes] ) {
 
			// Set the route to test against
			if ( [playerData isGhost] || [playerData isDead] ) route = [routeSet routeForKey:CorpseRunRoute];
				else route = [routeSet routeForKey:PrimaryRoute];

			if ( !route || route == nil) continue;
 
			if ( closestDistance == 0.0f ) {
				thisWaypoint = [route waypointClosestToPosition:playerPosition];
				closestDistance = [playerPosition distanceToPosition: [thisWaypoint position]];
				routeSetFound = routeSet;
				continue;
			}
 
			// We have one to compare
			thisWaypoint = [route waypointClosestToPosition:playerPosition];
			distanceToWaypoint = [playerPosition distanceToPosition: [thisWaypoint position]];
			if (distanceToWaypoint < closestDistance) {
				closestDistance = distanceToWaypoint;
				routeSetFound = routeSet;
			}
		}

		if ( routeSetFound && [routeSetFound UUID] != [self.currentRouteSet UUID]) {
			log(LOG_WAYPOINT, @"Found a closer route, switching!");
			[self setPatrolRouteSet: routeSetFound];
			routeSetFound = nil;
			[routeSetFound release];
			[self performSelector: _cmd withObject: nil afterDelay:0.3f];
			return;
		}
	}

	float tooClose = ( [playerData speedMax] / 2.0f);
	if ( tooClose < 4.0f ) tooClose = 4.0f;

	log(LOG_WAYPOINT, @"Checking to see if waypoint distance (%0.2f) is too close (%0.2f)", distanceToWaypoint, tooClose);
	// If the waypoint is too close, grab the next
	if ( newWaypointIndex != [waypoints count] - 1 && ![newWaypoint actions] && distanceToWaypoint < tooClose ) {
		newWaypointIndex++;
		newWaypoint = [waypoints objectAtIndex: newWaypointIndex];
		log(LOG_WAYPOINT, @"Waypoint distance is too close. shifting to the next waypoint in the array.");
	}

	// If we already have a waypoint we check it
	if ( self.destinationWaypoint ) {

		int indexNext = [waypoints indexOfObject:self.destinationWaypoint];
		int indexClosest = [waypoints indexOfObject: newWaypoint];

		// If the closest waypoint is further back than the current one then don't use it.
		if ( indexClosest < indexNext) {
			newWaypoint = self.destinationWaypoint;
		} else

		// Don't skip more than...
		if ( (indexClosest-indexNext) > 10 ) {
			newWaypoint = self.destinationWaypoint;
		} else {

			Waypoint *thisWaypoint;
			NSArray *actions;
			int i;

			for ( i=indexNext; i<indexClosest; i++ ) {
				actions = nil;

				thisWaypoint = [[self.currentRoute waypoints] objectAtIndex: i];

				if ( [thisWaypoint actions] ) actions = [thisWaypoint actions];

				// If there are no actions
				if ( !actions || [actions count] <= 0 ) continue;

				// If there are actions to be taken at the current waypoint we don't skip it.
				newWaypoint = thisWaypoint;
			}
		}
	}

	// Check to see if we're air mounted and this is a long distance waypoint.  If so we wait to start our descent.
	if ( !botController.pvpIsInBG && ![playerData isOnGround] && [[playerData player] isMounted] ) {

		distanceToWaypoint = [[playerData position] distanceToPosition: [newWaypoint position]];

		float horizontalDistanceToWaypoint = [[playerData position] distanceToPosition2D: [newWaypoint position]];
		float verticalDistanceToWaypoint = [[playerData position] zPosition]-[[newWaypoint position] zPosition];
		Position *positionAboveWaypoint = [[Position alloc] initWithX:[[newWaypoint position] xPosition] Y:[[newWaypoint position] yPosition] Z:[playerPosition zPosition]];

		// Only consider this if it's a far off distance
		if ( distanceToWaypoint > 100.0f && 
			distanceToWaypoint > ( verticalDistanceToWaypoint/2.0f ) && 
			verticalDistanceToWaypoint < horizontalDistanceToWaypoint &&
			verticalDistanceToWaypoint > 30.0f
			) {

			log(LOG_WAYPOINT, @"Waypoint is far off so we won't descend until we're closer. hDist: %0.2f, vDist: %0.2f", horizontalDistanceToWaypoint, verticalDistanceToWaypoint);

			Position *positionToDescend = [playerPosition positionAtDistance:verticalDistanceToWaypoint withDestination:positionAboveWaypoint];
			log(LOG_DEV, @"playerPosition: %@, positionAboveWaypoint: %@, positionToDescend: %@", playerPosition, positionAboveWaypoint, positionToDescend);

			[self moveToPosition: positionToDescend];
			return;
		}
	}

	// we have a waypoint to move to!
	if ( newWaypoint ) {

		log(LOG_MOVEMENT, @"Found waypoint %@ to move to", newWaypoint);
		[self moveToWaypoint:newWaypoint];

	} else {
		log(LOG_ERROR, @"Unable to find a position to resume movement to!");
		[self resetMovementState];
		[botController evaluateSituation];
		return;
	}
}

- (int)movementType {
	return [movementTypePopUp selectedTag];
}

#pragma mark Waypoints
- (void)moveToWaypoint: (Waypoint*)waypoint {

	if ( !botController.isBotting ) {
		[self resetMovementState];
		return;
	}

	// reset our timer
	[self resetMovementTimer];

	int index = [[_currentRoute waypoints] indexOfObject: waypoint];
	[waypointController selectCurrentWaypoint:index];

	log(LOG_WAYPOINT, @"Moving to a waypoint: %@", waypoint);

	self.destinationWaypoint = waypoint;

	[self moveToPosition:[waypoint position]];
}

- (void)moveToWaypointFromUI:(Waypoint*)wp {
	_destinationWaypointUI = [wp retain];
	[self moveToPosition:[wp position]];
}

- (void)startFollow {
	
	log(LOG_WAYPOINT, @"Starting movement controller for follow");
	
	// reset our timer
	[self resetMovementTimer];

/*
	if ( [playerData targetID] != [[botController followUnit] GUID]) {
		log(LOG_DEV, @"Targeting follow unit.");
		[playerData targetGuid:[[botController followUnit] GUID]];
	}
*/

	// Check to see if we need to mount or dismount
	if ( [botController followMountCheck] ) {
		// Just kill the follow and mounts will be checked before follow begins again
		[self resetMovementState];
		[botController performSelector: @selector(evaluateSituation) withObject:nil afterDelay:0.1f];
		return;
	}

	self.isFollowing = YES;
	self.currentRouteHoldForFollow = self.currentRoute;
	self.currentRoute = botController.followRoute;

	// find the closest waypoint in our route
	self.destinationWaypoint = [self.currentRoute waypointClosestToPosition: [playerData position]];

	log(LOG_WAYPOINT, @"Starting movement controller for follow with waypoint: %@", self.destinationWaypoint);

	[self resumeMovement];
}

- (void)moveToNextWaypoint{

	if ( !botController.isBotting ) {
		[self resetMovementState];
		return;
	}

	// reset our timer
	[self resetMovementTimer];

	if ( self.isFollowing ) {
	
		// Check to see if we need to mount or dismount
		if ( [botController followMountCheck] ) {
			// Just kill the follow and mounts will be checked before follow begins again
			[botController performSelector: @selector(evaluateSituation) withObject:nil afterDelay:0.25f];
			[self resetMovementState];
			return;
		}

		// Refresh our follow route
		self.currentRoute = botController.followRoute;
		[self realMoveToNextWaypoint];

		// Return here since we're skipping waypoint actions in follow mode
		return;
	}

	// do we have an action for the destination we just reached?
	NSArray *actions = [self.destinationWaypoint actions];
	if ( actions && [actions count] > 0 ) {
		
		log(LOG_WAYPOINT, @"Actions to take? %d", [actions count]);

		// check if conditions are met
		Rule *rule = [self.destinationWaypoint rule];
		
		if ( rule == nil || [botController evaluateRule: rule withTarget: TargetNone asTest: NO] ) {

			log(LOG_WAYPOINT, @"Performing %d actions", [actions count] );

			// time to perform actions!
			NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
								  actions,						@"Actions",
								  [NSNumber numberWithInt:0],	@"CurrentAction",
								  nil];

			[self performActions:dict];

			return;
		}
	}

	[self realMoveToNextWaypoint];	
}

- (void)realMoveToNextWaypoint {

	if ( !botController.isBotting && !_destinationWaypointUI ) {
		[self resetMovementState];
		return;
	}

	log(LOG_WAYPOINT, @"Moving to the next waypoint!");

	// reset our timer
	[self resetMovementTimer];

	NSArray *waypoints = [self.currentRoute waypoints];
	int index = [waypoints indexOfObject:self.destinationWaypoint];

	// we have an index! yay!
	if ( index != NSNotFound ){

		// at the end of the route
		if ( index == [waypoints count] - 1 ){
			log(LOG_WAYPOINT, @"We've reached the end of the route!");
			
			// TO DO: keep a dictionary w/the route collection (or set) to remember how many times we've run a route
			
			[self routeEnded];
			return;
		}

		// increment something here to keep track of how many waypoints we've moved to?
		else if ( index < [waypoints count] - 1 ) {
			index++;
		}

		// move to the next WP
		Waypoint *newWaypoint = [waypoints objectAtIndex:index];

		// If we're in follow mode lets make sure the waypoint isn't right on top of the follow unit
		if ( self.isFollowing && botController.followUnit && [botController.followUnit isValid] ) {

			float distanceLeaderToWaypoint = [[botController.followUnit position] distanceToPosition: [newWaypoint position]];
			if (distanceLeaderToWaypoint < 4.0f) {
				log(LOG_WAYPOINT, @"We've reached the end of the follow route (next waypoint is right on top of leader)!");
				[self routeEnded];
				return;
			}
		}

		log(LOG_WAYPOINT, @"Moving to next %@ with index %d", newWaypoint, index);
		[self moveToWaypoint:newWaypoint];
	} else {
		if (self.isFollowing) {
			[self routeEnded];
			return;
		} else {
			log(LOG_ERROR, @"There are no waypoints for the current route!");
		}
	}
}

- (void)routeEnded{
	
	// reset our timer
	[self resetMovementTimer];

	// Pop the notification if we're following
	if ( self.isFollowing ) {
		log(LOG_WAYPOINT, @"Ending follow with notification.");
		[[NSNotificationCenter defaultCenter] postNotificationName: ReachedFollowUnitNotification object: nil];
		return;
	}

	// player is currently on the primary route and is dead, if they've finished, then we ran the entire route and didn't find our body :(
	if ( self.currentRouteKey == PrimaryRoute && [playerData isGhost] ) {
		[botController stopBot:nil];
		[controller setCurrentStatus:@"Bot: Unable to find body, stopping bot"];
		log(LOG_GHOST, @"Unable to find your body after running the full route, stopping bot");
		return;
	}

	// In PvP we stay where we went unless the waypoint tells us to switch routes.
	if ( botController.pvpIsInBG ) {
		log(LOG_DEV, @"End of PvP Route, stoping movement.");
		[self resetMovementState];
		[botController evaluateSituation];
		return;
	}

	// we've reached the end of our corpse route, lets switch to our main route
	if ( self.currentRouteKey == CorpseRunRoute ) {
		
		log(LOG_GHOST, @"Switching from corpse to primary route!");
		
		self.currentRouteKey = PrimaryRoute;
		self.currentRoute = [self.currentRouteSet routeForKey:PrimaryRoute];
		
		// find the closest WP
		self.destinationWaypoint = [self.currentRoute waypointClosestToPosition:[playerData position]];
	}

	// Use the first waypoint
	else{
		self.destinationWaypoint = [[self.currentRoute waypoints] objectAtIndex:0];
	}
	
	[self resumeMovement];
}

#pragma mark Actual Movement Shit - Scary

- (void)moveToPosition: (Position*)position {

	if ( !botController.isBotting && !_destinationWaypointUI ) {
		[self resetMovementState];
		return;
	}

	// reset our timer (that checks if we're at the position)
	[self resetMovementTimer];

	[botController jumpIfAirMountOnGround];

    Position *playerPosition = [playerData position];
    float distance = [playerPosition distanceToPosition: position];

	log(LOG_MOVEMENT, @"moveToPosition called (distance: %f).", distance)

	// sanity check
    if ( !position || distance == INFINITY ) {
        log(LOG_MOVEMENT, @"Invalid waypoint (distance: %f). Ending patrol.", distance);
		botController.evaluationInProgress=nil;
		[botController evaluateSituation];
        return;
    }

	float tooClose = ( [playerData speedMax] / 2.0f);
	if ( tooClose < 3.0f ) tooClose = 3.0f;

	// no object, no actions, just trying to move to the next WP!
	if ( _destinationWaypoint && !self.isFollowing && ( ![_destinationWaypoint actions] || [[_destinationWaypoint actions] count] == 0 ) && distance < tooClose  ) {
		log(LOG_WAYPOINT, @"Waypoint is too close %0.2f < %0.2f. Moving to the next one.", distance, tooClose);
		[self moveToNextWaypoint];
		return;
	}

	// we're moving to a new position!
	if ( ![_lastAttemptedPosition isEqual:position] ) 
		log(LOG_MOVEMENT, @"Moving to a new position! From %@ to %@ Timer will expire in %0.2f", _lastPlayerPosition, position, (distance/[playerData speedMax]) + 4.0);

	// only reset the stuck counter if we're going to a new position
	if ( ![position isEqual:self.lastAttemptedPosition] ) {
		log(LOG_DEV, @"Resetting stuck counter");
		_stuckCounter = 0;
	}

	self.lastAttemptedPosition		= position;
	self.lastAttemptedPositionTime	= [NSDate date];
	self.lastPlayerPosition			= playerPosition;
	_positionCheck					= 0;
	_lastDistanceToDestination		= 0.0f;

	_isActive = YES;

    self.movementExpiration = [NSDate dateWithTimeIntervalSinceNow: (distance/[playerData speedMax]) + 4.0f];

	// Actually move!
	if ( [self movementType] == MovementType_Keyboard && [[playerData player] isFlyingMounted] ) {
		log(LOG_MOVEMENT, @"Forcing CTM since we're flying!");
		// Force CTM for party follow.
		[self setClickToMove:position andType:ctmWalkTo andGUID:0];
	}

	else if ( [self movementType] == MovementType_Keyboard && [[playerData player] isSwimming] ) {
		log(LOG_MOVEMENT, @"Forcing CTM since we're swimming!");
		// Force CTM for party follow.
		[self setClickToMove:position andType:ctmWalkTo andGUID:0];
	}

	else if ( [self movementType] == MovementType_Keyboard ) {
		log(LOG_MOVEMENT, @"moveToPosition: with Keyboard");
		UInt32 movementFlags = [playerData movementFlags];

		// If we don't have the bit for forward motion let's stop
		if ( !(movementFlags & MovementFlag_Forward) ) [self moveForwardStop];
        [self correctDirection: YES];
        if ( !(movementFlags & MovementFlag_Forward) )  [self moveForwardStart];
	}

	else if ( [self movementType] == MovementType_Mouse ) {
		log(LOG_MOVEMENT, @"moveToPosition: with Mouse");

		[self moveForwardStop];
		[self correctDirection: YES];
		[self moveForwardStart];
	}

	else if ( [self movementType] == MovementType_CTM ) {
		log(LOG_MOVEMENT, @"moveToPosition: with CTM");
		[self setClickToMove:position andType:ctmWalkTo andGUID:0];
	}

	_movementTimer = [NSTimer scheduledTimerWithTimeInterval: 0.25f target: self selector: @selector(checkCurrentPosition:) userInfo: nil repeats: YES];
}

- (void)checkCurrentPosition: (NSTimer*)timer {

	// stopped botting?  end!
	if ( !botController.isBotting && !_destinationWaypointUI ) {
		log(LOG_MOVEMENT, @"We're not botting, stop the timer!");
		[self resetMovementState];
		return;
	}

	_positionCheck++;

	if (_stuckCounter > 0) {
		log(LOG_MOVEMENT, @"[%d] Check current position.  Stuck counter: %d", _positionCheck, _stuckCounter);
	} else {
		log(LOG_MOVEMENT, @"[%d] Check current position.", _positionCheck);
	}

	Player *player=[playerData player];

	// If we're in the air, but not air mounted we don't try to correct movement unless we are CTM
	if ( [self movementType] != MovementType_CTM && ![player isOnGround] && ![playerData isAirMounted] && ![player isSwimming] ) {
		log(LOG_MOVEMENT, @"Skipping position check since we're in the air and not air mounted.");
		return;
	}

	Position *playerPosition = [player position];
	float playerSpeed = [playerData speed];
    Position *destPosition;
	float distanceToDestination;
	float stopingDistance;

	/*
	 * Being called from the UI
	 */

	if ( _destinationWaypointUI ) {
		destPosition = [_destinationWaypoint position];
		distanceToDestination = [playerPosition distanceToPosition: destPosition];

		// sanity check, incase something happens
		if ( distanceToDestination == INFINITY ) {
			log(LOG_MOVEMENT, @"Player distance == infinity. Stopping.");
			[_destinationWaypointUI release];
			_destinationWaypointUI = nil;
			// stop movement
			[self resetMovementState];
			return;
		}

		// 4 yards considering before/after
		stopingDistance = 2.0f;

		// we've reached our position!
		if ( distanceToDestination <= stopingDistance ) {
			log(LOG_MOVEMENT, @"Reached our destination while moving from UI.");
			[_destinationWaypointUI release];
			_destinationWaypointUI = nil;
			// stop movement
			[self resetMovementState];
			return;
		}

		// If we're stuck lets just stop
		if ( _positionCheck > 6 && ![self isMoving] ) {
			log(LOG_MOVEMENT, @"Stuck while moving from UI.");
			[_destinationWaypointUI release];
			_destinationWaypointUI = nil;
			// stop movement
			[self resetMovementState];
			return;
		}

		// Since we're moving to a UI waypoint we don't do any stuck checking
		return;
		
	} else

	/*
	 * We are in Follow mode
	 */

	if ( self.isFollowing ) {

		// Check to see if we're close to the follow unit enough to stop.
		if ( botController.followUnit && [botController.followUnit isValid] ) {
			log(LOG_DEV, @"Checking to see if we're close enough to stop.");

			Position *positionFollowUnit = [botController.followUnit position];
			float distanceToFollowUnit = [playerPosition distanceToPosition: positionFollowUnit];

			// If we're close enough let's check to see if we need to stop
			if ( distanceToFollowUnit <=  botController.theCombatProfile.yardsBehindTargetStop ) {
				log(LOG_DEV, @"Setting a random stopping distance");

				// Establish a random stopping distance
				float randomStoppingDistance = SSRandomFloatBetween(botController.theCombatProfile.yardsBehindTargetStart, botController.theCombatProfile.yardsBehindTargetStop);
				if ( distanceToFollowUnit < randomStoppingDistance ) {
					log(LOG_MOVEMENT, @"Reached our follow unit.");
					// We're close enough to stop!
					[[NSNotificationCenter defaultCenter] postNotificationName: ReachedFollowUnitNotification object: nil];
					return;
				}
			}
		}

		// Check to see if we need to mount or dismount
		if ( [botController followMountCheck] ) {
			// Just kill the follow and mounts will be checked before follow begins again
			log(LOG_MOVEMENT, @"Need to mount while in follow.");
			[botController performSelector: @selector(evaluateSituation) withObject:nil afterDelay:0.25f];
			[self resetMovementState];
			return;
		}

		destPosition = [_destinationWaypoint position];
		distanceToDestination = [playerPosition distanceToPosition: destPosition];

		if ( !botController.followUnit || ![botController.followUnit isValid] ) {

			// Since the leader is out of sight we'll make this a very short distance so we hit zone ins better
			stopingDistance = 3.0f;	// 6.0 yards total before/after

			// we've reached our position!
			if ( distanceToDestination <= stopingDistance ) {
				log(LOG_MOVEMENT, @"Reached follow waypoint.");
				[self moveToNextWaypoint];
				return;
			}

		} else {

			stopingDistance = ([playerData speedMax]/2.0f);
			if ( stopingDistance < 3.0f) stopingDistance = 3.0f;

			// we've reached our position!
			if ( distanceToDestination <= stopingDistance ) {
				log(LOG_MOVEMENT, @"Reached follow waypoint.");
				[self moveToNextWaypoint];
				return;
			}
		}

	} else

	/*
	 * Moving to a Node
	 */

	if (_moveToObject && [_moveToObject isKindOfClass: [Node class]] ) {
		destPosition = [_moveToObject position];
		distanceToDestination = [playerPosition distanceToPosition: destPosition];

		// sanity check, incase something happens
		if ( distanceToDestination == INFINITY ) {
			log(LOG_MOVEMENT, @"Player distance == infinity. Stopping.");
			[botController cancelCurrentEvaluation];
			[botController performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.25f];
			[self resetMovementState];
			return;
		}

		if ( ![(Node*) _moveToObject validToLoot] ) {
			log(LOG_NODE, @"%@ is not valid to loot, moving on.", _moveToObject);
			[botController cancelCurrentEvaluation];
			[botController performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.25f];
			[self resetMovementState];
			return;
		}

		if ( distanceToDestination > 20.0f ) {
			// If we're not supposed to loot this node due to proximity rules
			BOOL nearbyScaryUnits = [botController scaryUnitsNearNode:_moveToObject doMob:botController.theCombatProfile.GatherNodesMobNear doFriendy:botController.theCombatProfile.GatherNodesFriendlyPlayerNear doHostile:botController.theCombatProfile.GatherNodesHostilePlayerNear];

			if ( nearbyScaryUnits ) {
				log(LOG_NODE, @"Skipping node due to proximity count");
				[botController cancelCurrentEvaluation];
				[botController performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.25f];
				[self resetMovementState];
				return;
			}
		}

		stopingDistance = 2.4f;

		float horizontalDistance = [[playerData position] distanceToPosition2D: [_moveToObject position]];

		// we've reached our position!
		if ( distanceToDestination <= stopingDistance || ( horizontalDistance < 1.3f && distanceToDestination <= 4.0f) ) {

			if ( [[playerData player] isFlyingMounted] ) { 
				log(LOG_MOVEMENT, @"Reached our hover spot for node: %@", _moveToObject);
			} else {
				log(LOG_MOVEMENT, @"Reached our node: %@", _moveToObject);
			}

			// Send a notification
			[[NSNotificationCenter defaultCenter] postNotificationName: ReachedObjectNotification object: [[_moveToObject retain] autorelease]];
			return;
		}

	} else

	/*
	 * Moving to loot a mob
	 */

	if ( _moveToObject && [_moveToObject isKindOfClass: [Mob class]] && botController.mobsToLoot && [botController.mobsToLoot containsObject: (Mob*)_moveToObject]  ) {
		destPosition = [_moveToObject position];
		distanceToDestination = [playerPosition distanceToPosition: destPosition];

		// sanity check, incase something happens
		if ( distanceToDestination == INFINITY ) {
			log(LOG_MOVEMENT, @"Player distance == infinity. Stopping.");
			[botController performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.25f];
			[self resetMovementState];
			return;
		}

		if ( ![(Unit*)_moveToObject isValid] ) {
			log(LOG_LOOT, @"%@ is not valid to loot, moving on.", _moveToObject);
			[botController performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.25f];
			[self resetMovementState];
			return;
		}
/*
		if ( ![(Unit*)_moveToObject isLootable] ) {
			log(LOG_LOOT, @"%@ is no longer lootable, moving on.", _moveToObject);
			[botController performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.25f];
			[self resetMovementState];
			return;
		}
*/

		stopingDistance = 3.0f; // 6 yards total

		// we've reached our position!
		if ( distanceToDestination <= stopingDistance ) {

			log(LOG_MOVEMENT, @"Reached our loot: %@", _moveToObject);

			// Send a notification
			[[NSNotificationCenter defaultCenter] postNotificationName: ReachedObjectNotification object: [[_moveToObject retain] autorelease]];
			return;
		}

	} else

	/*
	 * Moving to an object
	 */

	if ( _moveToObject ) {
		destPosition = [_moveToObject position];
		distanceToDestination = [playerPosition distanceToPosition: destPosition];

		// sanity check, incase something happens
		if ( distanceToDestination == INFINITY ) {
			log(LOG_MOVEMENT, @"Player distance == infinity. Stopping.");
			[botController performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.25f];
			[self resetMovementState];
			return;
		}

		stopingDistance = 4.0f; // 8 yards total
		
		// we've reached our position!
		if ( distanceToDestination <= stopingDistance ) {

			log(LOG_MOVEMENT, @"Reached our object: %@", _moveToObject);

			// Send a notification
			[[NSNotificationCenter defaultCenter] postNotificationName: ReachedObjectNotification object: [[_moveToObject retain] autorelease]];
			return;
		}

	} else

	/*
	 * Moving to a waypoint on a route
	 */

	if ( self.destinationWaypoint ) {

		destPosition = [_destinationWaypoint position];
		distanceToDestination = [playerPosition distanceToPosition: destPosition];

		// sanity check, incase something happens
		if ( distanceToDestination == INFINITY ) {
			log(LOG_MOVEMENT, @"Player distance == infinity. Stopping.");
			[botController performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.25f];
			[self resetMovementState];
			return;
		}

		// Ghost Handling
		if ( [playerData isGhost] ) {

			// Check to see if our corpse is in sight.
			if( !botController.movingToCorpse && [playerData corpsePosition] ) {
				Position *playerPosition = [playerData position];
				Position *corpsePosition = [playerData corpsePosition];
				float distanceToCorpse = [playerPosition distanceToPosition: corpsePosition];
				if ( distanceToCorpse <= botController.theCombatProfile.moveToCorpseRange ) {
					log(LOG_MOVEMENT, @"Corpse in sight, stopping movement.");
					[botController performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.25f];
					[self resetMovementState];
					return;
				}
			}
		}

		stopingDistance = ([playerData speedMax]/2.0f);
		if ( stopingDistance < 4.0f) stopingDistance = 4.0f;

		// We've reached our position!
		if ( distanceToDestination <= stopingDistance ) {
			log(LOG_MOVEMENT, @"Reached our destination! %0.2f < %0.2f", distanceToDestination, stopingDistance);
			[self moveToNextWaypoint];
			return;
		}

	} else

	/*
	 * If it's not moveToObject and no destination waypoint then we must have called moveToPosition by it's self (perhaps to a far off waypoint)
	 */

	if ( self.lastAttemptedPosition ) {

		destPosition = self.lastAttemptedPosition;
		distanceToDestination = [playerPosition distanceToPosition: destPosition];

		// sanity check, incase something happens
		if ( distanceToDestination == INFINITY ) {
			log(LOG_MOVEMENT, @"Player distance == infinity. Stopping.");
			[botController performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.25f];
			[self resetMovementState];
			return;
		}

		stopingDistance = ([playerData speedMax]/2.0f);
		if ( stopingDistance < 4.0f) stopingDistance = 4.0f;

		// We've reached our position!
		if ( distanceToDestination <= stopingDistance ) {
			log(LOG_MOVEMENT, @"Reached our destination! %0.2f < %0.2f", distanceToDestination, stopingDistance);
			[botController performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.25f];
			[self resetMovementState];
			return;
		}

	} else {

		log(LOG_ERROR, @"Somehow we' cant tell what we're moving to!?");
		[botController performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.25f];
		[self resetMovementState];
		return;
	}

	// ******************************************
	// if we we get here, we're not close enough 
	// ******************************************

	// If it's not been 1/4 a second yet don't try anything else
	if ( _positionCheck <= 1 ) {

		// Check evaluation to see if we need to do anything
		if ( !botController.evaluationIsActive && !botController.procedureInProgress ) 
			[botController performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.1f];

		return;
	}

	// should we jump?
	float tooCLose = ([playerData speedMax]/1.1f);
	if ( tooCLose < 3.0f) tooCLose = 3.0f;

	if ( [self isMoving] && distanceToDestination > tooCLose  &&
		playerSpeed >= [playerData speedMax] && 
		[[[NSUserDefaults standardUserDefaults] objectForKey: @"MovementShouldJump"] boolValue] &&
		![[playerData player] isFlyingMounted]
		) {

		if ( ([[NSDate date] timeIntervalSinceDate: self.lastJumpTime] > self.jumpCooldown ) ) {
			[self jump];
			return;
		}
	}

	// If it's not been 1/2 a second yet don't try anything else
	if ( _positionCheck <= 2 ) {
		
		// Check evaluation to see if we need to do anything
		if ( !botController.evaluationIsActive && !botController.procedureInProgress ) 
			[botController performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.1f];
		
		return;
	}

	// *******************************************************
	// stuck checking
	// *******************************************************

	// If we're in preparation just keep running forward, no unsticking (most likely we are running against a gate)
	// make sure we're still moving
	if ( !botController.waitForPvPPreparation && _stuckCounter < 2 && ![self isMoving] ) {
		log(LOG_MOVEMENT, @"For some reason we're not moving! Increasing stuck counter by 1!");
		_stuckCounter++;
		return;
	}

	// make sure we're still moving
	if ( !botController.waitForPvPPreparation && _stuckCounter < 3 && ![self isMoving] ) {
		log(LOG_MOVEMENT, @"For some reason we're not moving! Let's start moving again!");
		[self resumeMovement];
		_stuckCounter++;
		return;
	}

	// copy the old stuck counter
	int oldStuckCounter = _stuckCounter;

	// we're stuck?
	if ( _stuckCounter > 3 ) {
		[controller setCurrentStatus: @"Bot: Stuck, entering anti-stuck routine"];
		log(LOG_MOVEMENT, @"Player is stuck, trying anti-stuck routine.");
		[self unStickify];
		return;
	}

	// check to see if we are stuck
	if ( _positionCheck > 6 ) {
		float maxSpeed = [playerData speedMax];
		float distanceTraveled = [self.lastPlayerPosition distanceToPosition:playerPosition];

//		log(LOG_DEV, @" Checking speed: %0.2f <= %.02f  (max: %0.2f)", playerSpeed, (maxSpeed/10.0f), maxSpeed );
//		log(LOG_DEV, @" Checking distance: %0.2f <= %0.2f", distanceTraveled, (maxSpeed/10.0f)/5.0f);

		// distance + speed check
		if ( distanceTraveled <= (maxSpeed/10.0f)/5.0f || playerSpeed <= maxSpeed/10.0f ) {
			log(LOG_DEV, @"Incrementing the stuck counter! (playerSpeed: %0.2f)", playerSpeed);
			_stuckCounter++;
		}

		self.lastPlayerPosition = playerPosition;
	}

	// reset if stuck didn't change!
	if ( _positionCheck > 16 && oldStuckCounter == _stuckCounter ) _stuckCounter = 0;

	UInt32 movementFlags = [playerData movementFlags];

	// are we stuck moving up?
	if ( movementFlags & MovementFlag_FlyUp && !_movingUp ){
		log(LOG_MOVEMENT, @"We're stuck moving up! Fixing!");
		[self moveUpStop];
		[self resumeMovement];
		return;
	}

	if( [controller currentStatus] == @"Bot: Stuck, entering anti-stuck routine" ) {
		if ( self.isFollowing ) [controller setCurrentStatus: @"Bot: Following"];
		else if ( self.moveToObject ) [controller setCurrentStatus: @"Bot: Moving to object"];
		else [controller setCurrentStatus: @"Bot: Patrolling"];
	}

	// Check evaluation to see if we need to do anything
	if ( !botController.evaluationIsActive && !botController.procedureInProgress ) 
		[botController performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.1f];

	// TO DO: moving in the wrong direction check? (can sometimes happen when doing mouse movements based on the speed of the machine)
}

- (void)unStickify{

	if ( !botController.isBotting ) {
		[self resetMovementState];
		return;
	}

	// Stop the timer
	[self resetMovementTimer];

	// Update our follow route
	if ( self.isFollowing ) 
		self.currentRoute = botController.followRoute;

	_movementState = MovementState_Stuck;

	// *************************************************
	// Check for alarm/log out
	// *************************************************
	
	// should we play an alarm?
	if ( [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"AlarmOnStuck"] boolValue] ){
		int stuckThreshold = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"AlarmOnStuckAttempts"] intValue];
		if ( _unstickifyTry > stuckThreshold ){
			log(LOG_MOVEMENT, @"We're stuck, playing an alarm!");
			[[NSSound soundNamed: @"alarm"] play];
		}
	}

	// check to see if we should log out!
	if ( [[botController logOutAfterStuckCheckbox] state] ){
		int stuckTries = [logOutStuckAttemptsTextField intValue];

		if ( _unstickifyTry > stuckTries ) {
			log(LOG_MOVEMENT, @"We're stuck, closing wow!");
			[botController logOut];
			[controller setCurrentStatus: @"Bot: Logged out due to being stuck"];
			return;
		}
	}

	// set our stuck counter to 0!
	_stuckCounter = 0;

	// is this a new attempt?
	id lastTarget = [self.unstickifyTarget retain];

	// what is our new "target" we are trying to reach?
	if ( self.moveToObject ) self.unstickifyTarget = self.moveToObject;
		else self.unstickifyTarget = self.destinationWaypoint;

	// reset our counter
	if ( self.unstickifyTarget != lastTarget ) _unstickifyTry = 0;

	_unstickifyTry++;
	[lastTarget release];

	log(LOG_MOVEMENT, @"Entering anti-stuck procedure! Try %d", _unstickifyTry);

	[botController jumpIfAirMountOnGround];

	// anti-stuck for follow!
	if ( self.isFollowing && _unstickifyTry > 5) {

		log(LOG_MOVEMENT, @"Got stuck while following, cancelling follow!");
		[[NSNotificationCenter defaultCenter] postNotificationName: ReachedFollowUnitNotification object: nil];
		return;

	}

	// Can't reach a waypoint
	if ( self.destinationWaypoint && _unstickifyTry > 5 ){

		// move to the previous waypoint and try this again
		NSArray *waypoints = [[self currentRoute] waypoints];
		int index = [waypoints indexOfObject: [self destinationWaypoint]];

		if ( index != NSNotFound ) {
			if ( index == 0 ) index = [waypoints count];
			log(LOG_MOVEMENT, @"Moving to prevous waypoint.");
			[self moveToWaypoint: [waypoints objectAtIndex: index-1]];
			return;
		} else {
			log(LOG_MOVEMENT, @"Trying to move to a previous WP, previously we would finish the route");
		}
	}

	if ( self.destinationWaypoint && _unstickifyTry > 10 ) {
		// Move to the closest waypoint
//		self.destinationWaypoint = [self.currentRoute waypointClosestToPosition:[playerData position]];
		[self moveToWaypoint: [self.currentRoute waypointClosestToPosition:[playerData position]]];
		return;
	}

	// Moving to an object
	if ( self.moveToObject ) {

		// If it's a Node we'll adhere to the UI blacklist setting
		if ( [self.moveToObject isKindOfClass: [Node class]] ) {

			// have we exceeded the amount of attempts to move to the node?
			int blacklistTriggerNodeFailedToReach = [[[NSUserDefaults standardUserDefaults] objectForKey: @"BlacklistTriggerNodeFailedToReach"] intValue];
			if ( _unstickifyTry > blacklistTriggerNodeFailedToReach ) {

				log(LOG_NODE, @"Unable to reach %@ after %d attempts, blacklisting.", _moveToObject, blacklistTriggerNodeFailedToReach);

				[blacklistController blacklistObject:(Node*)self.moveToObject withReason:Reason_CantReachObject];
				[botController cancelCurrentEvaluation];

				[botController performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.25f];
				[self resetMovementState];
				return;
			}

		} else

		if ( [_moveToObject isKindOfClass: [Mob class]] && botController.mobsToLoot && [botController.mobsToLoot containsObject: (Mob*)_moveToObject] ) {

			// NOTE: For now we're just using the setting from the Mining and Herbalism in the UI

			// have we exceeded the amount of attempts to move to the node?
			int blacklistTriggerNodeFailedToReach = [[[NSUserDefaults standardUserDefaults] objectForKey: @"BlacklistTriggerNodeFailedToReach"] intValue];

			if ( _unstickifyTry > blacklistTriggerNodeFailedToReach ) {

				log(LOG_LOOT, @"Unable to reach %@ after %d attempts, blacklisting.", _moveToObject, blacklistTriggerNodeFailedToReach);

				[blacklistController blacklistObject:(Mob*)self.moveToObject withReason:Reason_CantReachObject];

				[botController cancelCurrentEvaluation];

				[botController performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.25f];
				[self resetMovementState];
				return;
			}

		} else

		// blacklist unit after 5 tries!
		if ( _unstickifyTry > 5 && _unstickifyTry < 10 ) {
			
			log(LOG_MOVEMENT, @"Unable to reach %@, blacklisting", self.moveToObject);
			
			[blacklistController blacklistObject:self.moveToObject withReason:Reason_CantReachObject];

			[botController cancelCurrentEvaluation];

			[botController performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.25f];
			[self resetMovementState];
			return;
		}
	}

	// player is flying and is stuck :(  makes me sad, lets move up a bit
	if ( [[playerData player] isFlyingMounted] ) {

		log(LOG_MOVEMENT, @"Moving up since we're flying mounted!");
/*
		if ( _unstickifyTry < 3 ) {
			// Bump to the right
			[bindingsController executeBindingForKey:BindingStrafeRight];
		} else {
			// Bump to the left
			[bindingsController executeBindingForKey:BindingStrafeLeft];
		}
*/
		// move up for 1 second!

		[self moveUpStop];
		[self moveUpStart];
/*
		if ( _unstickifyTry < 3 ) {
			// Bump to the right
			[bindingsController executeBindingForKey:BindingStrafeRight];
		} else {
			// Bump to the left
			[bindingsController executeBindingForKey:BindingStrafeLeft];
		}
*/
		[self performSelector:@selector(moveUpStop) withObject:nil afterDelay:1.4f];
		[self performSelector:@selector(resumeMovement) withObject:nil afterDelay:1.5f];
		return;
	}

	if ( _unstickifyTry == 3 ) {
		log(LOG_MOVEMENT, @"Stuck, backing up too try to jump over object.");

		// Stop n back up a lil
		[self stopMovement];
		_isActive = YES;
		// Jump Back
		[self jumpBack];
		usleep( 300000 );

		// Move forward
		[self moveForwardStart];
		usleep( 200000 );

	}

	log(LOG_MOVEMENT, @"Stuck so I'm jumping!");
	// Jump
	[self jumpRaw];
/*
	if ( _unstickifyTry < 2 ) [bindingsController executeBindingForKey:BindingStrafeRight];
	else [bindingsController executeBindingForKey:BindingStrafeLeft];

	usleep( [controller refreshDelay]*2 );

	if ( _unstickifyTry < 2 ) [bindingsController executeBindingForKey:BindingStrafeRight];
	else [bindingsController executeBindingForKey:BindingStrafeLeft];
*/
	[self resumeMovement];
	return;
}

- (BOOL)checkUnitOutOfRange: (Unit*)target {
	
	if ( !botController.isBotting ) {
		[self resetMovementState];
		return NO;
	}

	// This is intended for issues like runners, a chance to correct vs blacklist
	// Hopefully this will help to avoid bad blacklisting which comes AFTER the cast
	// returns true if the mob is good to go

	if (!target || target == nil) return YES;

	// only do this for hostiles
	if (![playerData isHostileWithFaction: [target factionTemplate]]) return YES;

	Position *playerPosition = [(PlayerDataController*)playerData position];
	// If the mob is in our attack range return true
	float distanceToTarget = [playerPosition distanceToPosition: [target position]];

	
	if ( distanceToTarget <= [botController.theCombatProfile attackRange] ) return YES;

	float vertOffset = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"BlacklistVerticalOffset"] floatValue];

	if ( [[target position] verticalDistanceToPosition: playerPosition] > vertOffset ) {
		log(LOG_COMBAT, @"Target is beyond the vertical offset limits: %@, giving up.", target);
		return NO;
	}

	log(LOG_COMBAT, @"%@ has gone out of range: %0.2f", target, distanceToTarget);

	float attackRange = [botController.theCombatProfile engageRange];
	if ( [botController.theCombatProfile attackRange] > [botController.theCombatProfile engageRange] )
		attackRange = [botController.theCombatProfile attackRange];
	
	// If they're just a lil out of range lets inch up
	if ( distanceToTarget < (attackRange + 6.0f) ) {

		log(LOG_COMBAT, @"Unit is still close, jumping forward.");

		if ( [self jumpTowardsPosition: [target position]] ) {
	
			// Now check again to see if they're in range
			float distanceToTarget = [playerPosition distanceToPosition: [target position]];

			if ( distanceToTarget > botController.theCombatProfile.attackRange ) {
				log(LOG_COMBAT, @"Still out of range: %@, giving up.", target);
				return NO;
			} else {
				log(LOG_COMBAT, @"Back in range: %@.", target);
				return YES;
			}
		}
	}

	// They're running and they're nothing we can do about it
	log(LOG_COMBAT, @"Target: %@ has gone out of range: %0.2f", target, distanceToTarget);
    return NO;
}

- (void)resetRoutes{

	// dump the routes!
	self.currentRouteSet = nil;
	self.currentRouteKey = nil;
	self.currentRoute = nil;

}

- (void)resetMovementState {

	[NSObject cancelPreviousPerformRequestsWithTarget: self];
	log(LOG_MOVEMENT, @"Resetting movement state");

	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(unstickifyTarget) object: nil];

	// reset our timer
	[self resetMovementTimer];

	if ( [self isMoving] ) {
		log(LOG_MOVEMENT, @"Stopping movement!");
		[self stopMovement];
	}

	if ( [self isCTMActive] ) [self setClickToMove:nil andType:ctmIdle andGUID:0x0];

	if ( _moveToObject ) {
		[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(stayWithObject:) object: _moveToObject];
	}
	[_moveToObject release]; _moveToObject = nil;
	self.moveToObject = nil;

	self.destinationWaypoint		= nil;
	self.lastAttemptedPosition		= nil;
	self.lastAttemptedPositionTime	= nil;
	self.lastPlayerPosition			= nil;
	_isMovingFromKeyboard			= NO;
	[_stuckDictionary removeAllObjects];
	_positionCheck = 0;
	_unstickifyTry = 0;
	_stuckCounter = 0;
	_performingActions = NO;

	if ( self.currentRouteHoldForFollow && self.currentRouteHoldForFollow != nil ) {
		// Switch back to what ever was the old route
		self.currentRoute =	self.currentRouteHoldForFollow;
		self.currentRouteHoldForFollow =  nil;
	}

	_isActive = NO;
	_isFollowing = NO;
}

#pragma mark -

- (void)resetMovementTimer{	
	if ( !_movementTimer ) return;
	log(LOG_MOVEMENT, @"Resetting the movement timer.");
    [_movementTimer invalidate];
	_movementTimer = nil;
}

- (void)correctDirection: (BOOL)stopStartMovement {

	// Handlers for the various object/waypoint types
	if ( _moveToObject ) {
		[self turnTowardObject: _moveToObject];

	} else if ( _destinationWaypoint ) {
		[self turnToward: [_destinationWaypoint position]];

	} else if ( _lastAttemptedPosition ) {
		[self turnToward: _lastAttemptedPosition];
	}

}

- (void)turnToward: (Position*)position{

	/*if ( [movementType selectedTag] == MOVE_CTM ){
	 log(LOG_MOVEMENT, @"[Move] In theory we should never be here!");
	 return;
	 }*/
	
    BOOL printTurnInfo = NO;
	
	// don't change position if the right mouse button is down
    if ( ![controller isWoWFront] || ( ( GetCurrentButtonState() & 0x2 ) != 0x2 ) ) {
        Position *playerPosition = [playerData position];
        if ( [self movementType] == MovementType_Keyboard ){
			
            // check player facing vs. unit position
            float playerDirection, savedDirection;
            playerDirection = savedDirection = [playerData directionFacing];
            float theAngle = [playerPosition angleTo: position];
			
            if ( fabsf(theAngle - playerDirection) > M_PI ){
                if ( theAngle < playerDirection )	theAngle += (M_PI*2);
                else								playerDirection += (M_PI*2);
            }
            
            // find the difference between the angles
            float angleTo = (theAngle - playerDirection), absAngleTo = fabsf(angleTo);
            
            // tan(angle) = error / distance; error = distance * tan(angle);
            float speedMax = [playerData speedMax];
            float startDistance = [playerPosition distanceToPosition2D: position];
            float errorLimit = (startDistance < speedMax) ?  1.0f : (1.0f + ((startDistance-speedMax)/12.5f)); // (speedMax/3.0f);
            //([playerData speed] > 0) ? ([playerData speedMax]/4.0f) : ((startDistance < [playerData speedMax]) ? 1.0f : 2.0f);
            float errorStart = (absAngleTo < M_PI_2) ? (startDistance * sinf(absAngleTo)) : INFINITY;
            
            
            if( errorStart > (errorLimit) ) { // (fabsf(angleTo) > OneDegree*5) 
				
                // compensate for time taken for WoW to process keystrokes.
                // response time is directly proportional to WoW's refresh rate (FPS)
                // 2.25 rad/sec is an approximate turning speed
                float compensationFactor = ([controller refreshDelay]/2000000.0f) * 2.25f;
                
                if(printTurnInfo) log(LOG_MOVEMENT, @"[Turn] ------");
                if(printTurnInfo) log(LOG_MOVEMENT, @"[Turn] %.3f rad turn with %.2f error (lim %.2f) for distance %.2f.", absAngleTo, errorStart, errorLimit, startDistance);
                
                NSDate *date = [NSDate date];
                ( angleTo > 0) ? [self turnLeft: YES] : [self turnRight: YES];
                
                int delayCount = 0;
                float errorPrev = errorStart, errorNow;
                float lastDiff = angleTo, currDiff;
                
                
                while ( delayCount < 2500 ) { // && (signbit(lastDiff) == signbit(currDiff))
                    
                    // get current values
                    Position *currPlayerPosition = [playerData position];
                    float currAngle = [currPlayerPosition angleTo: position];
                    float currPlayerDirection = [playerData directionFacing];
                    
                    // correct for looping around the circle
                    if(fabsf(currAngle - currPlayerDirection) > M_PI) {
                        if(currAngle < currPlayerDirection) currAngle += (M_PI*2);
                        else                                currPlayerDirection += (M_PI*2);
                    }
                    currDiff = (currAngle - currPlayerDirection);
                    
                    // get current diff and apply compensation factor
                    float modifiedDiff = fabsf(currDiff);
                    if(modifiedDiff > compensationFactor) modifiedDiff -= compensationFactor;
                    
                    float currentDistance = [currPlayerPosition distanceToPosition2D: position];
                    errorNow = (fabsf(currDiff) < M_PI_2) ? (currentDistance * sinf(modifiedDiff)) : INFINITY;
                    
                    if( (errorNow < errorLimit) ) {
                        if(printTurnInfo) log(LOG_MOVEMENT, @"[Turn] [Range is Good] %.2f < %.2f", errorNow, errorLimit);
                        //log(LOG_MOVEMENT, @"Expected additional movement: %.2f", currentDistance * sinf(0.035*2.25));
                        break;
                    }
                    
                    if( (delayCount > 250) ) {
                        if( (signbit(lastDiff) != signbit(currDiff)) ) {
                            if(printTurnInfo) log(LOG_MOVEMENT, @"[Turn] [Sign Diff] %.3f vs. %.3f (Error: %.2f vs. %.2f)", lastDiff, currDiff, errorNow, errorPrev);
                            break;
                        }
                        if( (errorNow > (errorPrev + errorLimit)) ) {
                            if(printTurnInfo) log(LOG_MOVEMENT, @"[Turn] [Error Growing] %.2f > %.2f", errorNow, errorPrev);
                            break;
                        }
                    }
                    
                    if(errorNow < errorPrev)
                        errorPrev = errorNow;
					
                    lastDiff = currDiff;
                    
                    delayCount++;
                    usleep(1000);
                }
                
                ( angleTo > 0) ? [self turnLeft: NO] : [self turnRight: NO];
                
                float finalFacing = [playerData directionFacing];
				
                /*int j = 0;
				 while(1) {
				 j++;
				 usleep(2000);
				 if(finalFacing != [playerData directionFacing]) {
				 float currentDistance = [[playerData position] distanceToPosition2D: position];
				 float diff = fabsf([playerData directionFacing] - finalFacing);
				 log(LOG_MOVEMENT, @"[Turn] Stabalized at ~%d ms (wow delay: %d) with %.3f diff --> %.2f yards.", j*2, [controller refreshDelay], diff, currentDistance * sinf(diff) );
				 break;
				 }
				 }*/
                
                // [playerData setDirectionFacing: newPlayerDirection];
                
                if(fabsf(finalFacing - savedDirection) > M_PI) {
                    if(finalFacing < savedDirection)    finalFacing += (M_PI*2);
                    else                                savedDirection += (M_PI*2);
                }
                float interval = -1*[date timeIntervalSinceNow], turnRad = fabsf(savedDirection - finalFacing);
                if(printTurnInfo) log(LOG_MOVEMENT, @"[Turn] %.3f rad/sec (%.2f/%.2f) at pSpeed %.2f.", turnRad/interval, turnRad, interval, [playerData speed] );
                
            }
        }
		else{
            if ( printTurnInfo ) log(LOG_MOVEMENT, @"DOING SHARP TURN to %.2f", [playerPosition angleTo: position]);
			[self turnTowardPosition: position];
            usleep([controller refreshDelay]*2);
        }
    } else {
        if(printTurnInfo) log(LOG_MOVEMENT, @"Skipping turn because right mouse button is down.");
    }
    
}

#pragma mark Notifications

- (void)reachedFollowUnit: (NSNotification*)notification {

	log(LOG_FUNCTION, @"Reached Follow Unit called in the movementController.");

	// Reset the movement controller.
	[self resetMovementState];

}

- (void)reachedObject: (NSNotification*)notification {
		
	log(LOG_FUNCTION, @"Reached Follow Unit called in the movementController.");
	
	// Reset the movement controller.
	[self resetMovementState];
	
}

- (void)playerHasDied:(NSNotification *)notification {
	if ( !botController.isBotting ) return;

	// reset our movement state!
	[self resetMovementState];

	// If in a BG
	if ( botController.pvpIsInBG ) {
//		self.currentRouteSet = nil;
//		[self resetRoutes];
		log(LOG_MOVEMENT, @"Ignoring corpse route because we're PvPing!");
		return;
	}

	// We're not set to use a route so do nothing
	if ( ![[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"UseRoute"] boolValue] ) return;

	// switch back to starting route?
	if ( [botController.theRouteCollection startRouteOnDeath] ) {

		self.currentRouteKey = CorpseRunRoute;
		self.currentRouteSet = [botController.theRouteCollection startingRoute];
		if ( !self.currentRouteSet ) self.currentRouteSet = [[botController.theRouteCollection routes] objectAtIndex:0];
		self.currentRoute = [self.currentRouteSet routeForKey:CorpseRunRoute];
		log(LOG_MOVEMENT, @"Player Died, switching to main starting route! %@", self.currentRoute);
	}
	// be normal!
	else{
		log(LOG_MOVEMENT, @"Player Died, switching to corpse route");
		self.currentRouteKey = CorpseRunRoute;
		self.currentRoute = [self.currentRouteSet routeForKey:CorpseRunRoute];
	}

	if ( self.currentRoute && [[self.currentRoute waypoints] count] == 0  ){
		log(LOG_MOVEMENT, @"No corpse route! Ending movement");
	}
}

- (void)playerHasRevived:(NSNotification *)notification {
	if ( !botController.isBotting ) return;

	// do nothing if PvPing or in a BG
	if ( botController.pvpIsInBG ) return;

	// We're not set to use a route so do nothing
	if ( ![[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"UseRoute"] boolValue] ) return;

	// reset movement state
	[self resetMovementState];

	if ( self.currentRouteSet ) {
		// switch our route!
		self.currentRouteKey = PrimaryRoute;
		self.currentRoute = [self.currentRouteSet routeForKey:PrimaryRoute];
	}

	log(LOG_MOVEMENT, @"Player revived, switching to %@", self.currentRoute);

}

- (void)applicationWillTerminate:(NSNotification *)notification{
    /*if( [playerData playerIsValid:self] ) {
        [self resetMovementState];
    }*/
}

// have no target
- (void)haveNoTarget: (NSNotification*)notification {
	if ( !botController.isBotting ) return;
	Unit *unit = [notification object];

	log(LOG_DEV, @"[Notification] No Target (movementController): %@", unit);
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(stayWithObject:) object: (WoWObject*)unit];
	// reset movement state
	if ( [self moveToObject] ) [self resetMovementState];
}


// invalid target
- (void)invalidTarget: (NSNotification*)notification {
	if ( !botController.isBotting ) return;
	Unit *unit = [notification object];

	log(LOG_DEV, @"[Notification] No Target (movementController): %@", unit);
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(stayWithObject:) object: (WoWObject*)unit];
	if ( [self moveToObject] ) [self resetMovementState];

}

// not in LoS
- (void)targetNotInLOS: (NSNotification*)notification {
	if ( !botController.isBotting ) return;
	Unit *unit = [notification object];

	log(LOG_DEV, @"[Notification] Not in LoS (movementController): %@", unit);
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(stayWithObject:) object: (WoWObject*)unit];
	if ( [self moveToObject] ) [self resetMovementState];
}

- (void)cantDoThatWhileStunned: (NSNotification*)notification {
	if ( !botController.isBotting ) return;
	Unit *unit = [notification object];

	log(LOG_DEV, @"[Notification] Cant do that while stunned (movementController): %@", unit);
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(stayWithObject:) object: (WoWObject*)unit];
	[self resetMovementState];
}

#pragma mark Keyboard Movements

- (void)moveForwardStart{
    _isMovingFromKeyboard = YES;
	
	log(LOG_MOVEMENT, @"moveForwardStart");
	
    ProcessSerialNumber wowPSN = [controller getWoWProcessSerialNumber];
    CGEventRef wKeyDown = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)kVK_UpArrow, TRUE);
    if(wKeyDown) {
        CGEventPostToPSN(&wowPSN, wKeyDown);
        CFRelease(wKeyDown);
    }
}

- (void)moveForwardStop {
	_isMovingFromKeyboard = NO;
	
	log(LOG_MOVEMENT, @"moveForwardStop");
	
    ProcessSerialNumber wowPSN = [controller getWoWProcessSerialNumber];
    
    // post another key down
    CGEventRef wKeyDown = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)kVK_UpArrow, TRUE);
    if(wKeyDown) {
        CGEventPostToPSN(&wowPSN, wKeyDown);
        CFRelease(wKeyDown);
    }
    
    // then post key up, twice
    CGEventRef wKeyUp = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)kVK_UpArrow, FALSE);
    if(wKeyUp) {
        CGEventPostToPSN(&wowPSN, wKeyUp);
        CGEventPostToPSN(&wowPSN, wKeyUp);
        CFRelease(wKeyUp);
    }
}

- (void)moveBackwardStart {
    _isMovingFromKeyboard = YES;
	
    ProcessSerialNumber wowPSN = [controller getWoWProcessSerialNumber];
    CGEventRef wKeyDown = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)kVK_DownArrow, TRUE);
    if(wKeyDown) {
        CGEventPostToPSN(&wowPSN, wKeyDown);
        CFRelease(wKeyDown);
    }
}

- (void)moveBackwardStop {
    _isMovingFromKeyboard = NO;
	
    ProcessSerialNumber wowPSN = [controller getWoWProcessSerialNumber];
    
    // post another key down
    CGEventRef wKeyDown = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)kVK_DownArrow, TRUE);
    if(wKeyDown) {
        CGEventPostToPSN(&wowPSN, wKeyDown);
        CFRelease(wKeyDown);
    }
    
    // then post key up, twice
    CGEventRef wKeyUp = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)kVK_DownArrow, FALSE);
    if(wKeyUp) {
        CGEventPostToPSN(&wowPSN, wKeyUp);
        CGEventPostToPSN(&wowPSN, wKeyUp);
        CFRelease(wKeyUp);
    }
}

- (void)moveUpStart {
	_isMovingFromKeyboard = YES;
	_movingUp = YES;

    ProcessSerialNumber wowPSN = [controller getWoWProcessSerialNumber];
    CGEventRef wKeyDown = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)kVK_Space, TRUE);
    if(wKeyDown) {
        CGEventPostToPSN(&wowPSN, wKeyDown);
        CFRelease(wKeyDown);
    }
}

- (void)moveUpStop {
	_isMovingFromKeyboard = NO;
	_movingUp = NO;
	
    ProcessSerialNumber wowPSN = [controller getWoWProcessSerialNumber];
    
    // post another key down
    CGEventRef wKeyDown = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)kVK_Space, TRUE);
    if(wKeyDown) {
        CGEventPostToPSN(&wowPSN, wKeyDown);
        CFRelease(wKeyDown);
    }
    
    // then post key up, twice
    CGEventRef wKeyUp = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)kVK_Space, FALSE);
    if(wKeyUp) {
        CGEventPostToPSN(&wowPSN, wKeyUp);
        CGEventPostToPSN(&wowPSN, wKeyUp);
        CFRelease(wKeyUp);
    }
}

- (void)turnLeft: (BOOL)go{
    ProcessSerialNumber wowPSN = [controller getWoWProcessSerialNumber];
    
    if(go) {
        CGEventRef keyStroke = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)kVK_LeftArrow, TRUE);
        if(keyStroke) {
			CGEventPostToPSN(&wowPSN, keyStroke);
            CFRelease(keyStroke);
        }
    } else {
        // post another key down
        CGEventRef keyStroke = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)kVK_LeftArrow, TRUE);
        if(keyStroke) {
            CGEventPostToPSN(&wowPSN, keyStroke);
            CFRelease(keyStroke);
            
            // then post key up, twice
            keyStroke = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)kVK_LeftArrow, FALSE);
            if(keyStroke) {
                CGEventPostToPSN(&wowPSN, keyStroke);
                CGEventPostToPSN(&wowPSN, keyStroke);
                CFRelease(keyStroke);
            }
        }
    }
}

- (void)turnRight: (BOOL)go{
    ProcessSerialNumber wowPSN = [controller getWoWProcessSerialNumber];
    
    if(go) {
        CGEventRef keyStroke = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)kVK_RightArrow, TRUE);
        if(keyStroke) {
            CGEventPostToPSN(&wowPSN, keyStroke);
            CFRelease(keyStroke);
        }
    } else { 
        // post another key down
        CGEventRef keyStroke = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)kVK_RightArrow, TRUE);
        if(keyStroke) {
            CGEventPostToPSN(&wowPSN, keyStroke);
            CFRelease(keyStroke);
        }
        
        // then post key up, twice
        keyStroke = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)kVK_RightArrow, FALSE);
        if(keyStroke) {
            CGEventPostToPSN(&wowPSN, keyStroke);
            CGEventPostToPSN(&wowPSN, keyStroke);
            CFRelease(keyStroke);
        }
    }
}

- (void)strafeRightStart {
/*
	_isMovingFromKeyboard = YES;
	_movingUp = YES;

    ProcessSerialNumber wowPSN = [controller getWoWProcessSerialNumber];
    CGEventRef wKeyDown = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)kVK_Space, TRUE);
    if(wKeyDown) {
        CGEventPostToPSN(&wowPSN, wKeyDown);
        CFRelease(wKeyDown);
    }
*/
}

- (void)strafeRightStop {
/*
	_isMovingFromKeyboard = NO;
	_movingUp = NO;
	
    ProcessSerialNumber wowPSN = [controller getWoWProcessSerialNumber];
    
    // post another key down
    CGEventRef wKeyDown = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)kVK_Space, TRUE);
    if(wKeyDown) {
        CGEventPostToPSN(&wowPSN, wKeyDown);
        CFRelease(wKeyDown);
    }
    
    // then post key up, twice
    CGEventRef wKeyUp = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)kVK_Space, FALSE);
    if(wKeyUp) {
        CGEventPostToPSN(&wowPSN, wKeyUp);
        CGEventPostToPSN(&wowPSN, wKeyUp);
        CFRelease(wKeyUp);
    }
*/
}

- (void)turnTowardObject:(WoWObject*)obj{
	if ( obj ){
		[self turnTowardPosition:[obj position]];
	}
}

- (BOOL)isPatrolling {

	// we have a destination + our movement timer is going!
	if ( self.destinationWaypoint && _movementTimer )
		return YES;

	return NO;
}

- (void)antiAFK{
	
	if ( _afkPressForward ){
		[self moveForwardStop];
		_afkPressForward = NO;
	}
	else{
		[self moveBackwardStop];
		_afkPressForward = YES;
	}
}

- (void)establishPlayerPosition{
		
	if ( _lastCorrectionForward ){
	
		[self backEstablishPosition];
		_lastCorrectionForward = NO;
	}
	else{
		[self establishPosition];
		_lastCorrectionForward = YES;
	}
}

#pragma mark Helpers

- (void)establishPosition {
    [self moveForwardStart];
    usleep(100000);
    [self moveForwardStop];
    usleep(30000);
}

- (void)backEstablishPosition {
    [self moveBackwardStart];
    usleep(100000);
    [self moveBackwardStop];
    usleep(30000);
}

- (void)correctDirectionByTurning {

	if ( _lastCorrectionLeft ){
		log(LOG_MOVEMENT, @"Turning right!");
		[bindingsController executeBindingForKey:BindingTurnRight];
		usleep([controller refreshDelay]);
		[bindingsController executeBindingForKey:BindingTurnLeft];
		_lastCorrectionLeft = NO;
	}
	else{
		log(LOG_MOVEMENT, @"Turning left!");
		[bindingsController executeBindingForKey:BindingTurnLeft];
		usleep([controller refreshDelay]);
		[bindingsController executeBindingForKey:BindingTurnRight];
		_lastCorrectionLeft = YES;
	}
}

- (void)turnTowardPosition: (Position*)position {
	
    BOOL printTurnInfo = NO;
	
	// don't change position if the right mouse button is down
    if ( ((GetCurrentButtonState() & 0x2) != 0x2) ){
		
        Position *playerPosition = [playerData position];
		
		// keyboard turning
        if ( [self movementType] == MovementType_Keyboard ){
			
            // check player facing vs. unit position
            float playerDirection, savedDirection;
            playerDirection = savedDirection = [playerData directionFacing];
            float theAngle = [playerPosition angleTo: position];
			
            if ( fabsf( theAngle - playerDirection ) > M_PI ){
                if ( theAngle < playerDirection )	theAngle += (M_PI*2);
                else								playerDirection += (M_PI*2);
            }
            
            // find the difference between the angles
            float angleTo = (theAngle - playerDirection), absAngleTo = fabsf(angleTo);
            
            // tan(angle) = error / distance; error = distance * tan(angle);
            float speedMax = [playerData speedMax];
            float startDistance = [playerPosition distanceToPosition2D: position];
            float errorLimit = (startDistance < speedMax) ?  1.0f : (1.0f + ((startDistance-speedMax)/12.5f)); // (speedMax/3.0f);
            //([playerData speed] > 0) ? ([playerData speedMax]/4.0f) : ((startDistance < [playerData speedMax]) ? 1.0f : 2.0f);
            float errorStart = (absAngleTo < M_PI_2) ? (startDistance * sinf(absAngleTo)) : INFINITY;
            
            if( errorStart > (errorLimit) ) { // (fabsf(angleTo) > OneDegree*5) 
				
                // compensate for time taken for WoW to process keystrokes.
                // response time is directly proportional to WoW's refresh rate (FPS)
                // 2.25 rad/sec is an approximate turning speed
                float compensationFactor = ([controller refreshDelay]/2000000.0f) * 2.25f;
                
                if(printTurnInfo) log(LOG_MOVEMENT, @"[Turn] ------");
                if(printTurnInfo) log(LOG_MOVEMENT, @"[Turn] %.3f rad turn with %.2f error (lim %.2f) for distance %.2f.", absAngleTo, errorStart, errorLimit, startDistance);
                
                NSDate *date = [NSDate date];
                ( angleTo > 0) ? [self turnLeft: YES] : [self turnRight: YES];
                
                int delayCount = 0;
                float errorPrev = errorStart, errorNow;
                float lastDiff = angleTo, currDiff;
                
                
                while( delayCount < 2500 ) { // && (signbit(lastDiff) == signbit(currDiff))
                    
                    // get current values
                    Position *currPlayerPosition = [playerData position];
                    float currAngle = [currPlayerPosition angleTo: position];
                    float currPlayerDirection = [playerData directionFacing];
                    
                    // correct for looping around the circle
                    if(fabsf(currAngle - currPlayerDirection) > M_PI) {
                        if(currAngle < currPlayerDirection) currAngle += (M_PI*2);
                        else                                currPlayerDirection += (M_PI*2);
                    }
                    currDiff = (currAngle - currPlayerDirection);
                    
                    // get current diff and apply compensation factor
                    float modifiedDiff = fabsf(currDiff);
                    if(modifiedDiff > compensationFactor) modifiedDiff -= compensationFactor;
                    
                    float currentDistance = [currPlayerPosition distanceToPosition2D: position];
                    errorNow = (fabsf(currDiff) < M_PI_2) ? (currentDistance * sinf(modifiedDiff)) : INFINITY;
                    
                    if( (errorNow < errorLimit) ) {
                        if(printTurnInfo) log(LOG_MOVEMENT, @"[Turn] [Range is Good] %.2f < %.2f", errorNow, errorLimit);
                        //log(LOG_MOVEMENT, @"Expected additional movement: %.2f", currentDistance * sinf(0.035*2.25));
                        break;
                    }
                    
                    if( (delayCount > 250) ) {
                        if( (signbit(lastDiff) != signbit(currDiff)) ) {
                            if(printTurnInfo) log(LOG_MOVEMENT, @"[Turn] [Sign Diff] %.3f vs. %.3f (Error: %.2f vs. %.2f)", lastDiff, currDiff, errorNow, errorPrev);
                            break;
                        }
                        if( (errorNow > (errorPrev + errorLimit)) ) {
                            if(printTurnInfo) log(LOG_MOVEMENT, @"[Turn] [Error Growing] %.2f > %.2f", errorNow, errorPrev);
                            break;
                        }
                    }
                    
                    if(errorNow < errorPrev)
                        errorPrev = errorNow;
					
                    lastDiff = currDiff;
                    
                    delayCount++;
                    usleep(1000);
                }
                
                ( angleTo > 0) ? [self turnLeft: NO] : [self turnRight: NO];
                
                float finalFacing = [playerData directionFacing];
				
                /*int j = 0;
				 while(1) {
				 j++;
				 usleep(2000);
				 if(finalFacing != [playerData directionFacing]) {
				 float currentDistance = [[playerData position] distanceToPosition2D: position];
				 float diff = fabsf([playerData directionFacing] - finalFacing);
				 log(LOG_MOVEMENT, @"[Turn] Stabalized at ~%d ms (wow delay: %d) with %.3f diff --> %.2f yards.", j*2, [controller refreshDelay], diff, currentDistance * sinf(diff) );
				 break;
				 }
				 }*/
                
                // [playerData setDirectionFacing: newPlayerDirection];
                
                if(fabsf(finalFacing - savedDirection) > M_PI) {
                    if(finalFacing < savedDirection)    finalFacing += (M_PI*2);
                    else                                savedDirection += (M_PI*2);
                }
                float interval = -1*[date timeIntervalSinceNow], turnRad = fabsf(savedDirection - finalFacing);
                if(printTurnInfo) log(LOG_MOVEMENT, @"[Turn] %.3f rad/sec (%.2f/%.2f) at pSpeed %.2f.", turnRad/interval, turnRad, interval, [playerData speed] );
            }
			
		// mouse movement or CTM
        }
		else{

			// what are we facing now?
			float playerDirection = [playerData directionFacing];
			float theAngle = [playerPosition angleTo: position];

			log(LOG_MOVEMENT, @"%0.2f %0.2f Difference: %0.2f > %0.2f", playerDirection, theAngle, fabsf( theAngle - playerDirection ), M_PI);

			// face the other location!
			[playerData faceToward: position];

			// compensate for the 2pi --> 0 crossover
			if ( fabsf( theAngle - playerDirection ) > M_PI ) {
				if(theAngle < playerDirection)  theAngle        += (M_PI*2);
				else                            playerDirection += (M_PI*2);
			}

			// find the difference between the angles
			float angleTo = fabsf(theAngle - playerDirection);

			// if the difference is more than 90 degrees (pi/2) M_PI_2, reposition
			if( (angleTo > 0.785f) ) {  // changed to be ~45 degrees
				[self correctDirectionByTurning];
//				[self establishPlayerPosition];
			}
			
			if ( printTurnInfo ) log(LOG_MOVEMENT, @"Doing sharp turn to %.2f", theAngle );

            usleep( [controller refreshDelay] *2 );
        }
    }
	else {
        if(printTurnInfo) log(LOG_MOVEMENT, @"Skipping turn because right mouse button is down.");
    }
}

#pragma mark Click To Move

- (void)setClickToMove:(Position*)position andType:(UInt32)type andGUID:(UInt64)guid{
	
	MemoryAccess *memory = [controller wowMemoryAccess];
	if ( !memory ){
		return;
	}
	
	// Set our position!
	if ( position != nil ){
		float pos[3] = {0.0f, 0.0f, 0.0f};
		pos[0] = [position xPosition];
		pos[1] = [position yPosition];
		pos[2] = [position zPosition];
		[memory saveDataForAddress: [offsetController offset:@"CTM_POS"] Buffer: (Byte *)&pos BufLength: sizeof(float)*3];
	}
	
	// Set the GUID of who to interact with!
	if ( guid > 0 ){
		[memory saveDataForAddress: [offsetController offset:@"CTM_GUID"] Buffer: (Byte *)&guid BufLength: sizeof(guid)];
	}
	
	// Set our scale!
	float scale = 13.962634f;
	[memory saveDataForAddress: [offsetController offset:@"CTM_SCALE"] Buffer: (Byte *)&scale BufLength: sizeof(scale)];
	
	// Set our distance to the target until we stop moving
	float distance = 0.5f;	// Default for just move to position
	if ( type == ctmAttackGuid ){
		distance = 3.66f;
	}
	else if ( type == ctmInteractNpc ){
		distance = 2.75f;
	}
	else if ( type == ctmInteractObject ){
		distance = 4.5f;
	}
	[memory saveDataForAddress: [offsetController offset:@"CTM_DISTANCE"] Buffer: (Byte *)&distance BufLength: sizeof(distance)];
	
	// take action!
	[memory saveDataForAddress: [offsetController offset:@"CTM_ACTION"] Buffer: (Byte *)&type BufLength: sizeof(type)];
}

- (BOOL)isCTMActive{
	UInt32 value = 0;
    [[controller wowMemoryAccess] loadDataForObject: self atAddress: [offsetController offset:@"CTM_ACTION"] Buffer: (Byte*)&value BufLength: sizeof(value)];
    return ((value == ctmWalkTo) || (value == ctmLoot) || (value == ctmInteractNpc) || (value == ctmInteractObject));
}

#pragma mark Miscellaneous

- (BOOL)dismount{
	
	// do they have a standard mount?
	UInt32 mountID = [[playerData player] mountID];
	
	// check for druids
	if ( mountID == 0 ){
		
		// swift flight form
		if ( [auraController unit: [playerData player] hasAuraNamed: @"Swift Flight Form"] ){
			[macroController useMacroOrSendCmd:@"CancelSwiftFlightForm"];
			return YES;
		}
		
		// flight form
		else if ( [auraController unit: [playerData player] hasAuraNamed: @"Flight Form"] ){
			[macroController useMacroOrSendCmd:@"CancelFlightForm"];
			return YES;
		}
	}
	
	// normal mount
	else{
		[macroController useMacroOrSendCmd:@"Dismount"];
		return YES;
	}
	
	// just in case people have problems, we'll print something to their log file
	if ( ![[playerData player] isOnGround] ) {
		log(LOG_MOVEMENT, @"[Movement] Unable to dismount player! In theory we should never be here! Mount ID: %d", mountID);
    }
	
	return NO;	
}

- (void)jump{

	// If we're air mounted and not on the ground then let's not jump
	if ([[playerData player] isFlyingMounted] && ![[playerData player] isOnGround] ) return;
	
	log(LOG_MOVEMENT, @"Jumping!");
    // correct direction
    [self correctDirection: NO];
    
    // update variables
    self.lastJumpTime = [NSDate date];
    int min = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"MovementMinJumpTime"] intValue];
    int max = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"MovementMaxJumpTime"] intValue];
    self.jumpCooldown = SSRandomIntBetween(min, max);

	[self moveUpStart];
    usleep(5000);
    [self moveUpStop];
//    usleep(30000);
}

- (void)jumpRaw {

	// If we're air mounted and not on the ground then let's not jump
	if ( [[playerData player] isFlyingMounted] && ![[playerData player] isOnGround] ) return;

	log(LOG_MOVEMENT, @"Jumping!");
	[self moveUpStart];
	[self performSelector:@selector(moveUpStop) withObject:nil afterDelay:0.05f];
}

- (void)raiseUpAfterAirMount {
	
	log(LOG_MOVEMENT, @"Raising up!");
	[self moveUpStart];
	[self performSelector:@selector(moveUpStop) withObject:nil afterDelay:0.2f];
}

- (BOOL)jumpTowardsPosition: (Position*)position {
	log(LOG_MOVEMENT, @"Jumping towards position.");

	if ( [self isMoving] ) {
		BOOL wasActive = NO;
		if ( _isActive == YES ) wasActive = YES;
		[self stopMovement];
		if ( wasActive == YES ) _isActive = YES;
	}

	// Face the target
	[self turnTowardPosition: position];
	usleep( [controller refreshDelay]*2 );
	[self establishPosition];

	// Move forward
	[self moveForwardStart];
	usleep( [controller refreshDelay]*2 );

	// Jump
	[self jumpRaw];
	sleep(1);

	// Stop
	[self moveForwardStop];

	return YES;
}

- (BOOL)jumpForward {
	log(LOG_MOVEMENT, @"Jumping forward.");
	
	// Move backward
	[self moveForwardStart];
	usleep(100000);
	
	// Jump
	[self jumpRaw];
	
	// Stop
	[self moveForwardStop];
	usleep([controller refreshDelay]*2);
	
	return YES;
	
}

- (BOOL)jumpBack {
	log(LOG_MOVEMENT, @"Jumping back.");
	
	// Move backward
	[self moveBackwardStart];
	usleep(100000);
	
	// Jump
	[self jumpRaw];

	// Stop
	[self moveBackwardStop];
	usleep([controller refreshDelay]*2);
	
	return YES;
	
}

#pragma mark Waypoint Actions

#define INTERACT_RANGE		8.0f

- (void)performActions:(NSDictionary*)dict{
	
	// player cast?  try again shortly
	if ( [playerData isCasting] ) {
		_performingActions = NO;
		float delayTime = [playerData castTimeRemaining];
        if ( delayTime < 0.2f) delayTime = 0.2f;
        log(LOG_WAYPOINT, @"Player casting. Waiting %.2f to perform next action.", delayTime);

        [self performSelector: _cmd
                   withObject: dict 
                   afterDelay: delayTime];

		return;
	}

	// If we're being called after delaying lets cancel the evaluations we started
	if ( _performingActions ) {
		[botController cancelCurrentEvaluation];
		_performingActions = NO;
	}

	int actionToExecute = [[dict objectForKey:@"CurrentAction"] intValue];
	NSArray *actions = [dict objectForKey:@"Actions"];
	float delay = 0.0f;

	// are we done?
	if ( actionToExecute >= [actions count] ){
		log(LOG_WAYPOINT, @"Action complete, resuming route");
		[self realMoveToNextWaypoint];
		return;
	}

	// execute our action
	else {

		log(LOG_WAYPOINT, @"Executing action %d", actionToExecute);

		Action *action = [actions objectAtIndex:actionToExecute];

		// spell
		if ( [action type] == ActionType_Spell ){
			
			UInt32 spell = [[[action value] objectForKey:@"SpellID"] unsignedIntValue];
			BOOL instant = [[[action value] objectForKey:@"Instant"] boolValue];
			log(LOG_WAYPOINT, @"Casting spell %d", spell);

			// only pause movement if we have to!
			if ( !instant ) [self stopMovement];
			_isActive = YES;

			[botController performAction:spell];
		}
		
		// item
		else if ( [action type] == ActionType_Item ){
			
			UInt32 itemID = [[[action value] objectForKey:@"ItemID"] unsignedIntValue];
			BOOL instant = [[[action value] objectForKey:@"Instant"] boolValue];
			UInt32 actionID = (USE_ITEM_MASK + itemID);
			
			log(LOG_WAYPOINT, @"Using item %d", itemID);
			
			// only pause movement if we have to!
			if ( !instant )	[self stopMovement];
			_isActive = YES;

			[botController performAction:actionID];
		}

		// macro
		else if ( [action type] == ActionType_Macro ) {

			UInt32 macroID = [[[action value] objectForKey:@"MacroID"] unsignedIntValue];
			BOOL instant = [[[action value] objectForKey:@"Instant"] boolValue];
			UInt32 actionID = (USE_MACRO_MASK + macroID);
			
			log(LOG_WAYPOINT, @"Using macro %d", macroID);
			
			// only pause movement if we have to!
			if ( !instant )
				[self stopMovement];
			_isActive = YES;

			[botController performAction:actionID];
		}
		
		// delay
		else if ( [action type] == ActionType_Delay ){
			
			delay = [[action value] floatValue];
			
			[self stopMovement];
			_isActive = YES;
			log(LOG_WAYPOINT, @"Delaying for %0.2f seconds", delay);
		}
		
		// jump
		else if ( [action type] == ActionType_Jump ){
			
			[self jumpRaw];
			
		}
		
		// switch route
		else if ( [action type] == ActionType_SwitchRoute ){
			
			RouteSet *route = nil;
			NSString *UUID = [action value];
			for ( RouteSet *otherRoute in [waypointController routes] ){
				if ( [UUID isEqualToString:[otherRoute UUID]] ){
					route = otherRoute;
					break;
				}
			}
			
			if ( route == nil ){
				log(LOG_WAYPOINT, @"Unable to find route %@ to switch to!", UUID);
				
			}
			else{
				log(LOG_WAYPOINT, @"Switching route to %@ with %d waypoints", route, [[route routeForKey: PrimaryRoute] waypointCount]);
				
				// switch the botController's route!
//				[botController setTheRouteSet:route];
				
				[self setPatrolRouteSet:route];
				
				[self resumeMovement];
				
				// after we switch routes, we don't want to continue any other actions!
				return;
			}
		}
	
		else if ( [action type] == ActionType_QuestGrab || [action type] == ActionType_QuestTurnIn ){
	
			// reset mob counts
			if ( [action type] == ActionType_QuestTurnIn ){
				[statisticsController resetQuestMobCount];
			}
			
			// get all nearby mobs
			NSArray *nearbyMobs = [mobController mobsWithinDistance:INTERACT_RANGE levelRange:NSMakeRange(0,255) includeElite:YES includeFriendly:YES includeNeutral:YES includeHostile:NO];				
			Mob *questNPC = nil;
			for ( questNPC in nearbyMobs ){
				
				if ( [questNPC isQuestGiver] ){
					
					[self stopMovement];
					_isActive = YES;

					// might want to make k 3 (but will take longer)
					
					log(LOG_WAYPOINT, @"Turning in/grabbing quests to/from %@", questNPC);
					
					int i = 0, k = 1;
					for ( ; i < 3; i++ ){
						for ( k = 1; k < 5; k++ ){
							
							// interact
							if ( [botController interactWithMouseoverGUID:[questNPC GUID]] ){
								usleep(300000);
								
								// click the gossip button
								[macroController useMacroWithKey:@"QuestClickGossip" andInt:k];
								usleep(10000);
								
								// click "continue" (not all quests need this)
								[macroController useMacro:@"QuestContinue"];
								usleep(10000);
								
								// click "Accept" (this is ONLY needed if we're accepting a quest)
								[macroController useMacro:@"QuestAccept"];
								usleep(10000);
								
								// click "complete quest"
								[macroController useMacro:@"QuestComplete"];
								usleep(10000);
								
								// click "cancel" (sometimes we have to in case we just went into a quest we already have!)
								[macroController useMacro:@"QuestCancel"];
								usleep(10000);
							}
						}
					}
				}
			}
		}
		
		// interact with NPC
		else if ( [action type] == ActionType_InteractNPC ){
			
			NSNumber *entryID = [action value];
			log(LOG_WAYPOINT, @"Interacting with mob %@", entryID);
			
			// moving bad, lets pause!
			[self stopMovement];
			_isActive = YES;

			// interact
			[botController interactWithMob:[entryID unsignedIntValue]];
		}

		// interact with object
		else if ( [action type] == ActionType_InteractObject ) {

			NSNumber *entryID = [action value];
			log(LOG_WAYPOINT, @"Interacting with node %@", entryID);

			// moving bad, lets pause!
			[self stopMovement];
			_isActive = YES;

			// interact
			[botController interactWithNode:[entryID unsignedIntValue]];
		}

		// repair
		else if ( [action type] == ActionType_Repair ) {

			// get all nearby mobs
			NSArray *nearbyMobs = [mobController mobsWithinDistance:INTERACT_RANGE levelRange:NSMakeRange(0,255) includeElite:YES includeFriendly:YES includeNeutral:YES includeHostile:NO];
			Mob *repairNPC = nil;
			for ( repairNPC in nearbyMobs ) {
				if ( [repairNPC canRepair] ) {
					log(LOG_WAYPOINT, @"Repairing with %@", repairNPC);
					break;
				}
			}

			// repair
			if ( repairNPC ) {
				[self stopMovement];
				_isActive = YES;

				if ( [botController interactWithMouseoverGUID:[repairNPC GUID]] ){
					
					// sleep some to allow the window to open!
					usleep(500000);
					
					// now send the repair macro
					[macroController useMacro:@"RepairAll"];	
					
					log(LOG_WAYPOINT, @"All items repaired");
				}
			}
			else{
				log(LOG_WAYPOINT, @"Unable to repair, no repair NPC found!");
			}
		}

		// switch combat profile
		else if ( [action type] == ActionType_CombatProfile ) {
			log(LOG_WAYPOINT, @"Switching from combat profile %@", botController.theCombatProfile);

			CombatProfile *profile = nil;
			NSString *UUID = [action value];
			for ( CombatProfile *otherProfile in [profileController combatProfiles] ){
				if ( [UUID isEqualToString:[otherProfile UUID]] ) {
					profile = otherProfile;
					break;
				}
			}

			[botController changeCombatProfile:profile];
		}

		// jump to waypoint
		else if ( [action type] == ActionType_JumpToWaypoint ) {

			int waypointIndex = [[action value] intValue] - 1;
			NSArray *waypoints = [self.currentRoute waypoints];

			if ( waypointIndex >= 0 && waypointIndex < [waypoints count] ){
				self.destinationWaypoint = [waypoints objectAtIndex:waypointIndex];
				log(LOG_WAYPOINT, @"Jumping to waypoint %@", self.destinationWaypoint);
				[self resumeMovement];
			}
			else{
				log(LOG_WAYPOINT, @"Error, unable to move to waypoint index %d, out of range!", waypointIndex);
			}
		}
		
		// mail
		else if ( [action type] == ActionType_Mail ){

			MailActionProfile *profile = (MailActionProfile*)[profileController profileForUUID:[action value]];
			log(LOG_WAYPOINT, @"Initiating mailing profile: %@", profile);
			[itemController mailItemsWithProfile:profile];
		}

	}

	log(LOG_WAYPOINT, @"Action %d complete, checking for more!", actionToExecute);

	if (delay > 0.0f) {
		_performingActions = YES;
		[botController performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.25f];
		// Lets run evaluation while we're waiting, it will not move while performingActions
		[self performSelector: _cmd
			   withObject: [NSDictionary dictionaryWithObjectsAndKeys:
							actions,									@"Actions",
							[NSNumber numberWithInt:++actionToExecute],	@"CurrentAction",
							nil]
				afterDelay: delay];
	} else {
		[self performSelector: _cmd
				   withObject: [NSDictionary dictionaryWithObjectsAndKeys:
								actions,									@"Actions",
								[NSNumber numberWithInt:++actionToExecute],	@"CurrentAction",
								nil]
				   afterDelay: 0.25f];
		
	}
}

#pragma mark Temporary

- (float)averageSpeed{
	return 0.0f;
}
- (float)averageDistance{
	return 0.0f;
}
- (BOOL)shouldJump{
	return NO;
}

@end
