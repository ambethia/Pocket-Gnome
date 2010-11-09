//
//  FishController.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 12/23/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SRRecorderControl;

@class Controller;
@class NodeController;
@class PlayerDataController;
@class MemoryAccess;
@class ChatController;
@class BotController;
@class InventoryController;
@class MemoryViewController;
@class LootController;
@class SpellController;
@class MovementController;

@class PTHotKey;

@class Node;

@interface FishController : NSObject {
    IBOutlet Controller             *controller;
	IBOutlet NodeController			*nodeController;
	IBOutlet PlayerDataController	*playerController;
	IBOutlet BotController			*botController;
    IBOutlet InventoryController    *itemController;
	IBOutlet LootController			*lootController;
	IBOutlet SpellController		*spellController;
	IBOutlet MovementController		*movementController;
	
	BOOL _optApplyLure;
	BOOL _optUseContainers;
	BOOL _optRecast;
	int _optLureItemID;
	
	BOOL _isFishing;
	BOOL _ignoreIsFishing;
	
	int _applyLureAttempts;
	int _totalFishLooted;
	int _castNumber;
	int _lootAttempt;
	
	UInt32 _fishingSpellID;
	UInt64 _playerGUID;
	
	Node *_nearbySchool;
	//Node *_bobber;
	NSDate *_castStartTime;
	
	NSMutableArray *_facedSchool;
}

@property (readonly) BOOL isFishing;

- (void)fish: (BOOL)optApplyLure 
  withRecast:(BOOL)optRecast 
	 withUse:(BOOL)optUseContainers 
	withLure:(int)optLureID
  withSchool:(Node*)nearbySchool;

- (void)stopFishing;

- (Node*)nearbySchool;

@end
