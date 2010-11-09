//
//  Mob.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 12/20/07.
//  Copyright 2007 Savory Software, LLC. All rights reserved.
//

#import "Mob.h"
#import "Offsets.h"


#define MOB_NAMESTRUCT_POINTER_OFFSET     0x9F8

enum eMobNameStructFields {
    NAMESTRUCT_TITLE_PTR            = 0x4,
    NAMESTRUCT_NAMESPACE_END_PTR    = 0x8,  // this is bogus half the time, so I don't know
    NAMESTRUCT_CreatureType         = 0x10,
    NAMESTRUCT_NAME_PTR             = 0x60,
    NAMESTRUCT_ENTRY_ID             = 0x70,
};

@interface Mob ()
@property (readwrite, retain) NSString *name;
@end

@interface Mob (Internal)
- (BOOL)isHostileDeprecated;
@end

@implementation Mob

+ (id)mobWithAddress: (NSNumber*)address inMemory: (MemoryAccess*)memory {
    return [[[Mob alloc] initWithAddress: address inMemory: memory] autorelease];
}

- (NSString*)description {
    if( [self isFeignDeath] )
        return [NSString stringWithFormat: @"<Mob [%d] [%d%% <FD>] \"%@\" (%d) (0x%X)>", [self level], [self percentHealth], self.name, [self entryID], [self lowGUID]];
    else
        return [NSString stringWithFormat: @"<Mob [%d] [%d%%] \"%@\" (%d) (0x%X)>", [self level], [self percentHealth], self.name, [self entryID], [self lowGUID]];
    // <Mob [61] [100%] "Marshbleh Threshablah" (12345) (0xBEWBZ01)>
}


- (void) dealloc
{
    [_name release]; _name = nil;
    [super dealloc];
}


#pragma mark -

// 3 reads
- (NSString*)name {
    // if we already have a name saved, return it
    if(_name && [_name length]) {
        if(_nameEntryID == [self entryID])
            return [[_name retain] autorelease];
    }
    
    // if we don't, load the name out of memory
    if([self objectTypeID] == TYPEID_UNIT) {
        
        // get the address from the object itself
        UInt32 value = 0;
        if([_memory loadDataForObject: self atAddress: ([self baseAddress] + MOB_NAMESTRUCT_POINTER_OFFSET) Buffer: (Byte *)&value BufLength: sizeof(value)])
        {
            UInt32 entryID = 0, stringPtr = 0, titlePtr = 0;
            
            // verify that the entry IDs match, then follow the pointer to the string value
            if([_memory loadDataForObject: self atAddress: (value + NAMESTRUCT_NAME_PTR) Buffer: (Byte *)&stringPtr BufLength: sizeof(stringPtr)] &&
               [_memory loadDataForObject: self atAddress: (value + NAMESTRUCT_ENTRY_ID) Buffer: (Byte *)&entryID BufLength: sizeof(entryID)])
            {
				
                if( (entryID == [self entryID]) && stringPtr )
                {
                    // get title ptr if it exists; we dont care if this op fails
                    [_memory loadDataForObject: self atAddress: (value + NAMESTRUCT_TITLE_PTR) Buffer: (Byte *)&titlePtr BufLength: sizeof(titlePtr)];
                    
                    char name[97];
                    name[96] = 0;  // make sure it's null terminated, just incase
                    if([_memory loadDataForObject: self atAddress: stringPtr Buffer: (Byte *)&name BufLength: sizeof(name)-1])
                    {
                        NSString *newName = [NSString stringWithUTF8String: name];  // will stop after it's first encounter with '\0'
                        if([newName length]) {
                            // now see if there's a title
                            NSString *title = nil;
                            UInt32 titleOffset = titlePtr - stringPtr;
                            if(titlePtr && (titleOffset > 0) && (titleOffset < 96)) {
                                title = [NSString stringWithUTF8String: (name + titleOffset)];
                            }
                            
                            [self setName: [title length] ? [NSString stringWithFormat: @"%@ <%@>", newName, title] : newName];
                            return newName;
                        }
                    }
                }
            }
        }
    }
    return @"";
}

- (void)setName: (NSString*)name {
    id temp = nil;
    [name retain];
    @synchronized (@"Name") {
        temp = _name;
        _name = name;
        _nameEntryID = [self entryID];
    }
    [temp release];
}


// 1 read
// broken at the moment
- (UInt32)experience {
    return 0;
}

#pragma mark -
#pragma mark Selection

#define UnitSelectedFlag (1 << 12) // 0x1000
#define UnitFocusedFlag  (1 << 13) // 0x2000

- (BOOL)valueMeansSelected: (UInt32)value {
    return ((value & UnitSelectedFlag) == UnitSelectedFlag);
}

// 1 read, 1 write
- (void)select {
    UInt32 select = UnitSelectedFlag, value = 0;
    [_memory loadDataForObject: self atAddress: [self baseAddress] + BaseField_SelectionFlags Buffer: (Byte *)&value BufLength: sizeof(value)];
    select |= value;
    [_memory saveDataForAddress: [self baseAddress] + BaseField_SelectionFlags Buffer: (Byte *)&select BufLength: sizeof(select)];
}

// this isn't used right now, but might be useful for Focus support?
- (void)focus {
    UInt32 focus = UnitFocusedFlag, value = 0;
    [_memory loadDataForObject: self atAddress: [self baseAddress] + BaseField_SelectionFlags Buffer: (Byte *)&value BufLength: sizeof(value)];
    focus |= value;
    [_memory saveDataForAddress: [self baseAddress] + BaseField_SelectionFlags Buffer: (Byte *)&focus BufLength: sizeof(focus)];
}

// 1 read, 1 write
- (void)deselect {
    UInt32 value = 0;
    [_memory loadDataForObject: self atAddress: [self baseAddress] + BaseField_SelectionFlags Buffer: (Byte *)&value BufLength: sizeof(value)];
    if([self valueMeansSelected: value]) {
        value ^= UnitSelectedFlag;
        [_memory saveDataForAddress: [self baseAddress] + BaseField_SelectionFlags Buffer: (Byte *)&value BufLength: sizeof(value)];
    }
}

// 1 read
- (BOOL)isSelected {
    UInt32 value = 0;
    if([_memory loadDataForObject: self atAddress: [self baseAddress] + BaseField_SelectionFlags Buffer: (Byte *)&value BufLength: sizeof(value)] && [self valueMeansSelected: value])
        return YES;
    return NO;
}


#pragma mark -

// redefined from Unit
- (BOOL)isTotem {
    if([self creatureType] == CreatureType_Totem)
        return YES;
    return NO;
}

- (CreatureType)creatureType {
    UInt32 value = 0;
    if([_memory loadDataForObject: self atAddress: ([self baseAddress] + MOB_NAMESTRUCT_POINTER_OFFSET) Buffer: (Byte *)&value BufLength: sizeof(value)] && value)
    {
        UInt32 type = 0;
        if([_memory loadDataForObject: self atAddress: (value + NAMESTRUCT_CreatureType) Buffer: (Byte *)&type BufLength: sizeof(type)] && type) {
            if( (type > CreatureType_Unknown) && (type < CreatureType_Max)) {
                return type;
            }
        }
    }
    return CreatureType_Unknown;
}

- (BOOL)isSkinnable {
    if( ([self stateFlags] & (1 << UnitStatus_Skinnable)) == (1 << UnitStatus_Skinnable))
        return YES;
    return NO;
}

- (BOOL)isElite {
    if( ([self stateFlags] & (1 << UnitStatus_Elite)) == (1 << UnitStatus_Elite))
        return YES;
    return NO;
}

#pragma mark NPC Flags

- (BOOL)canGossip {
    if( ([self npcFlags] & 0x1) == 0x1)
        return YES;
    return NO;
}

- (BOOL)isQuestGiver {
    if( ([self npcFlags] & 0x2) == 0x2)
        return YES;
    return NO;
}

- (BOOL)isTrainer {
    if( ([self npcFlags] & 0x10) == 0x10)
        return YES;
    return NO;
}

- (BOOL)isYourClassTrainer {
    if( ([self npcFlags] & 0x20) == 0x20)
        return YES;
    return NO;
}

- (BOOL)isYourProfessionTrainer {
    if( ([self npcFlags] & 0x40) == 0x40)
        return YES;
    return NO;
}

- (BOOL)isVendor {
    if( ([self npcFlags] & 0x80) == 0x80)
        return YES;
    return NO;
}

- (BOOL)isGeneralGoodsVendor {
    if( ([self npcFlags] & 0x100) == 0x100)
        return YES;
    return NO;
}

- (BOOL)isFoodDrinkVendor {
    if( ([self npcFlags] & 0x200) == 0x200)
        return YES;
    return NO;
}

- (BOOL)isPoisonVendor {
    if( ([self npcFlags] & 0x400) == 0x400)
        return YES;
    return NO;
}

- (BOOL)isReagentVendor {
    if( ([self npcFlags] & 0x800) == 0x800)
        return YES;
    return NO;
}

- (BOOL)canRepair {
    if( ([self npcFlags] & 0x1000) == 0x1000)
        return YES;
    return NO;
}

- (BOOL)isFlightMaster {
    if( ([self npcFlags] & 0x2000) == 0x2000)
        return YES;
    return NO;
}

- (BOOL)isSpiritHealer {
    if( ([self npcFlags] & 0x4000) == 0x4000)
        return YES;
    return NO;
}

- (BOOL)isSpiritGuide {
    if( ([self npcFlags] & 0x8000) == 0x8000)
        return YES;
    return NO;
}

- (BOOL)isInnkeeper {
    if( ([self npcFlags] & 0x10000) == 0x10000)
        return YES;
    return NO;
}

- (BOOL)isBanker {
    if( ([self npcFlags] & 0x20000) == 0x20000)
        return YES;
    return NO;
}

- (BOOL)isPetitioner {
    if( ([self npcFlags] & 0x40000) == 0x40000)
        return YES;
    return NO;
}

- (BOOL)isTabbardDesigner {
    if( ([self npcFlags] & 0x80000) == 0x80000)
        return YES;
    return NO;
}

- (BOOL)isBattlemaster {
    if( ([self npcFlags] & 0x100000) == 0x100000)
        return YES;
    return NO;
}

- (BOOL)isAuctioneer {
    if( ([self npcFlags] & 0x200000) == 0x200000)
        return YES;
    return NO;
}

- (BOOL)isStableMaster {
    if( ([self npcFlags] & 0x400000) == 0x400000)
        return YES;
    return NO;
}

#pragma mark Unit Dynamic Flags

- (BOOL)isTapped {
    if( ([self dynamicFlags] & 0x4) == 0x4)  // bit 2
        return YES;
    return NO;
}

- (BOOL)isTappedByMe {
    if( ([self dynamicFlags] & 0xC) == 0xC) // bits 2 & 3
        return YES;
    return NO;
}

- (BOOL)isTappedByOther {
    return ([self isTapped] && ![self isTappedByMe]);
}

- (BOOL)isLootable {
    if( ([self dynamicFlags] & 0xD) == 0xD) // bits 0, 2 & 3
        return YES;
    return NO;
}

- (BOOL)isBeingTracked {
    if( ([self dynamicFlags] & 0x2) == 0x2) // bit 1
        return YES;
    return NO;
}


@end
