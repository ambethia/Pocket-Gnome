//
//  Player.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 5/25/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import "Player.h"
#import "WoWObject.h"
#import "Mob.h"
#import "Offsets.h"

#import "OffsetController.h"
#import "PlayersController.h"

enum PlayerFlags
{
    PLAYER_FLAGS_GROUP_LEADER   = 0x00000001,
    PLAYER_FLAGS_AFK            = 0x00000002,
    PLAYER_FLAGS_DND            = 0x00000004,
    PLAYER_FLAGS_GM             = 0x00000008,
    PLAYER_FLAGS_GHOST          = 0x00000010,
    PLAYER_FLAGS_RESTING        = 0x00000020,
    PLAYER_FLAGS_FFA_PVP        = 0x00000080,
    PLAYER_FLAGS_UNK            = 0x00000100,               // show PvP in tooltip
    PLAYER_FLAGS_IN_PVP         = 0x00000200,
    PLAYER_FLAGS_HIDE_HELM      = 0x00000400,
    PLAYER_FLAGS_HIDE_CLOAK     = 0x00000800,
    PLAYER_FLAGS_UNK1           = 0x00001000,               // played long time
    PLAYER_FLAGS_UNK2           = 0x00002000,               // played too long time
    PLAYER_FLAGS_UNK3           = 0x00008000,               // strange visual effect (2.0.1), looks like PLAYER_FLAGS_GHOST flag
    PLAYER_FLAGS_UNK4           = 0x00020000,               // taxi benchmark mode (on/off) (2.0.1)
    PLAYER_UNK                  = 0x00040000,               // 2.0.8...
};


@interface Player (Internal)
- (UInt32)playerFlags;
- (UInt32)playerFieldsAddress;
@end

@implementation Player

+ (id)playerWithAddress: (NSNumber*)address inMemory: (MemoryAccess*)memory {
    return [[[Player alloc] initWithAddress: address inMemory: memory] autorelease];
}

- (NSString*)description {
    return [NSString stringWithFormat: @"<%@ [%d] [%d%%] (0x%X)>", [self className], [self level], [self percentHealth], [self lowGUID]];
}

- (void) dealloc{
    [super dealloc];
}
#pragma mark -

- (UInt32)playerFieldsAddress{
	UInt32 value = 0;
	if ( [_memory loadDataForObject: self atAddress: ([self baseAddress] + [[OffsetController sharedController] offset:@"PlayerField_Pointer"]) Buffer: (Byte *)&value BufLength: sizeof(value)] ){
		return value;
	}
	return 0;
}

- (UInt32)playerFlags {
    UInt32 value = 0;
    if([self isValid] && [_memory loadDataForObject: self atAddress: ([self playerFieldsAddress] + PLAYER_FLAGS) Buffer: (Byte *)&value BufLength: sizeof(value)] && (value != 0xDDDDDDDD)) {
        return value;
    }
    return 0;
}

- (BOOL)isGM {
    if( ([self playerFlags] & (PLAYER_FLAGS_GM)) == (PLAYER_FLAGS_GM))
        return YES;
    return NO;
}

- (GUID)itemGUIDinSlot: (CharacterSlot)slot {
    if(slot < 0 || slot >= SLOT_MAX) return 0;
    
    GUID value = 0;
    if([_memory loadDataForObject: self atAddress: ([self playerFieldsAddress] + PLAYER_FIELD_INV_SLOT_HEAD + sizeof(GUID)*slot) Buffer: (Byte *)&value BufLength: sizeof(value)]) {
        //if(GUID_HIPART(value) == HIGHGUID_ITEM) - As of 3.1.3 I had to comment out this - i'm not sure why
		return value;
    }
    return 0;
}

// items player has in their backpack
- (NSArray*)itemGUIDsInBackpack{
	NSMutableArray *itemGUIDs = [NSMutableArray array];
	
	const int numberOfItems = 16;	// this could change on a patch day, it's the number of items stored in a player's backpack
	uint i;
	GUID value = 0;
	for ( i = 0; i < numberOfItems; i++ ){
		if([_memory loadDataForObject: self atAddress: ([self playerFieldsAddress] + PLAYER_FIELD_PACK_SLOT_1 + sizeof(GUID)*i) Buffer: (Byte *)&value BufLength: sizeof(value)]) {
			[itemGUIDs addObject:[NSNumber numberWithLongLong:value]];
		}
	}
	
	return itemGUIDs;
}

// the GUIDs of the player's bags
- (NSArray*)itemGUIDsOfBags{
	NSMutableArray *bagGUIDs = [NSMutableArray array];
	const int numberOfBags = 4;
	uint i;
	GUID value = 0;
	for ( i = 0; i < numberOfBags; i++ ){
		if([_memory loadDataForObject: self atAddress: ([self playerFieldsAddress] + PLAYER_FIELD_BANKBAG_SLOT_1 + sizeof(GUID)*i) Buffer: (Byte *)&value BufLength: sizeof(value)]) {
			[bagGUIDs addObject:[NSNumber numberWithLongLong:value]];
		}
	}
	
	return bagGUIDs;
}

// items the player is wearing
- (NSArray*)itemGUIDsPlayerIsWearing{
	NSMutableArray *itemGUIDs = [NSMutableArray array];
	uint slot;
	GUID value = 0;
	for ( slot = 0; slot <= SLOT_TABARD; slot++ ){
		if([_memory loadDataForObject: self atAddress: ([self playerFieldsAddress] + PLAYER_FIELD_INV_SLOT_HEAD + sizeof(GUID)*slot) Buffer: (Byte *)&value BufLength: sizeof(value)]) {
			[itemGUIDs addObject:[NSNumber numberWithLongLong:value]];
		}
	}
	
	return itemGUIDs;
}

- (NSString*)name {
    return [playersController playerNameWithGUID:[self GUID]];
}

@end
