//
//  FishController.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 12/23/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import "FishController.h"
#import "Controller.h"
#import "NodeController.h"
#import "PlayerDataController.h"
#import "BotController.h"
#import "InventoryController.h"
#import "LootController.h"
#import "SpellController.h"
#import "ActionMenusController.h"
#import "MovementController.h"

#import "Offsets.h"
#import "Errors.h"

#import "Node.h"
#import "Position.h"
#import "MemoryAccess.h"
#import "Player.h"
#import "Item.h"
#import "Spell.h"

#import "PTHeader.h"

#import <ShortcutRecorder/ShortcutRecorder.h>
#import <ScreenSaver/ScreenSaver.h>

#define ITEM_REINFORCED_CRATE	44475

#define OFFSET_MOVED			0xCC		// When this is 1 the bobber has moved!  Offset from the base address
#define OFFSET_STATUS			0xCE		// This is 132 when the bobber is normal, shortly after it moves it's 148, then finally finishes at 133 (is it animation state?)
#define STATUS_NORMAL		132
#define OFFSET_VISIBILITY		0xD8		// Set this to 0 to hide the bobber!

// TO DO:
//	Log out on full inventory
//  Add a check for hostile players near you
//  Add a check for friendly players near you (and whisper check?)
//  Check for GMs?
//	Add a check for the following items: "Reinforced Crate", "Borean Leather Scraps", then /use them :-)
//  Select a route to run back in case you are killed (add a delay until res option as well?)
//  /use Bloated Mud Snapper
//  Recast if didn't land near the school?
//  new bobber detection method?  fire event when it's found?  Can check for invalid by firing off [node validToLoot]
//  turn on keyboard turning if we're facing a node?
//  make sure user has bobbers in inventory
//  closing wow will crash PG - fix this

@interface FishController (Internal)
- (void)stopFishing;
- (void)fishCast;
- (BOOL)applyLure;
- (void)monitorBobber:(Node*)bobber;
- (BOOL)isPlayerFishing;
- (void)facePool:(Node*)school;
- (void)verifyLoot;
@end


@implementation FishController

- (id)init{
    self = [super init];
    if (self != nil) {
		_isFishing = NO;
		_totalFishLooted = 0;
		_ignoreIsFishing = NO;
		//_blockActions = NO;
		_lootAttempt = 0;
		
		_nearbySchool = nil;	
		_facedSchool = [[NSMutableArray array] retain];
		_castStartTime = nil;		
		
		[[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(fishLooted:) 
                                                     name: ItemLootedNotification 
                                                   object: nil];
        [[NSNotificationCenter defaultCenter] addObserver: self 
												 selector: @selector(playerHasDied:) 
													 name: PlayerHasDiedNotification 
												   object: nil];
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(playerIsInvalid:) 
                                                     name: PlayerIsInvalidNotification 
                                                   object: nil];
    }
    return self;
}

- (void) dealloc
{
	[_facedSchool release];
    [super dealloc];
}

@synthesize isFishing = _isFishing;


/*
 _doFishing				= [fishingCheckbox state];
 _fishingGatherDistance	= [fishingGatherDistanceText floatValue];
 _fishingApplyLure		= [fishingApplyLureCheckbox state];
 _fishingOnlySchools		= [fishingOnlySchoolsCheckbox state];
 _fishingRecast			= [fishingRecastCheckbox state];
 _fishingUseContainers	= [fishingUseContainersCheckbox state];
 _fishingHideBobbers		= [fishingHideBobbersCheckbox state];
 _fishingLureSpellID		= [fishingLurePopUpButton selectedTag];*/

- (void)fish: (BOOL)optApplyLure 
  withRecast:(BOOL)optRecast 
	 withUse:(BOOL)optUseContainers 
	withLure:(int)optLureID
  withSchool:(Node*)nearbySchool
{
	
	log(LOG_DEV, @"[Fishing] Fishing...");
	
	if ( nearbySchool && [nearbySchool isValid] ){
		[self facePool:nearbySchool];
	}
	
	// Reload spells, since they may have just trained fishing!
	[spellController reloadPlayerSpells];
	
	// Get our fishing spell ID!
	Spell *fishingSpell = [spellController playerSpellForName: @"Fishing"];
	if ( fishingSpell ){
		_fishingSpellID = [[fishingSpell ID] intValue];
		
	}
	else{
		[controller setCurrentStatus:@"Bot: You need to learn fishing!"];
		return;
	}
	
	// set options
	_optApplyLure			= optApplyLure;
	_optUseContainers		= optUseContainers;
	_optRecast				= optRecast;
	_optLureItemID			= optLureID;
	_nearbySchool			= [nearbySchool retain];
	
	_isFishing = YES;
	
	// Reset our fishing variables!
	_applyLureAttempts	= 0;
	_ignoreIsFishing	= NO;
	_castNumber			= 0;
	_totalFishLooted	= 0;
	_playerGUID			= [[playerController player] GUID];
	
	// are we on the ground? if not lets delay our cast a bit
	if ( ![[playerController player] isOnGround] ){
		log(LOG_FISHING, @"Falling, fishing soon...");
		[self performSelector:@selector(fishCast) withObject:nil afterDelay:2.0f];
	}
	// start fishing if we're on the ground
	else{
		log(LOG_DEV, @"[Fishing] On ground, fishing!");
		[self fishCast];
	}
}

- (void)stopFishing{
	_isFishing = NO;
	
	[_nearbySchool release]; _nearbySchool = nil;
}

- (void)fishCast{
	
	if ( !_isFishing || ![botController isBotting] ){
		return;
	}
	
	// loot window open?  check again shortly
	if ( [lootController isLootWindowOpen] ){
		log(LOG_FISHING, @"Loot window is open! Attempting to loot");
		
		// cancel previous requests if any
		[NSObject cancelPreviousPerformRequestsWithTarget: self];
		
		// need to loot soon?
		_lootAttempt = 0;
		[self verifyLoot];
		
		return;
	}
	
	// school is gone!
	if ( _nearbySchool && ![_nearbySchool isValid] ){
		
		[self stopFishing];
		
		log(LOG_FISHING, @"[Eval] Fishing - school gone");
		[botController evaluateSituation];
		return;
	}
	
	// use containers?
	if ( _optUseContainers ){
		
		Item *item = [itemController itemForID:[NSNumber numberWithInt:ITEM_REINFORCED_CRATE]]; 
		
		if ( item && [itemController collectiveCountForItem:item] > 0 ){
			// Use our crate!
			[botController performAction:(USE_ITEM_MASK + ITEM_REINFORCED_CRATE)];
			
			// Wait a bit so we can loot it!
			usleep([controller refreshDelay]*2);
		}
	}
	
	// Lets apply some lure if we need to!
	[self applyLure];
	
	// We don't want to start fishing if we already are!
	if ( ![playerController isCasting] || _ignoreIsFishing ){
		
		// Reset this!  We only want this to be YES when we have to re-cast b/c we're not close to a school!
		_ignoreIsFishing = NO;
		
		// Time to fish!
		[botController performAction: _fishingSpellID];
		_castStartTime = [[NSDate date] retain];
		[controller setCurrentStatus: @"Bot: Fishing"];
		log(LOG_FISHING, @"Casting!");
		
		// find out bobber so we can monitor it!
		[self performSelector:@selector(findBobber) withObject:nil afterDelay:2.0f];
		
		_castNumber++;
	}
	else{
		if ( ![playerController isCasting] ) log(LOG_FISHING, @"Cast attempted failed. Trying again in 2 seconds...");
		// try again soon?
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:_cmd object:nil];
		[self performSelector:@selector(fishCast) withObject:nil afterDelay:2.0f];
	}
}

- (BOOL)applyLure{
	
	NSLog(@"applying lure? %d", _optApplyLure);
	if ( !_optApplyLure ){
		return NO;
	}
	
	// check to see if we even have any of the lure in our bags
	NSArray *itemsInInventory = [itemController itemsInBags];
	BOOL foundLure = NO;
	for ( Item *item in itemsInInventory ){
		if ( [item entryID] == _optLureItemID ){
			foundLure = YES;
			break;
		}
	}
	
	NSLog(@"Do we have any? %d", foundLure);
	
	// lure still in bags or we're using the hat!
	if ( foundLure || _optLureItemID == 33820 ){
		
		Item *item = [itemController itemForGUID: [[playerController player] itemGUIDinSlot: SLOT_MAIN_HAND]];
		if ( ![item hasTempEnchantment] && _applyLureAttempts < 3 ){
			
			log(LOG_DEV, @"[Fishing] Using lure: %d on item %d", _optLureItemID, [item entryID]);
			
			// Lets actually use the item we want to apply!
			[botController performAction:(USE_ITEM_MASK + _optLureItemID)];
			
			// Wait a bit before we cast the next one!
			usleep([controller refreshDelay]*2);
			
			// don't need to use the pole if we're casting a spell!
			if ( _optLureItemID != 33820 ){
				// Now use our fishing pole so it's applied!
				[botController performAction:(USE_ITEM_MASK + [item entryID])];
			
				// we may need this?
				usleep([controller refreshDelay]);
			}
			
			// Are we casting the lure on our fishing pole?
			if ( [playerController spellCasting] > 0 && ![self isPlayerFishing] ){
				_applyLureAttempts = 0;
				
				log(LOG_FISHING, @"Applying lure");
				
				// This will "pause" our main thread until this is complete!
				usleep(3500000);
			}
			else{
				log(LOG_FISHING, @"Lure application failed!");
				_applyLureAttempts++;
			}
			
			return YES;
		}
	}
	else{
		log(LOG_FISHING, @"Player is out of lures, not applying...");
	}
	
	return NO;
}

- (void)facePool:(Node*)school{
	// turn toward
	if ( ![_facedSchool containsObject:school] ){
		log(LOG_FISHING, @"Turning toward %@", school);
		[movementController turnTowardObject:school];
	}
	
	[_facedSchool addObject:[school retain]];	
}

// simply searches for our player's bobber
- (void)findBobber{
	if ( !_isFishing || ![botController isBotting] )
		return;
	
	MemoryAccess *memory = [controller  wowMemoryAccess];
	if ( !memory )
		return;
	
	UInt16 status = 0;
	for ( Node *bobber in [nodeController nodesOfType:GAMEOBJECT_TYPE_FISHING_BOBBER shouldLock:YES] ){
		
		// if we don't do this check we could find an old node (i believe status is animation state, not sure)
		if ( [memory loadDataForObject: self atAddress: ([bobber baseAddress] + OFFSET_STATUS) Buffer: (Byte *)&status BufLength: sizeof(status)] ){
			
			// bobber found! we're done
			if ( [bobber owner] == _playerGUID ){
				
				// Is our bobber normal yet?
				if ( status == STATUS_NORMAL ){
					
					log(LOG_FISHING, @"Bobber found, monitoring");
					[self monitorBobber:[bobber retain]];
					return;
				}
			}
		}
	}
	
	// only keep looking if we're fishing
	if ( [self isPlayerFishing] ){
		log(LOG_FISHING, @"Bobber, not found, searching again...");
		[self performSelector:@selector(findBobber) withObject:nil afterDelay:0.1f];
	}
	else{
		log(LOG_FISHING, @"No longer fishing, bobber scan stopped");
		
		// fish again!
		_ignoreIsFishing = YES;
		[self fishCast];
	}
}

// monitors our bobber + clicks as needed
- (void)monitorBobber:(Node*)bobber{
	if ( !_isFishing || ![botController isBotting] )
		return;
	
	MemoryAccess *memory = [controller  wowMemoryAccess];
	if ( !memory )
		return;
	
	// verify our bobber is still good!
	if ( !bobber || ![bobber isValid] ){
		log(LOG_FISHING, @"Our bobber is invalid :(");
		
		// make sure we don't try to watch this node next
		//[nodeController finishedNode:bobber];
		
		// fish again
		_ignoreIsFishing = YES;		// probably not necessary, but just in case it goes invalid while we're casting (probably not possible)?
		[self fishCast];
		
		return;
	}
	
	// do we have to make sure it landed in a pool
	if ( _optRecast && _nearbySchool ){
		float distance = [[bobber position] distanceToPosition: [_nearbySchool position]];
		
		// Fish again! Didn't land in the school!
		if ( distance > 2.6f ){
			_ignoreIsFishing = YES;
			
			[self fishCast];
			return;
		}
	}
	
	// check to see if it's bouncing
	UInt16 bouncing=0;
	if ( [memory loadDataForObject: self atAddress: ([bobber baseAddress] + OFFSET_MOVED) Buffer: (Byte *)&bouncing BufLength: sizeof(bouncing)] ){
		
		log(LOG_DEV, @"[Fishing] Bobber Bouncing: %d", bouncing);
		if (bouncing) log(LOG_FISHING, @"The bobber is Bouncing!");
		
		// it's bouncing!
		if ( bouncing ){
			
			// click our bobber!
			[botController interactWithMouseoverGUID: [bobber GUID]];
			
			
			// TO DO: replace finished??
			// make sure we don't try to watch this node next
			//[nodeController finishedNode:bobber];
			
			// make sure the fish was looted!
			_lootAttempt = 0;
			[self performSelector:@selector(verifyLoot) withObject:nil afterDelay:0.3f];
			
			return;
		}
	}
	
	// another check to make sure the bobber is still valid (i believe status is animation state)
	UInt16 status=0;
	if ( [memory loadDataForObject: self atAddress: ([bobber baseAddress] + OFFSET_STATUS) Buffer: (Byte *)&status BufLength: sizeof(status)] ){
		
		// bobber is no longer valid :/ (player could move or stop casting)
		if ( status != STATUS_NORMAL ){
			log(LOG_FISHING, @"Bobber invalid, re-casting");
			_ignoreIsFishing = YES;
			
			[self fishCast];
			return;
		}
	}
	
	[self performSelector:@selector(monitorBobber:) withObject:bobber afterDelay:0.1f];
}

- (BOOL)isPlayerFishing{
	return ([playerController spellCasting] == _fishingSpellID);
}

- (void)verifyLoot{
	
	if ( !_isFishing )
		return;
	
	// Sometimes the loot window sticks, i hate it, lets add a fix!
	if ( [lootController isLootWindowOpen] ){
		
		_lootAttempt++;
		
		// Loot window has been open too long lets accept it!
		if ( _lootAttempt > 10 ){
			[lootController acceptLoot];
		}
		
		log(LOG_DEV, @"Verifying loot attempt %d", _lootAttempt);
		
		[self performSelector:@selector(verifyLoot) withObject:nil afterDelay:0.1f];
	}
	
	// just in case the item notification doesn't fire off
	else{
		log(LOG_DEV, @"Attempting to cast in 3.0 seconds");
		[self performSelector:@selector(fishCast) withObject:nil afterDelay:3.0f];
	}
}


#pragma mark Notifications

// Called whenever ANY item is looted
- (void)fishLooted: (NSNotification*)notification {
	
	if ( !_isFishing )
		return;
	
	_totalFishLooted++;
	
	NSDate *currentTime = [NSDate date];
	log(LOG_FISHING, @"Fish looted after %0.2f seconds.", [currentTime timeIntervalSinceDate: _castStartTime]);
	
	[self performSelector:@selector(fishCast) withObject:nil afterDelay:0.1f];
}

- (void)playerHasDied: (NSNotification*)not { 
	if ( _isFishing ){
		[self stopFishing];
	}
}

- (void)playerIsInvalid: (NSNotification*)not {
    if( _isFishing ) {
        [self stopFishing];
    }
}

/*- (void)joinWG{
 
 if ( !_isFishing ){
 return;
 }
 
 // If we have this enabled!
 if ( 1 == 0 ){
 // The data structure CGPoint represents a point in a two-dimensional
 // coordinate system.  Here, X and Y distance from upper left, in pixels.
 //
 CGPoint pt;
 CGRect wowSize = [controller wowWindowRect];
 
 // Constants - ZOMG SO COMPLICATED TEH MATHSZ
 float yUpperConst = .2238;
 float yLowerConst = .238443;
 float xLeftConst = .40456;
 float xRightConst = .4936;
 
 float yPosToClick = wowSize.origin.y + ( ((wowSize.size.height * yUpperConst) + (wowSize.size.height * yLowerConst)) / 2 );
 float xPosToClick = wowSize.origin.x + ( ((wowSize.size.width * xLeftConst) + (wowSize.size.width * xRightConst)) / 2 );
 pt.y = yPosToClick;
 pt.x = xPosToClick;
 
 
 log(LOG_FISHING, @"Origin: {%0.2f, %0.2f} Dimensions: {%0.2f, %0.2f}", wowSize.origin.x, wowSize.origin.y, wowSize.size.width, wowSize.size.height);
 
 log(LOG_FISHING, @"Clicking {%0.2f, %0.2f}", xPosToClick, yPosToClick);
 
 if ( ![controller isWoWFront] ){
 [controller makeWoWFront];
 usleep(10000);
 }
 
 
 // This is where the magic happens.  See CGRemoteOperation.h for details.
 //
 // CGPostMouseEvent( CGPoint        mouseCursorPosition,
 //                   boolean_t      updateMouseCursorPosition,
 //                   CGButtonCount  buttonCount,
 //                   boolean_t      mouseButtonDown, ... )
 //
 // So, we feed coordinates to CGPostMouseEvent, put the mouse there,
 // then click and release.
 //
 
 if( pt.x && pt.y && [controller isWoWFront] ){
 
 CGInhibitLocalEvents(YES);
 
 CGPostMouseEvent( pt, TRUE, 1, TRUE );
 
 // Click a few times just to be safe!
 int i = 0;
 for ( i = 0; i < 5; i++ ){
 usleep(100000);
 CGPostMouseEvent( pt, TRUE, 1, FALSE );
 }
 
 CGInhibitLocalEvents(NO);
 }
 
 
 // right click on the loot point to skin
 BOOL weSkinned = NO;
 if(clickPt.x && clickPt.y && [controller isWoWFront]) {
 // move the mouse into position and click
 weSkinned = YES;
 CGInhibitLocalEvents(YES);
 CGPostMouseEvent(clickPt, FALSE, 2, FALSE, FALSE);
 PostMouseEvent(kCGEventMouseMoved, kCGMouseButtonLeft, clickPt, wowProcess);
 usleep(100000);	// wait
 PostMouseEvent(kCGEventRightMouseDown, kCGMouseButtonRight, clickPt, wowProcess);
 usleep(30000);
 PostMouseEvent(kCGEventRightMouseUp, kCGMouseButtonRight, clickPt, wowProcess);
 usleep(100000);	// wait
 CGInhibitLocalEvents(NO);
 }
 
 
 }
 }*/

- (Node*)nearbySchool{
	return [[_nearbySchool retain] autorelease];
}

@end
