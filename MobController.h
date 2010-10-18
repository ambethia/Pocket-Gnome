//
//  MobController.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 12/17/07.
//  Copyright 2007 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Mob.h"
#import "ObjectController.h"

@class CombatProfile;

@class BotController;

@class ObjectsController;

@interface MobController : ObjectController {
    IBOutlet BotController *botController;
    IBOutlet id memoryViewController;
    IBOutlet id combatController;
    IBOutlet id movementController;
    IBOutlet id auraController;
    IBOutlet id spellController;
	
	IBOutlet ObjectsController	*objectsController;

    IBOutlet id trackFriendlyMenuItem;
    IBOutlet id trackNeutralMenuItem;
    IBOutlet id trackHostileMenuItem;
    
    IBOutlet NSPopUpButton *additionalList;
    
    int cachedPlayerLevel;
    Mob *memoryViewMob;
}

+ (MobController *)sharedController;

@property (readonly) NSImage *toolbarIcon;

- (unsigned)mobCount;
- (NSArray*)allMobs;
- (void)doCombatScan;

- (void)clearTargets;
- (Mob*)playerTarget;
- (Mob*)mobWithEntryID: (int)entryID;
- (NSArray*)mobsWithEntryID: (int)entryID;
- (Mob*)mobWithGUID: (GUID)guid;

- (NSArray*)mobsWithinDistance: (float)mobDistance 
						MobIDs: (NSArray*)mobIDs 
					  position:(Position*)position 
					 aliveOnly:(BOOL)aliveOnly;

- (NSArray*)mobsWithinDistance: (float)distance
                    levelRange: (NSRange)range
                  includeElite: (BOOL)elite
               includeFriendly: (BOOL)friendly
                includeNeutral: (BOOL)neutral
                includeHostile: (BOOL)hostile;
- (Mob*)closestMobForInteraction:(UInt32)entryID;

- (NSArray*)uniqueMobsAlphabetized;
- (Mob*)closestMobWithName:(NSString*)mobName;

- (IBAction)updateTracking: (id)sender;

@end
