//
//  PlayersController.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 5/25/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ObjectController.h"

@class Player;
@class Unit;

@class PlayerDataController;
@class MemoryViewController;
@class MovementController;
@class ObjectsController;

@interface PlayersController : ObjectController {
    IBOutlet MemoryViewController *memoryViewController;
    IBOutlet MovementController *movementController;
	IBOutlet ObjectsController	*objectsController;

    IBOutlet NSButton *playerColorByLevel;
	
	NSMutableDictionary *_playerNameList;

    int cachedPlayerLevel;
}

@property (readonly) unsigned playerCount;

+ (PlayersController *)sharedPlayers;
- (NSArray*)allPlayers;
- (Player*)playerTarget;
- (Player*)playerWithGUID: (GUID)guid;

- (NSArray*)playersWithinDistance: (float)distance
                       levelRange: (NSRange)range
                  includeFriendly: (BOOL)friendly
                   includeNeutral: (BOOL)neutral
                   includeHostile: (BOOL)hostile;
- (BOOL)playerWithinRangeOfUnit: (float)distance Unit:(Unit*)unit includeFriendly:(BOOL)friendly includeHostile:(BOOL)hostile;
- (NSArray*)friendlyPlayers;

- (void)updateTracking: (id)sender;

- (NSString*)playerNameWithGUID:(UInt64)guid;

// player name
- (BOOL)addPlayerName: (NSString*)name withGUID:(UInt64)guid;
- (int)totalNames;

@end
