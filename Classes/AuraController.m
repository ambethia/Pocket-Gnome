//
//  AuraController.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 12/26/07.
//  Copyright 2007 Savory Software, LLC. All rights reserved.
//

#import "AuraController.h"
#import "Controller.h"
#import "PlayerDataController.h"
#import "SpellController.h"
#import "MobController.h"

#import "MemoryAccess.h"
#import "Offsets.h"
#import "Spell.h"

#import "Unit.h"
#import "Aura.h"


@implementation AuraController


static AuraController* sharedController = nil;

+ (AuraController *)sharedController {
	if (sharedController == nil)
		sharedController = [[[self class] alloc] init];
	return sharedController;
}

- (id) init
{
	if(sharedController) {
		[self release];
		self = sharedController;
	} else if(self != nil) {
        sharedController = self;

        _auras = [[NSMutableArray array] retain];
        _playerAuras = [[NSMutableArray array] retain];
        _firstRun = YES;

        // wow memory access validity notifications
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(playerIsInvalid:) 
                                                     name: PlayerIsInvalidNotification 
                                                   object: nil];
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(playerIsValid:) 
                                                     name: PlayerIsValidNotification 
                                                   object: nil];
    }
    return self;
}

- (void) dealloc{
    [_playerAuras release];
    [_auras release];
    [super dealloc];
}

- (void)awakeFromNib {
    [aurasPanel setCollectionBehavior: NSWindowCollectionBehaviorCanJoinAllSpaces];
}

- (void)playerIsValid: (NSNotification*)notification {
    [self performSelector: @selector(scanAllBuffs:) withObject: nil afterDelay: 1.0];
}

- (void)playerIsInvalid: (NSNotification*)notification {
    [NSObject cancelPreviousPerformRequestsWithTarget: self];
    [_auras removeAllObjects];
}


- (void)showAurasPanel {
    [aurasPanel makeKeyAndOrderFront: self];
}

#pragma mark -

typedef struct WoWAura {
    GUID    guid;
    UInt32  entryID;
    UInt32  bytes;
    UInt32  duration;
    UInt32  expiration;
	UInt32	unk1;
	UInt32	unk2;
	UInt32	unk3;
} WoWAura;



/*
 read +0xDB4
 if -1 then
 table is at:
 pointer(+0xC4C)
 else
 table is at +0xC34
 
 0xDB8 is valid count?
 
 */

- (NSArray*)aurasForUnit: (Unit*)unit idsOnly: (BOOL)IDs {
    // log(LOG_GENERAL, @"Loading for unit: %@ (0x%X)", unit, [unit baseAddress]);
    UInt32 validAuras = 0;
    MemoryAccess *wowMemory = [controller wowMemoryAccess];
    if(!unit || !wowMemory || ![playerController playerIsValid:self])
        return nil;
    
    // get the number of valid aura buckets
    [wowMemory readAddress: ([unit baseAddress] + BaseField_Auras_ValidCount) Buffer: (Byte*)&validAuras BufLength: sizeof(validAuras)];
	
    // we're overflowing. try the backup.
    if ( validAuras == 0xFFFFFFFF) {
        [wowMemory readAddress: ([unit baseAddress] + BaseField_Auras_OverflowValidCount) Buffer: (Byte*)&validAuras BufLength: sizeof(validAuras)];
		log(LOG_GENERAL, @"[Auras] Lot of auras! Switching to backup!");
	}
    
    if ( validAuras <= 0 || validAuras > 500 ) {
		log(LOG_GENERAL, @"[Auras] Not a valid aura count %d", validAuras);
		return nil;
	}
	
    UInt32 aurasAddress = [unit baseAddress] + BaseField_Auras_Start;
    if ( validAuras > 16 ) {
		
        // aura overflow
        UInt32 newAddr = 0;
        if([wowMemory loadDataForObject: self atAddress: ([unit baseAddress] + BaseField_Auras_OverflowPtr1) Buffer: (Byte*)&newAddr BufLength: sizeof(newAddr)] && newAddr) {
            aurasAddress = newAddr;
        } else {
            log(LOG_GENERAL, @"[Auras] Error finding aura overflow pointer.");
            return nil;
        }
    }
	
	//log(LOG_GENERAL, @"[Auras] Address start: 0x%X", aurasAddress);
    
    
    int i;
    // GUID unitGUID = [unit GUID];
    // UInt32 currentTime = [playerController currentTime];
    NSMutableArray *auras = [NSMutableArray array];
    for(i=0; i< validAuras; i++) {
        WoWAura aura;
        if([wowMemory loadDataForObject: self atAddress: (aurasAddress) + i*sizeof(aura) Buffer:(Byte*)&aura BufLength: sizeof(aura)]) {
            aura.bytes = CFSwapInt32HostToLittle(aura.bytes);
			
			//log(LOG_GENERAL, @"[auras] Bytes: %d", aura.bytes);
			//log(LOG_GENERAL, @"[Auras] 0x%X Entry ID: %d", (aurasAddress) + i*sizeof(aura), aura.entryID);
			
            // skip empty buckets
            if(aura.entryID == 0) continue;
            
			// As of 3.1.0 - I don't think expiration is needed, if you remove the buff, it sets that memory space to 0
            // skip expired buffs; they seem to linger until the space is needed for something else
            /*if((currentTime > aura.expiration) && (aura.expiration != 0)) {
                log(LOG_GENERAL, @"%d is expired (%d).", aura.entryID, aura.expiration);
                continue;
            }*/
            
            // if we get here, the spell ID is valid and the expiration time is good
            // the GUID is that of the casting player
            // it is 0 for invalid auras, but can also be 0 for environmental auras (world buffs)
            
            // is the aura ours or something elses?
            // i dont think we're going to bother differentiating for the time being
            // but there's the damn code
            /*
            if(aura.guid == unitGUID) {
                
            } else {
                // is it environmental?
                if(aura.guid == 0) {
                    
                }
                
                // is it another player?
                if( GUID_HIPART(aura.guid) == HIGHGUID_PLAYER) {
                    
                }
                
                // is it a mob?
                if(GUID_HIPART(aura.guid) == HIGHGUID_UNIT) {
                    
                }
            }*/
            
            if(IDs) [auras addObject: [NSNumber numberWithUnsignedInt: aura.entryID]];
            else    [auras addObject: [Aura auraEntryID: aura.entryID 
                                                   GUID: aura.guid
                                                  bytes: aura.bytes 
                                               duration: aura.duration 
                                             expiration: aura.expiration]];
            
            //log(LOG_GENERAL, @"Found aura %d.", aura.entryID);
        }
    }
    
    return auras;
}

- (BOOL)unit: (Unit*)unit hasAura: (unsigned)spellID {
    for(Aura *aura in [self aurasForUnit: unit idsOnly: NO]) {
        if(aura.entryID == spellID)
            return aura.stacks ? aura.stacks : YES;
    }
    return NO;
}

- (BOOL)unit: (Unit*)unit hasBuff: (unsigned)spellID {
    for(Aura *aura in [self aurasForUnit: unit idsOnly: NO]) {
        if((aura.entryID == spellID) && (!aura.isDebuff))
            return aura.stacks ? aura.stacks : YES;
    }
    return NO;
}

- (BOOL)unit: (Unit*)unit hasDebuff: (unsigned)spellID {
    for(Aura *aura in [self aurasForUnit: unit idsOnly: NO]) {
        if((aura.entryID == spellID) && (aura.isDebuff))
            return aura.stacks ? aura.stacks : YES;
    }
    return NO;
}

- (BOOL)unit: (Unit*)unit hasAuraNamed: (NSString*)spellName {
    for(Aura *aura in [self aurasForUnit: unit idsOnly: NO]) {
        Spell *spell;
        if( (spell = [spellController spellForID: [NSNumber numberWithInt: aura.entryID]]) && [spell name]) {
            NSRange range = [[spell name] rangeOfString: spellName 
                                                options: NSCaseInsensitiveSearch | NSAnchoredSearch | NSDiacriticInsensitiveSearch];
            if(range.location != NSNotFound) {
                //log(LOG_GENERAL, @"Found player buff '%@' at index %d.", spellName, i);
                return aura.stacks ? aura.stacks : YES;
            }
        }
    }
    return NO;
}


- (BOOL)unit: (Unit*)unit hasBuffNamed: (NSString*)spellName {
    for(Aura *aura in [self aurasForUnit: unit idsOnly: NO]) {
        Spell *spell;
        if( (!aura.isDebuff) && (spell = [spellController spellForID: [NSNumber numberWithInt: aura.entryID]]) && [spell name]) {
            NSRange range = [[spell name] rangeOfString: spellName 
                                                options: NSCaseInsensitiveSearch | NSAnchoredSearch | NSDiacriticInsensitiveSearch];
            if(range.location != NSNotFound) {
                //log(LOG_GENERAL, @"Found player buff '%@' at index %d.", spellName, i);
                return aura.stacks ? aura.stacks : YES;
            }
        }
    }
    return NO;
}

- (BOOL)unit: (Unit*)unit hasDebuffNamed: (NSString*)spellName {
    for(Aura *aura in [self aurasForUnit: unit idsOnly: NO]) {
        Spell *spell;
        if( (aura.isDebuff) && (spell = [spellController spellForID: [NSNumber numberWithInt: aura.entryID]]) && [spell name]) {
            NSRange range = [[spell name] rangeOfString: spellName 
                                                options: NSCaseInsensitiveSearch | NSAnchoredSearch | NSDiacriticInsensitiveSearch];
            if(range.location != NSNotFound) {
                //log(LOG_GENERAL, @"Found player buff '%@' at index %d.", spellName, i);
                return aura.stacks ? aura.stacks : YES;
            }
        }
    }
    return NO;
}


- (BOOL)unit: (Unit*)unit hasAuraType: (NSString*)type {
    for(Aura *aura in [self aurasForUnit: unit idsOnly: NO]) {
        Spell *spell;
        if( (spell = [spellController spellForID: [NSNumber numberWithInt: aura.entryID]]) && [spell dispelType]) {
            if( [type isEqualToString: [spell dispelType]] ) {
                return YES;
            }
        }
    }
    return NO;
}

- (BOOL)unit: (Unit*)unit hasBuffType: (NSString*)type {
    for(Aura *aura in [self aurasForUnit: unit idsOnly: NO]) {
        Spell *spell;
        if( (!aura.isDebuff) && (spell = [spellController spellForID: [NSNumber numberWithInt: aura.entryID]]) && [spell dispelType]) {
            if( [type isEqualToString: [spell dispelType]] ) {
                return YES;
            }
        }
    }
    return NO;
}

- (BOOL)unit: (Unit*)unit hasDebuffType: (NSString*)type {
    for(Aura *aura in [self aurasForUnit: unit idsOnly: NO]) {
        Spell *spell;
        if( (aura.isDebuff) && (spell = [spellController spellForID: [NSNumber numberWithInt: aura.entryID]]) && [spell dispelType]) {
            if( [type isEqualToString: [spell dispelType]] ) {
                return YES;
            }
        }
    }
    return NO;
}

/*
- (BOOL)loadAurasFrom: (unsigned) address intoArray: (Byte*)auraArray ofSize: (unsigned)size {
    // get WoW memory and player structure
    MemoryAccess *wowMemory = [controller wowMemoryAccess];
    if(!wowMemory) return NO;
    
    if([wowMemory loadDataForObject: self atAddress: address Buffer: (Byte*)auraArray BufLength: sizeof(unsigned)*size]) {
        return YES;
    }
    return NO;
}

- (UInt8)getStackCountAtAddress: (UInt32)address {
    // figure how many applications of this buff there are
    UInt8 stacks = 0;
    if([[controller wowMemoryAccess] loadDataForObject: self atAddress: address Buffer: (Byte*)&stacks BufLength: sizeof(stacks)]) {
        if(stacks == 0xFF)  stacks = 1;
        else                stacks++;
    } else {
        stacks = 1;
    }
    
    return stacks;
}*/

/*
- (BOOL)playerHasBuff: (unsigned)spellID {
    if(!spellID || ![playerController playerIsValid:self]) return NO;
    
    unsigned auras[PLAYER_BUFF_SLOTS];
    if([self loadAurasFrom: ([playerController infoAddress] + PLAYER_BUFFS_OFFSET) intoArray: (Byte*)&auras ofSize: PLAYER_BUFF_SLOTS]) {
        unsigned i;
        for(i=0; i<PLAYER_BUFF_SLOTS; i++) {
            if(auras[i] == 0) continue;
            if(auras[i] == spellID) {
                //log(LOG_GENERAL, @"Found player buff %d at index %d.", spellID, i);
                return YES;
            }
        }
    }
    return NO;
}
    
- (BOOL)playerHasDebuff: (unsigned)spellID {
    if(!spellID || ![playerController playerIsValid:self]) return NO;
    
    unsigned auras[PLAYER_DEBUFF_SLOTS];
    if([self loadAurasFrom: ([playerController infoAddress] + PLAYER_DEBUFFS_OFFSET) intoArray: (Byte*)&auras ofSize: PLAYER_DEBUFF_SLOTS]) {
        unsigned i;
        for(i=0; i<PLAYER_DEBUFF_SLOTS; i++) {
            if(auras[i] == 0) continue;
            if(auras[i] == spellID) {
                //log(LOG_GENERAL, @"Found player debuff %d at index %d.", spellID, i);
                return YES;
            }
        }
    }
    return NO;
}

- (BOOL)playerHasBuffNamed: (NSString*)spellName {
    if(!spellName || ![spellName length] || ![playerController playerIsValid:self]) return NO;
    
    unsigned auras[PLAYER_BUFF_SLOTS];
    if([self loadAurasFrom: ([playerController infoAddress] + PLAYER_BUFFS_OFFSET) intoArray: (Byte*)&auras ofSize: PLAYER_BUFF_SLOTS]) {
        unsigned i;
        Spell *spell;
        for(i=0; i<PLAYER_BUFF_SLOTS; i++) {
            if(auras[i] == 0) continue;
            if( (spell = [spellController spellForID: [NSNumber numberWithInt: auras[i]]]) && [spell name]) {
                NSRange range = [[spell name] rangeOfString: spellName 
                                                    options: NSCaseInsensitiveSearch | NSAnchoredSearch | NSDiacriticInsensitiveSearch];
                if(range.location != NSNotFound) {
                    //log(LOG_GENERAL, @"Found player buff '%@' at index %d.", spellName, i);
                    return YES;
                }
            }
        }
    }
    return NO;
}

- (BOOL)playerHasDebuffNamed: (NSString*)spellName {
    if(!spellName || ![spellName length] || ![playerController playerIsValid:self]) return NO;
    
    unsigned auras[PLAYER_DEBUFF_SLOTS];
    if([self loadAurasFrom: ([playerController infoAddress] + PLAYER_DEBUFFS_OFFSET) intoArray: (Byte*)&auras ofSize: PLAYER_DEBUFF_SLOTS]) {
        unsigned i;
        Spell *spell;
        for(i=0; i<PLAYER_DEBUFF_SLOTS; i++) {
            if(auras[i] == 0) continue;
            if( (spell = [spellController spellForID: [NSNumber numberWithInt: auras[i]]]) && [spell name]) {
                NSRange range = [[spell name] rangeOfString: spellName 
                                                    options: NSCaseInsensitiveSearch | NSAnchoredSearch | NSDiacriticInsensitiveSearch];
                if(range.location != NSNotFound) {
                    //log(LOG_GENERAL, @"Found player debuff '%@' at index %d.", spellName, i);
                    return YES;
                }
            }
        }
    }
    return NO;
}

- (BOOL)unit: (Unit*)unit hasBuffType: (NSString*)type {
    if(!type || ![unit isValid]) return NO;
    
    int typeID = [unit objectTypeID];
    int slots = (typeID == TYPEID_UNIT) ? MOB_BUFF_SLOTS : PLAYER_BUFF_SLOTS;
    int offset = (typeID == TYPEID_UNIT) ? MOB_BUFFS_OFFSET : PLAYER_BUFFS_OFFSET;
    
    unsigned auras[slots];
    if([self loadAurasFrom: ([unit infoAddress] + offset) intoArray: (Byte*)&auras ofSize: slots]) {
        unsigned i;
        Spell *spell;
        for(i=0; i<slots; i++) {
            if(auras[i] == 0) continue;
            if( (spell = [spellController spellForID: [NSNumber numberWithInt: auras[i]]]) && [spell dispelType]) {
                if( [type isEqualToString: [spell dispelType]] ) {
                    return YES;
                }
            }
        }
    }
    return NO;
}

- (BOOL)unit: (Unit*)unit hasDebuffType: (NSString*)type {
    if(!type || ![unit isValid]) return NO;
    
    int typeID = [unit objectTypeID];
    int slots = (typeID == TYPEID_UNIT) ? MOB_DEBUFF_SLOTS : PLAYER_DEBUFF_SLOTS;
    int offset = (typeID == TYPEID_UNIT) ? MOB_DEBUFFS_OFFSET : PLAYER_DEBUFFS_OFFSET;
    
    unsigned auras[slots];
    if([self loadAurasFrom: ([unit infoAddress] + offset) intoArray: (Byte*)&auras ofSize: slots]) {
        unsigned i;
        Spell *spell;
        for(i=0; i<slots; i++) {
            if(auras[i] == 0) continue;
            if( (spell = [spellController spellForID: [NSNumber numberWithInt: auras[i]]]) && [spell dispelType]) {
                if( [type isEqualToString: [spell dispelType]] ) {
                    return YES;
                }
            }
        }
    }
    return NO;
}

- (BOOL)unit: (Unit*)unit hasBuff: (unsigned)spellID {
    if(!spellID || ![unit isValid]) return NO;
    
    int typeID = [unit objectTypeID];
    int slots = (typeID == TYPEID_UNIT) ? MOB_BUFF_SLOTS : PLAYER_BUFF_SLOTS;
    int offset = (typeID == TYPEID_UNIT) ? MOB_BUFFS_OFFSET : PLAYER_BUFFS_OFFSET;
    
    unsigned auras[slots];
    if([self loadAurasFrom: ([unit infoAddress] + offset) intoArray: (Byte*)&auras ofSize: slots]) {
        unsigned i;
        for(i=0; i<slots; i++) {
            if(auras[i] == 0) continue;
            if(auras[i] == spellID) {
                return [self getStackCountAtAddress: ([unit infoAddress] + UnitField_AuraStacks + i)];
            }
        }
    }
    return NO;
}

- (BOOL)unit: (Unit*)unit hasDebuff: (unsigned)spellID {
    if(!spellID || ![unit isValid]) return NO;
    
    int typeID = [unit objectTypeID];
    int buffSlots = (typeID == TYPEID_UNIT) ? MOB_BUFF_SLOTS : PLAYER_BUFF_SLOTS;
    int slots = (typeID == TYPEID_UNIT) ? MOB_DEBUFF_SLOTS : PLAYER_DEBUFF_SLOTS;
    int offset = (typeID == TYPEID_UNIT) ? MOB_DEBUFFS_OFFSET : PLAYER_DEBUFFS_OFFSET;
    
    unsigned auras[slots];
    if([self loadAurasFrom: ([unit infoAddress] + offset) intoArray: (Byte*)&auras ofSize: slots]) {
        unsigned i;
        for(i=0; i<slots; i++) {
            if(auras[i] == 0) continue;
            if(auras[i] == spellID) {
                return [self getStackCountAtAddress: ([unit infoAddress] + (UnitField_AuraStacks + buffSlots) + i)];
            }
        }
    }
    return NO;
}

- (BOOL)unit: (Unit*)unit hasBuffNamed: (NSString*)spellName {
    if(!spellName || ![spellName length] || ![unit isValid]) return NO;
    
    int typeID = [unit objectTypeID];
    int slots = (typeID == TYPEID_UNIT) ? MOB_BUFF_SLOTS : PLAYER_BUFF_SLOTS;
    int offset = (typeID == TYPEID_UNIT) ? MOB_BUFFS_OFFSET : PLAYER_BUFFS_OFFSET;
    
    unsigned auras[slots];
    if([self loadAurasFrom: ([unit infoAddress] + offset) intoArray: (Byte*)&auras ofSize: slots]) {
        unsigned i;
        Spell *spell;
        for(i=0; i<slots; i++) {
            if(auras[i] == 0) continue;
            if( (spell = [spellController spellForID: [NSNumber numberWithInt: auras[i]]]) && [spell name]) {
                NSRange range = [[spell name] rangeOfString: spellName 
                                                    options: NSCaseInsensitiveSearch | NSAnchoredSearch | NSDiacriticInsensitiveSearch];
                if(range.location != NSNotFound) {
                    return [self getStackCountAtAddress: ([unit infoAddress] + UnitField_AuraStacks + i)];
                }
            }
        }
    }
    return NO;
}

- (BOOL)unit: (Unit*)unit hasDebuffNamed: (NSString*)spellName {
    if(!spellName || ![spellName length] || ![unit isValid]) return NO;
    
    int typeID = [unit objectTypeID];
    int buffSlots = (typeID == TYPEID_UNIT) ? MOB_BUFF_SLOTS : PLAYER_BUFF_SLOTS;
    int slots = (typeID == TYPEID_UNIT) ? MOB_DEBUFF_SLOTS : PLAYER_DEBUFF_SLOTS;
    int offset = (typeID == TYPEID_UNIT) ? MOB_DEBUFFS_OFFSET : PLAYER_DEBUFFS_OFFSET;
    
    unsigned auras[slots];
    if([self loadAurasFrom: ([unit infoAddress] + offset) intoArray: (Byte*)&auras ofSize: slots]) {
        unsigned i;
        Spell *spell;
        for(i=0; i<slots; i++) {
            if(auras[i] == 0) continue;
            if( (spell = [spellController spellForID: [NSNumber numberWithInt: auras[i]]]) && [spell name]) {
                NSRange range = [[spell name] rangeOfString: spellName 
                                                    options: NSCaseInsensitiveSearch | NSAnchoredSearch | NSDiacriticInsensitiveSearch];
                if(range.location != NSNotFound) {
                    return [self getStackCountAtAddress: ([unit infoAddress] + (UnitField_AuraStacks + buffSlots) + i)];
                }
            }
        }
    }
    return NO;
}
*/
#pragma mark -

// 3 loads
- (void)scanAllBuffs: (id)sender {
    // get WoW memory and player structure
    MemoryAccess *wowMemory = [controller wowMemoryAccess];
    
    if(wowMemory && [playerController playerIsValid:self]) {
        
        // unsigned i;
        
        [_playerAuras removeAllObjects];
        NSArray *newAuras = [self aurasForUnit: (Unit*)[playerController player] idsOnly: NO];
        NSArray *petAuras = [self aurasForUnit: [playerController pet] idsOnly: YES];
        NSArray *tarAuras = [self aurasForUnit: [mobController playerTarget] idsOnly: YES];
        
        // log(LOG_GENERAL, @"%d buffs on player", [newAuras count]);
        
        // gather all buffs
        /*unsigned buffs[PLAYER_BUFF_SLOTS];
        if([self loadAurasFrom: ([playerController infoAddress] + PLAYER_BUFFS_OFFSET) intoArray: (Byte*)&buffs ofSize: PLAYER_BUFF_SLOTS]) {
            for(i=0; i<PLAYER_BUFF_SLOTS; i++) {
                if(buffs[i])        [newAuras addObject: [NSNumber numberWithUnsignedInt: buffs[i]]];
            }
        }
        
        // gather all debuffs
        unsigned debuffs[PLAYER_DEBUFF_SLOTS];
        if([self loadAurasFrom: ([playerController infoAddress] + PLAYER_DEBUFFS_OFFSET) intoArray: (Byte*)&debuffs ofSize: PLAYER_DEBUFF_SLOTS]) {
            for(i=0; i<PLAYER_DEBUFF_SLOTS; i++) {
                if(debuffs[i])      [newAuras addObject: [NSNumber numberWithUnsignedInt: debuffs[i]]];
            }
        }
        
        // gather all pet auras
        if( [playerController pet] && [[playerController pet] isValid] ) {
            int auraSlots = MOB_BUFF_SLOTS + MOB_DEBUFF_SLOTS;
            unsigned auras[auraSlots];
            if([self loadAurasFrom: ([[playerController pet] infoAddress] + MOB_BUFFS_OFFSET) intoArray: (Byte*)&auras ofSize: auraSlots]) {
                for(i=0; i<auraSlots; i++) {
                    if(auras[i])      [petAuras addObject: [NSNumber numberWithUnsignedInt: auras[i]]];
                }
            }
        }
        
        // gather all target auras
        Unit *target = [mobController playerTarget];
        if( [target isValid] ) {
            int auraSlots = MOB_BUFF_SLOTS + MOB_DEBUFF_SLOTS;
            unsigned auras[auraSlots];
            if([self loadAurasFrom: ([target infoAddress] + MOB_BUFFS_OFFSET) intoArray: (Byte*)&auras ofSize: auraSlots]) {
                for(i=0; i<auraSlots; i++) {
                    if(auras[i])      [tarAuras addObject: [NSNumber numberWithUnsignedInt: auras[i]]];
                }
            }
        }*/
        
        // report status
        // log(LOG_GENERAL, @"Player has %d buffs and %d debuffs.", [buffsArray count], [debuffsArray count]);
        
        // check for buff losses
        for(Aura *aura in _auras) {
        
            // see if it exists
            BOOL foundAura = NO;
            for(Aura *newAura in newAuras) {
                if(newAura.entryID == aura.entryID) {
                    foundAura = YES;
                    break;
                }
            }
        
            if( !foundAura && (aura.entryID > 0) && (aura.entryID  <= MaxSpellID) ) {
                Spell *spell = [spellController spellForID: [NSNumber numberWithUnsignedInt: aura.entryID]];
                if(spell) {
                    // log(LOG_GENERAL, @"::: %@ fades from you.", spell);
                    [[NSNotificationCenter defaultCenter] postNotificationName: BuffFadeNotification 
                                                                        object: self 
                                                                      userInfo: [NSDictionary dictionaryWithObject: spell forKey: @"Spell"]];
                }
            }
        }
        
        // then check for buff gains
        UInt32 currentTime = [playerController currentTime];
        int order = 0;
        for(Aura *aura in newAuras) {
            order++;
            
            // see if it exists
            BOOL foundAura = NO;
            for(Aura *oldAura in _auras) {
                if(oldAura.entryID == aura.entryID) {
                    foundAura = YES;
                    break;
                }
            }
            
            NSNumber *auraID = [NSNumber numberWithUnsignedInt: [aura entryID]];
            if( !foundAura && ([aura entryID] > 0) && ([aura entryID] <= MaxSpellID) ) {
                // check to see if we know of this spell
                if( ![spellController spellForID: auraID] ) {
                    [spellController addSpellAsRecognized: [Spell spellWithID: auraID]];
                }
                
                // reload the spell name if we dont have it
                Spell *spell = [spellController spellForID: auraID];
                if(spell) {
                    // log(LOG_GENERAL, @"::: You gain %@.", spell);
                    [[NSNotificationCenter defaultCenter] postNotificationName: BuffGainNotification 
                                                                        object: self 
                                                                      userInfo: [NSDictionary dictionaryWithObject: spell forKey: @"Spell"]];
                    
                    if(spell && (![spell name] || ![[spell name] length])) {
                        [spell reloadSpellData];
                    }
                } else {
                    // log(LOG_GENERAL, @"[Auras] Failed to create valid spell from ID %@.", num);
                }
            }
            
            // build our info dict for the auras window
            Spell *spell = [[SpellController sharedSpells] spellForID: auraID];
            NSString *name = ([spell name] ? [spell name] : @"(Unknown)");

            float timeRemaining = [aura expiration] ? ([aura expiration] - currentTime)/1000.0f : INFINITY;
            NSDate *expiration = [aura expiration] ? [NSDate dateWithTimeIntervalSinceNow: timeRemaining] : [NSDate distantFuture];
            
            int i;
            NSString *bytes = [NSString string];
            for(i=31; i>=0; i--) {
                bytes = [bytes stringByAppendingString: ((aura.bytes >> i)&0x1) ? @"1" : @"0"];
                if(i == 24 || i == 16 || i == 8) {
                    bytes = [bytes stringByAppendingString: @" | "];
                }
            }
            //NSString *bytes = [NSString stringWithFormat: @"[%X] [%X] [%X] [%X]", (aura.bytes >> 24)&0xFF, (aura.bytes >> 16)&0xFF, (aura.bytes >> 8)&0xFF, (aura.bytes >> 0)&0xFF];
            
            [_playerAuras addObject: [NSDictionary dictionaryWithObjectsAndKeys:
                                      aura,                                                 @"Aura",
                                      [NSNumber numberWithInt: order],                      @"Order",
                                      auraID,                                               @"ID",
                                      name,                                                 @"Name",
                                      [NSNumber numberWithUnsignedInt: aura.stacks],        @"Stacks",
                                      [NSNumber numberWithUnsignedInt: aura.level],         @"Level",
                                      [NSNumber numberWithFloat: [aura duration]/1000.0f],  @"Duration",
                                      expiration,                                           @"Expiration",
                                      [NSNumber numberWithFloat: timeRemaining],            @"TimeRemaining",
                                      bytes,         @"Bytes",
                                      nil]];
            
        }
        
        // then go and add pet spells
        for(NSNumber *num in petAuras) {
            // check to see if we know of this spell
            if( ![spellController spellForID: num] ) {
                [spellController addSpellAsRecognized: [Spell spellWithID: num]];
            }
            
            // reload the spell name if we dont have it
            Spell *spell = [spellController spellForID: num];
            if( spell && (![spell name] || ![[spell name] length])) {
                [spell reloadSpellData];
                // log(LOG_GENERAL, @"Loading pet spell %@", num);
            }
        }
        
        // then go and add target spells
        for(NSNumber *num in tarAuras) {
            // check to see if we know of this spell
            if( ![spellController spellForID: num] ) {
                [spellController addSpellAsRecognized: [Spell spellWithID: num]];
            }
            
            // reload the spell name if we dont have it
            Spell *spell = [spellController spellForID: num];
            if( spell && (![spell name] || ![[spell name] length])) {
                [spell reloadSpellData];
                // log(LOG_GENERAL, @"Loading target spell %@", num);
            }
        }
        
        // remove all the old buffs and add the new ones
        [_auras removeAllObjects];
        [_auras addObjectsFromArray: newAuras];
        
        [_playerAuras sortUsingDescriptors: [aurasPanelTable sortDescriptors]];
        [aurasPanelTable reloadData];
    }

    _firstRun = NO;
    [self performSelector: @selector(scanAllBuffs:) withObject: nil afterDelay: 1.0];
}


#pragma mark -
#pragma mark Auras Delesource


- (int)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [_playerAuras count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
    if(rowIndex == -1 || rowIndex >= [_playerAuras count]) return nil;
    
    Aura *aura = [[_playerAuras objectAtIndex: rowIndex] objectForKey: @"Aura"];
    if([[aTableColumn identifier] isEqualToString: @"TimeRemaining"]) {
        //NSDate *exp = [[_playerAuras objectAtIndex: rowIndex] objectForKey: @"Expiration"];
        //NSCalendarDate *date = [NSCalendarDate calendarDate];
        //date = [date dateByAddingYears: 0 months: 0 days: 0 hours: 0 minutes: 0 seconds: [exp timeIntervalSinceNow]];
    
        float secRemaining = [[[_playerAuras objectAtIndex: rowIndex] objectForKey: [aTableColumn identifier]] floatValue];
        if(secRemaining < 60.0f) {
            return [NSString stringWithFormat: @"%.0f sec", secRemaining];
        } else if(secRemaining < 3600.0f) {
            return [NSString stringWithFormat: @"%.0f min", secRemaining/60.0f];
        } else if(secRemaining < 86400.0f) {
            return [NSString stringWithFormat: @"%.0f hour", secRemaining/3600.0f];
        } else {
            if([aura isPassive])
                return @"Passive";
            else if(![aura isActive])
                return @"Innate";
            return @"Never";
        }
    }
    
    if([[aTableColumn identifier] isEqualToString: @"Name"]) {
        NSString *name = [[_playerAuras objectAtIndex: rowIndex] objectForKey: @"Name"];
        NSNumber *stacks = [[_playerAuras objectAtIndex: rowIndex] objectForKey: @"Stacks"];
        return [NSString stringWithFormat: @"[%@] %@", stacks, name];
    }
    
    return [[_playerAuras objectAtIndex: rowIndex] objectForKey: [aTableColumn identifier]];
}

- (void)tableView: (NSTableView *)aTableView willDisplayCell: (id)aCell forTableColumn: (NSTableColumn *)aTableColumn row: (int)rowIndex
{
    if( rowIndex == -1 || rowIndex >= [_playerAuras count]) return;
    
    Aura *aura = [[_playerAuras objectAtIndex: rowIndex] objectForKey: @"Aura"];
    
    if([aura isDebuff]) {
        [aCell setTextColor: [NSColor redColor]];
        return;
    }
    
    [aCell setTextColor: [NSColor blackColor]];
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    return NO;
}

- (void)tableView:(NSTableView *)aTableView  sortDescriptorsDidChange:(NSArray *)oldDescriptors {
    [_playerAuras sortUsingDescriptors: [aurasPanelTable sortDescriptors]];
    [aurasPanelTable reloadData];
}

@end
