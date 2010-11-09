//
//  Mob.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 12/20/07.
//  Copyright 2007 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Position.h"
#import "Unit.h"


@interface Mob : Unit {
    UInt32  _stateFlags;
    
    NSString *_name;
    UInt32 _nameEntryID;
}
+ (id)mobWithAddress: (NSNumber*)address inMemory: (MemoryAccess*)memory;

- (UInt32)experience;

- (void)select;
- (void)deselect;
- (BOOL)isSelected;

// npc type
- (BOOL)isVendor;
- (BOOL)canRepair;
- (BOOL)isFlightMaster;
- (BOOL)canGossip;
- (BOOL)isTrainer;
- (BOOL)isYourClassTrainer;
- (BOOL)isYourProfessionTrainer;
- (BOOL)isQuestGiver;
- (BOOL)isStableMaster;
- (BOOL)isBanker;
- (BOOL)isAuctioneer;
- (BOOL)isInnkeeper;
- (BOOL)isFoodDrinkVendor;
- (BOOL)isReagentVendor;
- (BOOL)isSpiritHealer;
- (BOOL)isBattlemaster;

// status
- (BOOL)isTapped;
- (BOOL)isTappedByMe;
- (BOOL)isTappedByOther;
- (BOOL)isBeingTracked;


@end
