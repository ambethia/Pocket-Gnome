//
//  Player.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 5/25/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Unit.h"

enum ePlayer_TrackResources_Fields {
	TrackObject_All			= -1,
	TrackObject_None		= 0x0,
	TrackObject_Herbs		= 0x2,
	TrackObject_Minerals	= 0x4,
	TrackObject_Treasure	= 0x20,
	TrackObject_Treasure2	= 0x1000,
	TrackObject_Fish		= 0x40000,
};

enum ePlayer_VisibleItem_Fields {
    VisibleItem_CreatorGUID                     = 0x0,
    VisibleItem_EntryID                         = 0x8,
    VisibleItem_Enchant                         = 0x10,
    // other unknown properties follow
    
    VisibleItem_Size                            = 0x40,
};

typedef enum eCharacterSlot { 
    SLOT_HEAD = 0,
    SLOT_NECK = 1,
    SLOT_SHOULDERS = 2,
    SLOT_SHIRT = 3, 
    SLOT_CHEST = 4, 
    SLOT_WAIST = 5,
    SLOT_LEGS = 6,
    SLOT_FEET = 7, 
    SLOT_WRISTS = 8,
    SLOT_HANDS = 9,
    SLOT_FINGER1 = 10, 
    SLOT_FINGER2 = 11, 
    SLOT_TRINKET1 = 12,
    SLOT_TRINKET2 = 13,
    SLOT_BACK = 14,
    SLOT_MAIN_HAND = 15, 
    SLOT_OFF_HAND = 16, 
    SLOT_RANGED = 17,
    SLOT_TABARD = 18,
    SLOT_EMPTY = 19,
    SLOT_MAX,
} CharacterSlot;

//typedef enum {
//    UnitBloc_Alliance       = 3,
//    UnitBloc_Horde          = 5,
//} UnitBloc;

@class PlayersController;

@interface Player : Unit {
    UInt32 _nameEntryID;
	
	IBOutlet PlayersController *playersController;
}

+ (id)playerWithAddress: (NSNumber*)address inMemory: (MemoryAccess*)memory;

// status
- (BOOL)isGM;

- (GUID)itemGUIDinSlot: (CharacterSlot)slot;    // invalid for other players

- (NSArray*)itemGUIDsInBackpack;
- (NSArray*)itemGUIDsOfBags;
- (NSArray*)itemGUIDsPlayerIsWearing;

- (NSString*)name;
@end
