//
//  Unit.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 5/26/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import "Unit.h"
#import "Offsets.h"
#import "Condition.h"

#import "SpellController.h"
#import "PlayerDataController.h"
#import "OffsetController.h"

/*
/// Non Player Character flags
enum NPCFlags
{
    UNIT_NPC_FLAG_NONE              = 0x00000000,
    UNIT_NPC_FLAG_GOSSIP            = 0x00000001,
    UNIT_NPC_FLAG_QUESTGIVER        = 0x00000002,
    UNIT_NPC_FLAG_VENDOR            = 0x00000004,
    UNIT_NPC_FLAG_TAXIVENDOR        = 0x00000008,
    UNIT_NPC_FLAG_TRAINER           = 0x00000010,
    UNIT_NPC_FLAG_SPIRITHEALER      = 0x00000020,
    UNIT_NPC_FLAG_SPIRITGUIDE       = 0x00000040,           // Spirit Guide
    UNIT_NPC_FLAG_INNKEEPER         = 0x00000080,
    UNIT_NPC_FLAG_BANKER            = 0x00000100,
    UNIT_NPC_FLAG_PETITIONER        = 0x00000200,           // 0x600 = guild petitions, 0x200 = arena team petitions
    UNIT_NPC_FLAG_TABARDDESIGNER    = 0x00000400,
    UNIT_NPC_FLAG_BATTLEFIELDPERSON = 0x00000800,
    UNIT_NPC_FLAG_AUCTIONEER        = 0x00001000,
    UNIT_NPC_FLAG_STABLE            = 0x00002000,
    UNIT_NPC_FLAG_ARMORER           = 0x00004000,
    UNIT_NPC_FLAG_GUARD             = 0x00010000,           // custom flag
};
*/

@interface Unit (Internal)
- (UInt32)infoFlags;
@end

@implementation Unit

+ (id)unitWithAddress: (NSNumber*)address inMemory: (MemoryAccess*)memory {
    return [[[Unit alloc] initWithAddress: address inMemory: memory] autorelease];
}

#pragma mark Object Global Accessors

// 1 read
- (Position*)position {
    float pos[3] = {-1.0f, -1.0f, -1.0f };
    if([_memory loadDataForObject: self atAddress: ([self baseAddress] + BaseField_XLocation) Buffer: (Byte *)&pos BufLength: sizeof(float)*3])
        return [Position positionWithX: pos[0] Y: pos[1] Z: pos[2]];
    return nil;
}

- (float)directionFacing {
    float floatValue = -1.0;
    [_memory loadDataForObject: self atAddress: ([self baseAddress] + BaseField_Facing_Horizontal) Buffer: (Byte*)&floatValue BufLength: sizeof(floatValue)];
    return floatValue;
}


- (GUID)petGUID {
    UInt64 value = 0;
    
    // check for summon
    if( (value = [self summon]) ) {
        return value;
    }
    
    // check for charm
    if( (value = [self charm]) ) {
        return value;
    }
    return 0;
}


- (BOOL)hasPet {
    if( [self petGUID] > 0 ) {
        return YES;
    }
    return NO;
}

- (BOOL)isPet {
    if((GUID_HIPART([self GUID]) == HIGHGUID_PET) || [self isTotem])
        return YES;
        
    if( [self createdBy] || [self summonedBy] || [self charmedBy])
        return YES;
    
    return NO;
}

- (BOOL)isTotem {
    return NO;
}

- (BOOL)isCasting {
    UInt32 cast = 0, channel = 0;
    if([self isNPC]) {
        [_memory loadDataForObject: self atAddress: ([self baseAddress] + [[OffsetController sharedController] offset:@"BaseField_Spell_ToCast"]) Buffer: (Byte *)&cast BufLength: sizeof(cast)];
        [_memory loadDataForObject: self atAddress: ([self baseAddress] + [[OffsetController sharedController] offset:@"BaseField_Spell_Channeling"]) Buffer: (Byte *)&channel BufLength: sizeof(channel)];
    } else if([self isPlayer]) {
        [_memory loadDataForObject: self atAddress: ([self baseAddress] + [[OffsetController sharedController] offset:@"BaseField_Spell_Casting"]) Buffer: (Byte *)&cast BufLength: sizeof(cast)];
        [_memory loadDataForObject: self atAddress: ([self baseAddress] + [[OffsetController sharedController] offset:@"BaseField_Spell_Channeling"]) Buffer: (Byte *)&channel BufLength: sizeof(channel)];
    }
    
    if( cast > 0 || channel > 0)
        return YES;
    
    return NO;
}

- (UInt32)mountID{
	UInt32 value = 0;
	if([_memory loadDataForObject: self atAddress: ([self unitFieldAddress] + UNIT_FIELD_MOUNTDISPLAYID) Buffer: (Byte*)&value BufLength: sizeof(value)] && (value > 0) && (value != 0xDDDDDDDD)) {
        return value;
    }
	return 0;
}


- (BOOL)isMounted {
    UInt32 value = 0;
    if([_memory loadDataForObject: self atAddress: ([self unitFieldAddress] + UNIT_FIELD_MOUNTDISPLAYID) Buffer: (Byte*)&value BufLength: sizeof(value)] && (value > 0) && (value != 0xDDDDDDDD)) {
        return YES;
    }
	
	// check movement flags (mainly for the druid flight form since the mount display fails)
    if([_memory loadDataForObject: self atAddress: ([self baseAddress] + BaseField_MovementFlags) Buffer: (Byte*)&value BufLength: sizeof(value)] && (value > 0) && (value & MovementFlags_AirMounted)) {
		return YES;
    }
	
    return NO;
}

- (BOOL)isOnGround {
	UInt32 movementFlags = [self movementFlags];
	
	// player is air mounted + in the air!
	if ( (movementFlags & MovementFlags_AirMountedInAir) == MovementFlags_AirMountedInAir ){
		return NO;
	}
	
	// player is in the air
	if ( (movementFlags & MovementFlags_InAir) == MovementFlags_InAir ){
		return NO;
	}
	
	// we should assume if we get here, the player must be on the ground	
	return YES;
}

-(BOOL)isSwimming{
	UInt32 movementFlags = [self movementFlags];
	
	if ( (movementFlags & MovementFlag_Swimming) == MovementFlag_Swimming ){
		return YES;
	}
	
	return NO;
}

-(BOOL)isTargetingMe{

	if ( [self targetID]  == [playerController GUID] ) return YES;

	return NO;
}

- (BOOL)isFlyingMounted{
	UInt32 movementFlags = [self movementFlags];
	
	if ( movementFlags & MovementFlag_Flying1 ){
		return YES;
	}
	else if ( movementFlags & MovementFlag_Flying2 ){
		return YES;
	}
	return NO;
}

- (BOOL)isElite {
    return NO;
}

#pragma mark Object Field Accessors

- (UInt64)charm {
    UInt64 value = 0;
    if([_memory loadDataForObject: self atAddress: ([self unitFieldAddress] + UNIT_FIELD_CHARM) Buffer: (Byte *)&value BufLength: sizeof(value)])
        return value;
    return 0;
}

- (UInt64)summon {
    UInt64 value = 0;
    if([_memory loadDataForObject: self atAddress: ([self unitFieldAddress] + UNIT_FIELD_SUMMON) Buffer: (Byte *)&value BufLength: sizeof(value)])
        return value;
    return 0;
}

// 1 read
- (UInt64)targetID {
    UInt64 value = 0;
    if([_memory loadDataForObject: self atAddress: ([self unitFieldAddress] + UNIT_FIELD_TARGET) Buffer: (Byte *)&value BufLength: sizeof(value)])
        return value;
    return 0;
}

- (UInt64)createdBy {
    UInt64 value = 0;
    if([_memory loadDataForObject: self atAddress: ([self unitFieldAddress] + UNIT_FIELD_CREATEDBY) Buffer: (Byte *)&value BufLength: sizeof(value)])
        return value;
    return 0;
}

- (UInt64)summonedBy {
    UInt64 value = 0;
    if([_memory loadDataForObject: self atAddress: ([self unitFieldAddress] + UNIT_FIELD_SUMMONEDBY) Buffer: (Byte *)&value BufLength: sizeof(value)])
        return value;
    return 0;
}

- (UInt64)charmedBy {
    UInt64 value = 0;
    if([_memory loadDataForObject: self atAddress: ([self unitFieldAddress] + UNIT_FIELD_CHARMEDBY) Buffer: (Byte *)&value BufLength: sizeof(value)])
        return value;
    return 0;
}

// 3 reads (2 in powerType, 1)
- (UInt32)maxPower {
    return [self maxPowerOfType: [self powerType]];
}

// 3 reads
- (UInt32)currentPower {
    return [self currentPowerOfType: [self powerType]];
}

// 4 reads: 2 in powerType, 2 in percentPowerOfType
- (UInt32)percentPower {
    return [self percentPowerOfType: [self powerType]];
}


// 1
- (UInt32)maxHealth {
	UInt32 value = 0;
    if([_memory loadDataForObject: self atAddress: ([self unitFieldAddress] + UNIT_FIELD_MAXHEALTH) Buffer: (Byte *)&value BufLength: sizeof(value)])
        return value;
    return 0;
}

// 1 read
- (UInt32)currentHealth {
    UInt32 value = 0;
    if([_memory loadDataForObject: self atAddress: ([self unitFieldAddress] + UNIT_FIELD_HEALTH) Buffer: (Byte *)&value BufLength: sizeof(value)])
        return value;
    return 0;
}

// 2 reads
- (UInt32)percentHealth {
    UInt32 maxHealth = [self maxHealth];
    if(maxHealth == 0) return 0;
    return (UInt32)((((1.0)*[self currentHealth])/maxHealth) * 100);
}

// 1 read
- (UInt32)level {
    UInt32 value = 0;
    if([_memory loadDataForObject: self atAddress: ([self unitFieldAddress] + UNIT_FIELD_LEVEL) Buffer: (Byte *)&value BufLength: sizeof(value)])
        return value;
    return 0;
}

// 1 read
- (UInt32)factionTemplate {
    UInt32 value = 0;
    [_memory loadDataForObject: self atAddress: ([self unitFieldAddress] + UNIT_FIELD_FACTIONTEMPLATE) Buffer: (Byte *)&value BufLength: sizeof(value)];
    return value;
}

// 1 read
- (UInt32)movementFlags {
    UInt32 value = 0;
    [_memory loadDataForObject: self atAddress: ([self baseAddress] + BaseField_MovementFlags) Buffer: (Byte*)&value BufLength: sizeof(value)];
    return value;
}

#pragma mark Power Helper

// type : 0 = current, 1 = percentage
- (UInt32)unitPowerWithQuality:(int)quality andType:(int)type{
	
	// check if it's power or health
	if ( quality == QualityHealth ){
		return ( (type == TypeValue) ? [self currentHealth] : [self percentHealth] );
	}
	else if ( quality == QualityPower ){
		return ( (type == TypeValue) ? [self currentPower] : [self percentPower] );
	}
	
	// otherwise check the other types!
	UInt32 powerType = 0;
	switch ( quality ){
		case QualityRage:
			powerType = UnitPower_Rage;
			break;
		case QualityEnergy:
			powerType = UnitPower_Energy;
			break;
		case QualityHappiness:
			powerType = UnitPower_Happiness;
			break;
		case QualityFocus:
			powerType = UnitPower_Focus;
			break;			
		case QualityRunicPower:
			powerType = UnitPower_RunicPower;
			break;		
		case QualityEclipse:
			powerType = UnitPower_Eclipse;
			break;	
		case QualityHolyPower:
			powerType = UnitPower_HolyPower;
			break;	
		case QualitySoulShards:
			powerType = UnitPower_SoulShard;
			break;	
	}
	
	// actual value
	if ( type == TypeValue ){
		return [self currentPowerOfType:powerType];
	}
	// percentage
	else{
		return [self maxPowerOfType:powerType];
	}
	
	return 0;
}

#pragma mark -

// 1 read
- (UInt32)maxPowerOfType: (UnitPower)powerType {
    if(powerType < 0 || powerType > UnitPower_Max) return 0;
    
    UInt32 value;
    if([_memory loadDataForObject: self atAddress: (([self unitFieldAddress] + UNIT_FIELD_MAXPOWER1) + (sizeof(value) * powerType)) Buffer: (Byte *)&value BufLength: sizeof(value)])
    { 
        if((powerType == UnitPower_Rage) || (powerType == UnitPower_RunicPower))
            return value/10;
        else
            return value;
    }
    return 0;
}

// 1 read
- (UInt32)currentPowerOfType: (UnitPower)powerType {
    if(powerType < 0 || powerType > UnitPower_Max) return 0;
    UInt32 value;
    if([_memory loadDataForObject: self atAddress: (([self unitFieldAddress] + UNIT_FIELD_POWER1) + (sizeof(value) * powerType)) Buffer: (Byte *)&value BufLength: sizeof(value)])
    {
        if((powerType == UnitPower_Rage) || (powerType == UnitPower_RunicPower))
            return lrintf(floorf(value/10.0f));
        else
            return value;
    }
    return 0;
}

// 1 in maxP, 1 in currP
- (UInt32)percentPowerOfType: (UnitPower)powerType {

    UInt32 maxPower = [self maxPowerOfType: powerType];
    if(maxPower == 0) return 0;
    return (UInt32)((((1.0)*[self currentPowerOfType: powerType])/maxPower) * 100);
}

#pragma mark Unit Info

// 2 read
- (UInt32)infoFlags {
    UInt32 value = 0;
    if([self isValid] && [_memory loadDataForObject: self atAddress: ([self unitFieldAddress] + UNIT_FIELD_BYTES_0) Buffer: (Byte *)&value BufLength: sizeof(value)] && (value != 0xDDDDDDDD)) {
        return CFSwapInt32HostToLittle(value);
    }
    return 0;
}

- (UnitRace)race {
    return ([self infoFlags] >> 0 & 0xFF);
}

- (UnitClass)unitClass {
    return (([self infoFlags] >> 8) & 0xFF);
}

- (UnitGender)gender {
    return (([self infoFlags] >> 16) & 0xFF);
}

- (UnitPower)powerType {
    return (([self infoFlags] >> 24) & 0xFF);
}

- (CreatureType)creatureType {
    if([self isPlayer]) {
        return CreatureType_Humanoid;
    }
    return CreatureType_Unknown;
}

#pragma mark Unit Info Translations

+ (NSString*)stringForClass: (UnitClass)unitClass {
    NSString *stringClass = nil;
    
    switch(unitClass) {
        case UnitClass_Warrior:
            stringClass = @"Warrior";
            break;
        case UnitClass_Paladin:
            stringClass = @"Paladin";
            break;
        case UnitClass_Hunter:
            stringClass = @"Hunter";
            break;
        case UnitClass_Rogue:
            stringClass = @"Rogue";
            break;
        case UnitClass_Priest:
            stringClass = @"Priest";
            break;
        case UnitClass_Shaman:
            stringClass = @"Shaman";
            break;
        case UnitClass_Mage:
            stringClass = @"Mage";
            break;
        case UnitClass_Warlock:
            stringClass = @"Warlock";
            break;
        case UnitClass_Druid:
            stringClass = @"Druid";
            break;
        case UnitClass_DeathKnight:
            stringClass = @"Death Knight";
            break;
        default:
            stringClass = @"Unknown";
            break;
    }
    return stringClass;
}

+ (NSString*)stringForRace: (UnitRace)unitRace {
    NSString *string = nil;
    
    switch(unitRace) {
        case UnitRace_Human:
            string = @"Human";
            break;
        case UnitRace_Orc:
            string = @"Orc";
            break;
        case UnitRace_Dwarf:
            string = @"Dwarf";
            break;
        case UnitRace_NightElf:
            string = @"Night Elf";
            break;
        case UnitRace_Undead:
            string = @"Undead";
            break;
        case UnitRace_Tauren:
            string = @"Tauren";
            break;
        case UnitRace_Gnome:
            string = @"Gnome";
            break;
        case UnitRace_Troll:
            string = @"Troll";
            break;
        case UnitRace_Goblin:
            string = @"Goblin";
            break;
        case UnitRace_BloodElf:
            string = @"Blood Elf";
            break;
        case UnitRace_Draenei:
            string = @"Draenei";
            break;
        case UnitRace_FelOrc:
            string = @"Fel Orc";
            break;
        case UnitRace_Naga:
            string = @"Naga";
            break;
        case UnitRace_Broken:
            string = @"Broken";
            break;
        case UnitRace_Skeleton:
            string = @"Skeleton";
            break;
        default:
            string = @"Unknown";
            break;
    }
    return string;
}

+ (NSString*)stringForGender: (UnitGender) underGender {
    NSString *string = nil;
    
    switch(underGender) {
        case UnitGender_Male:
            string = @"Male";
            break;
        case UnitGender_Female:
            string = @"Female";
            break;
        default:
            string = @"Unknown";
            break;
    }
    return string;
}

- (NSImage*)iconForClass: (UnitClass)unitClass {
    return [NSImage imageNamed: [[NSString stringWithFormat: @"%@_Small", [Unit stringForClass: unitClass]] stringByReplacingOccurrencesOfString: @" " withString: @""]];
    
    NSImage *icon = nil;
    switch(unitClass) {
        case UnitClass_Warrior:
            icon = [NSImage imageNamed: @"Warrior"];
            break;
        case UnitClass_Paladin:
            icon = [NSImage imageNamed: @"Paladin"];
            break;
        case UnitClass_Hunter:
            icon = [NSImage imageNamed: @"Hunter"];
            break;
        case UnitClass_Rogue:
            icon = [NSImage imageNamed: @"Rogue"];
            break;
        case UnitClass_Priest:
            icon = [NSImage imageNamed: @"Priest"];
            break;
        case UnitClass_Shaman:
            icon = [NSImage imageNamed: @"Shaman"];
            break;
        case UnitClass_Mage:
            icon = [NSImage imageNamed: @"Mage"];
            break;
        case UnitClass_Warlock:
            icon = [NSImage imageNamed: @"Warlock"];
            break;
        case UnitClass_Druid:
            icon = [NSImage imageNamed: @"Druid"];
            break;
        case UnitClass_DeathKnight:
            icon = [NSImage imageNamed: @"Death Knight"];
            break;
        default:
            icon = [NSImage imageNamed: @"UnknownSmall"];
            break;
    }
    return icon;
}

- (NSImage*)iconForRace: (UnitRace)unitRace gender: (UnitGender)unitGender {
    return [NSImage imageNamed: 
            [[NSString stringWithFormat: @"%@-%@_Small", 
              [Unit stringForRace: unitRace], 
              [Unit stringForGender: unitGender]] 
             stringByReplacingOccurrencesOfString: @" " withString: @""]];
}


#pragma mark State Functions

// 2 read
- (UInt32)stateFlags {
    UInt32 value = 0;
    if([self isValid] && [_memory loadDataForObject: self atAddress: ([self unitFieldAddress] + UNIT_FIELD_FLAGS) Buffer: (Byte *)&value BufLength: sizeof(value)] && (value != 0xDDDDDDDD)) {
        return value;
    }
    return 0;
}


- (BOOL)isPVP {
    if( ([self stateFlags] & (1 << UnitStatus_PVP)) == (1 << UnitStatus_PVP))   // 0x1000
        return YES;
    return NO;
}

// 2 reads
- (BOOL)isDead {
	int currentHealth = [self currentHealth];
    if ( currentHealth == 0 ) {
        if([self isFeignDeath]) {
            return NO;
        }
        return YES;
    }
    return NO;
}

- (BOOL)isFleeing {
    if( ([self stateFlags] & (1 << UnitStatus_Fleeing)) == (1 << UnitStatus_Fleeing))
        return YES;
    return NO;
}

- (BOOL)isEvading {
    if( ([self stateFlags] & (1 << UnitStatus_Evading)) == (1 << UnitStatus_Evading)) 
        return YES;
    return NO;
}

- (BOOL)isInCombat {
    if( ([self stateFlags] & (1 << UnitStatus_InCombat)) == (1 << UnitStatus_InCombat))   // 0x80000
        return YES;
    return NO;
}

- (BOOL)isSkinnable {
    return NO;
}

- (BOOL)isFeignDeath {
    if ( ([self stateFlags] & (1 << UnitStatus_FeignDeath)) == (1 << UnitStatus_FeignDeath))  // 0x20000000
        return YES;
    return NO;
}

- (BOOL)isSelectable {
    if ( ([self stateFlags] & (1 << UnitStatus_NotSelectable)) == (1 << UnitStatus_NotSelectable))
        return NO;
    return YES;
}

- (BOOL)isAttackable {
    if ( ([self stateFlags] & (1 << UnitStatus_NotAttackable)) == (1 << UnitStatus_NotAttackable))
        return NO;
    return YES;
}


- (UInt32)dynamicFlags {
    UInt32 value = 0;
    if([self isValid] && [_memory loadDataForObject: self atAddress: ([self unitFieldAddress] + UNIT_DYNAMIC_FLAGS) Buffer: (Byte *)&value BufLength: sizeof(value)] && (value != 0xDDDDDDDD)) {
        return value;
    }
    return 0;
}

- (UInt32)npcFlags {
    UInt32 value = 0;
    if([self isValid] && [_memory loadDataForObject: self atAddress: ([self unitFieldAddress] + UNIT_NPC_FLAGS) Buffer: (Byte *)&value BufLength: sizeof(value)] && (value != 0xDDDDDDDD)) {
        return value;
    }
    return 0;
}

- (BOOL)isLootable {
    return NO;
}

- (BOOL)isTappedByOther {
    return NO;
}

- (void)trackUnit {
    UInt32 value = [self dynamicFlags] | 0x2;
    [_memory saveDataForAddress: ([self unitFieldAddress] + UNIT_DYNAMIC_FLAGS) Buffer: (Byte *)&value BufLength: sizeof(value)];
}
- (void)untrackUnit {
    UInt32 value = [self dynamicFlags] & ~0x2;
    [_memory saveDataForAddress: ([self unitFieldAddress] + UNIT_DYNAMIC_FLAGS) Buffer: (Byte *)&value BufLength: sizeof(value)];
}

- (UInt32)petNumber {
    UInt32 value = 0;
    if([_memory loadDataForObject: self atAddress: ([self unitFieldAddress] + UNIT_FIELD_PETNUMBER) Buffer: (Byte *)&value BufLength: sizeof(value)]) {
        return value;
    }
    return 0;
}

- (UInt32)petNameTimestamp {
    UInt32 value = 0;
    if([_memory loadDataForObject: self atAddress: ([self unitFieldAddress] + UNIT_FIELD_PET_NAME_TIMESTAMP) Buffer: (Byte *)&value BufLength: sizeof(value)]) {
        return value;
    }
    return 0;
}

- (UInt32)createdBySpell {
    UInt32 value = 0;
    if([self isValid] && [_memory loadDataForObject: self atAddress: ([self unitFieldAddress] + UNIT_CREATED_BY_SPELL) Buffer: (Byte *)&value BufLength: sizeof(value)] && (value != 0xDDDDDDDD)) {
        return value;
    }
    return 0;
}

- (UInt32)unitBytes1 {
    // sit == 4, 5, 6
    // lie down = 0x7
    // kneel = 0x8
    // no shadow = 9

    UInt32 value = 0;
    if([self isValid] && [_memory loadDataForObject: self atAddress: ([self unitFieldAddress] + UNIT_FIELD_BYTES_1) Buffer: (Byte *)&value BufLength: sizeof(value)] && (value != 0xDDDDDDDD)) {
        return CFSwapInt32HostToLittle(value);  // not tested if CFSwapInt32HostToLittle is necessary, since unitBytes1 is not yet used anywhere
    }
    return 0;
}


- (BOOL)isSitting {
    return ([self unitBytes1] & 0x1);
}

- (UInt32)unitBytes2 {
    UInt32 value = 0;
    if([self isValid] && [_memory loadDataForObject: self atAddress: ([self unitFieldAddress] + UNIT_FIELD_BYTES_2) Buffer: (Byte *)&value BufLength: sizeof(value)] && (value != 0xDDDDDDDD)) {
        return CFSwapInt32HostToLittle(value);
    }
    return 0;
}

/*

// byte value (UNIT_FIELD_BYTES_1,0)
enum UnitStandStateType
{
    UNIT_STAND_STATE_STAND             = 0,
    UNIT_STAND_STATE_SIT               = 1,
    UNIT_STAND_STATE_SIT_CHAIR         = 2,
    UNIT_STAND_STATE_SLEEP             = 3,
    UNIT_STAND_STATE_SIT_LOW_CHAIR     = 4,
    UNIT_STAND_STATE_SIT_MEDIUM_CHAIR  = 5,
    UNIT_STAND_STATE_SIT_HIGH_CHAIR    = 6,
    UNIT_STAND_STATE_DEAD              = 7,
    UNIT_STAND_STATE_KNEEL             = 8
};
 
// byte flag value (UNIT_FIELD_BYTES_1,2)
enum UnitStandFlags
{
    UNIT_STAND_FLAGS_CREEP        = 0x02,
    UNIT_STAND_FLAGS_ALL          = 0xFF
};
 
// byte flags value (UNIT_FIELD_BYTES_1,3)
enum UnitBytes1_Flags
{
    UNIT_BYTE1_FLAG_ALWAYS_STAND = 0x01,
    UNIT_BYTE1_FLAG_UNTRACKABLE  = 0x04,
    UNIT_BYTE1_FLAG_ALL          = 0xFF
};


// high byte (3 from 0..3) of UNIT_FIELD_BYTES_2
enum ShapeshiftForm
{
    FORM_NONE               = 0x00,
    FORM_CAT                = 0x01,
    FORM_TREE               = 0x02,
    FORM_TRAVEL             = 0x03,
    FORM_AQUA               = 0x04,
    FORM_BEAR               = 0x05,
    FORM_AMBIENT            = 0x06,
    FORM_GHOUL              = 0x07,
    FORM_DIREBEAR           = 0x08,
    FORM_CREATUREBEAR       = 0x0E,
    FORM_CREATURECAT        = 0x0F,
    FORM_GHOSTWOLF          = 0x10,
    FORM_BATTLESTANCE       = 0x11,
    FORM_DEFENSIVESTANCE    = 0x12,
    FORM_BERSERKERSTANCE    = 0x13,
    FORM_TEST               = 0x14,
    FORM_ZOMBIE             = 0x15,
    FORM_FLIGHT_EPIC        = 0x1B,
    FORM_SHADOW             = 0x1C,
    FORM_FLIGHT             = 0x1D,
    FORM_STEALTH            = 0x1E,
    FORM_MOONKIN            = 0x1F,
    FORM_SPIRITOFREDEMPTION = 0x20
};


// byte (2 from 0..3) of UNIT_FIELD_BYTES_2
enum UnitRename
{
    UNIT_RENAME_NOT_ALLOWED = 0x02,
    UNIT_RENAME_ALLOWED     = 0x03
};

// byte (1 from 0..3) of UNIT_FIELD_BYTES_2
enum UnitBytes2_Flags
{
    UNIT_BYTE2_FLAG_PVP         = 0x01,
    UNIT_BYTE2_FLAG_UNK1        = 0x02,
    UNIT_BYTE2_FLAG_FFA_PVP     = 0x04,
    UNIT_BYTE2_FLAG_SANCTUARY   = 0x08,
    UNIT_BYTE2_FLAG_UNK4        = 0x10,
    UNIT_BYTE2_FLAG_UNK5        = 0x20,
    UNIT_BYTE2_FLAG_UNK6        = 0x40,
    UNIT_BYTE2_FLAG_UNK7        = 0x80
};

// low byte ( 0 from 0..3 ) of UNIT_FIELD_BYTES_2
enum SheathState
{
    SHEATH_STATE_UNARMED  = 0,                              // non prepared weapon
    SHEATH_STATE_MELEE    = 1,                              // prepared melee weapon
    SHEATH_STATE_RANGED   = 2                               // prepared ranged weapon
};
*/

#pragma mark -

- (NSString*)descriptionForOffset: (UInt32)offset {
    NSString *desc = nil;
    
    if(offset < ([self infoAddress] - [self baseAddress])) {
		
        switch(offset) {
        
            case BaseField_RunSpeed_Current:
                desc = @"Current Speed (float)";
                break;
            case BaseField_RunSpeed_Max:
                desc = @"Max Ground Speed (float)";
                break;
            case BaseField_AirSpeed_Max:
                desc = @"Max Air Speed (float)";
                break;
                
            case BaseField_XLocation:
                desc = @"X Location (float)";
                break;
            case BaseField_YLocation:
                desc = @"Y Location (float)";
                break;
            case BaseField_ZLocation:
                desc = @"Z Location (float)";
                break;
                
            case BaseField_Facing_Horizontal:
                desc = @"Direction Facing - Horizontal (float, [0, 2pi])";
                break;
            case BaseField_Facing_Vertical:
                desc = @"Direction Facing - Vertical (float, [-pi/2, pi/2])";
                break;
                
            case BaseField_MovementFlags:
                desc = @"Movement Flags";
                break;
				
            case BaseField_Auras_Start:
                desc = @"Start of Auras";
                break;
            case BaseField_Auras_ValidCount:
                desc = @"Auras Valid Count";
                break;
				
            case BaseField_Auras_OverflowPtr1:
                desc = @"Start of Auras 2";
                break;
            case BaseField_Auras_OverflowValidCount:
                desc = @"Auras Valid Count 2";
                break;
        }
		
		// dynamic shit
		if ( offset == [[OffsetController sharedController] offset:@"BaseField_Spell_Casting"] ){
			desc = @"Spell ID of casting spell";
		}
		else if ( offset == [[OffsetController sharedController] offset:@"BaseField_Spell_TimeEnd"] ){
			desc = @"Time of cast end";
		}
		else if ( offset == [[OffsetController sharedController] offset:@"BaseField_Spell_TimeStart"] ){
			desc = @"Time of cast start";
		}
		else if ( offset == [[OffsetController sharedController] offset:@"BaseField_Spell_ToCast"] ){
			desc = @"Spell ID to cast";
		}
		else if ( offset == [[OffsetController sharedController] offset:@"BaseField_Spell_Channeling"] ){
			desc = @"Spell ID channeling";
		}
		else if ( offset == [[OffsetController sharedController] offset:@"BaseField_Spell_ChannelTimeStart"] ){
			desc = @"Time of channel start";
		}
		else if ( offset == [[OffsetController sharedController] offset:@"BaseField_Spell_ChannelTimeEnd"] ){
			desc = @"Time of channel end";
		}
		
    } else {
        int revOffset = offset - ([self unitFieldAddress] - [self baseAddress]);

        switch(revOffset) {
            case UNIT_FIELD_CHARM:
                desc = @"Charm (GUID)";
                break;
            case UNIT_FIELD_SUMMON:
                desc = @"Summon (GUID)";
                break;
            case UNIT_FIELD_CRITTER:
                desc = @"Critter (GUID)";
                break;
            case UNIT_FIELD_CHARMEDBY:
                desc = @"Charmed By (GUID)";
                break;
            case UNIT_FIELD_SUMMONEDBY:
                desc = @"Summoned By (GUID)";
                break;
            case UNIT_FIELD_CREATEDBY:
                desc = @"Created By (GUID)";
                break;
            case UNIT_FIELD_TARGET:
                desc = @"Target (GUID)";
                break;
            case UNIT_FIELD_CHANNEL_OBJECT:
                desc = @"Channel Target (GUID)";
                break;
			case UNIT_CHANNEL_SPELL:
                desc = @"Channel Spell";
                break;
			case UNIT_FIELD_BYTES_0:
                desc = @"Info Flags (bytes_0)";
                break;
            case UNIT_FIELD_HEALTH:
                desc = @"Health, Current";
                break;
            case UNIT_FIELD_POWER1:
                desc = @"Mana, Current";
                break;
            case UNIT_FIELD_POWER2:
                desc = @"Rage, Current";
                break;
            case UNIT_FIELD_POWER3:
                desc = @"Focus, Current";
                break;
            case UNIT_FIELD_POWER4:
                desc = @"Energy, Current";
                break;
            case UNIT_FIELD_POWER5:
                desc = @"Happiness, Current";
                break;
			case UNIT_FIELD_POWER6:
                desc = @"Power 6";
                break;
            case UNIT_FIELD_POWER7:
                desc = @"Runic Power, Current";
                break;
			case UNIT_FIELD_POWER8:
                desc = @"Power 8";
                break;
			case UNIT_FIELD_POWER9:
                desc = @"Eclipse Power, Current";
                break;
			case UNIT_FIELD_POWER10:
                desc = @"Power 10";
                break;
			case UNIT_FIELD_POWER11:
                desc = @"Power 11";
                break;

            case UNIT_FIELD_MAXHEALTH:
                desc = @"Health, Max";
                break;
            case UNIT_FIELD_MAXPOWER1:
                desc = @"Mana, Max";
                break;
            case UNIT_FIELD_MAXPOWER2:
                desc = @"Rage, Max";
                break;
            case UNIT_FIELD_MAXPOWER3:
                desc = @"Focus, Max";
                break;
            case UNIT_FIELD_MAXPOWER4:
                desc = @"Energy, Max";
                break;
            case UNIT_FIELD_MAXPOWER5:
                desc = @"Happiness, Max";
                break;
			case UNIT_FIELD_MAXPOWER6:
                desc = @"Power 6, Max";
                break;
            case UNIT_FIELD_MAXPOWER7:
                desc = @"Runic Power, Max";
                break;
			case UNIT_FIELD_MAXPOWER8:
                desc = @"Power 8, Max";
                break;
			case UNIT_FIELD_MAXPOWER9:
                desc = @"Eclipse Power, Max";
                break;
			case UNIT_FIELD_MAXPOWER10:
                desc = @"Power 10, Max";
                break;
			case UNIT_FIELD_MAXPOWER11:
                desc = @"Power 11, Max";
                break;
				
			case UNIT_FIELD_POWER_REGEN_FLAT_MODIFIER:
                desc = @"Regen Modifier";
                break;
            case UNIT_FIELD_POWER_REGEN_INTERRUPTED_FLAT_MODIFIER:
                desc = @"Regen Int Modifier";
                break;

            case UNIT_FIELD_LEVEL:
                desc = @"Level";
                break;
            case UNIT_FIELD_FACTIONTEMPLATE:
                desc = @"Faction";
                break;
            case UNIT_FIELD_FLAGS:
                desc = @"Info Flags (Flags)";
                break;
            case UNIT_FIELD_FLAGS_2:
                desc = @"Status Flags (Flags2)";
                break;

            case UNIT_FIELD_BOUNDINGRADIUS:
                desc = @"Bounding Radius";
                break;
            case UNIT_FIELD_COMBATREACH:
                desc = @"Combat Reach";
                break;
            case UNIT_FIELD_DISPLAYID:
                desc = @"Display ID";
                break;
            case UNIT_FIELD_NATIVEDISPLAYID:
                desc = @"Native Display ID";
                break;
            case UNIT_FIELD_MOUNTDISPLAYID:
                desc = @"Mount Display ID";
                break;

            case UNIT_FIELD_BYTES_1:
                desc = @"Unit Bytes 1";
                break;
				
			case UNIT_FIELD_PETNUMBER:
                desc = @"Pet Number";
                break;

            case UNIT_FIELD_PETEXPERIENCE:
                desc = @"Pet Experience";
                break;
            case UNIT_FIELD_PETNEXTLEVELEXP:
                desc = @"Pet Next Level Experience";
                break;

            case UNIT_DYNAMIC_FLAGS:
                desc = @"Dynamic Flags";
                break;
            case UNIT_MOD_CAST_SPEED:
                desc = @"Cast Speed Modifier";
                break;
            case UNIT_CREATED_BY_SPELL:
                desc = @"Created by Spell";
                break;
            case UNIT_NPC_FLAGS:
                desc = @"NPC Flags";
                break;

            case UNIT_FIELD_BYTES_2:
                desc = @"Unit Bytes 2";
                break;
        }
    }
    
    if(desc) return desc;
    
    return [super descriptionForOffset: offset];
}

@end
