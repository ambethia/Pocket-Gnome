//
//  Node.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 12/27/07.
//  Copyright 2007 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WoWObject.h"
#import "Position.h"

#define NodeNameLoadedNotification @"NodeNameLoadedNotification"


typedef enum eGameObjectFlags {
    GAMEOBJECT_FLAG_IN_USE              = 1,    // disables interaction while animated
    GAMEOBJECT_FLAG_LOCKED              = 2,    // require key, spell, event, etc to be opened. Makes "Locked" appear in tooltip
    GAMEOBJECT_FLAG_CANT_TARGET         = 4,    // cannot interact (condition to interact)
    GAMEOBJECT_FLAG_TRANSPORT           = 8,    // any kind of transport? Object can transport (elevator, boat, car)
    GAMEOBJECT_FLAG_NEVER_DESPAWN       = 32,   // never despawn, typically for doors, they just change state
    GAMEOBJECT_FLAG_TRIGGERED           = 64,   // typically, summoned objects. Triggered by spell or other events
} NodeFlags;

typedef enum eGameObjectTypes {
    GAMEOBJECT_TYPE_DOOR                = 0,
    GAMEOBJECT_TYPE_BUTTON              = 1,
    GAMEOBJECT_TYPE_QUESTGIVER          = 2,
    GAMEOBJECT_TYPE_CONTAINER           = 3,
    GAMEOBJECT_TYPE_BINDER              = 4,
    GAMEOBJECT_TYPE_GENERIC             = 5,
    GAMEOBJECT_TYPE_TRAP                = 6,
    GAMEOBJECT_TYPE_CHAIR               = 7,
    GAMEOBJECT_TYPE_SPELL_FOCUS         = 8,
    GAMEOBJECT_TYPE_TEXT                = 9,
    GAMEOBJECT_TYPE_GOOBER              = 10, // eg, gong of zul'farrak, cove cannon
    GAMEOBJECT_TYPE_TRANSPORT           = 11, // eg, elevator
    GAMEOBJECT_TYPE_AREADAMAGE          = 12,
    GAMEOBJECT_TYPE_CAMERA              = 13,
    GAMEOBJECT_TYPE_MAP_OBJECT          = 14,
    GAMEOBJECT_TYPE_MO_TRANSPORT        = 15, // eg, boat
    GAMEOBJECT_TYPE_DUEL_ARBITER        = 16,
    GAMEOBJECT_TYPE_FISHING_BOBBER      = 17,
    GAMEOBJECT_TYPE_RITUAL              = 18,
    GAMEOBJECT_TYPE_MAILBOX             = 19,
    GAMEOBJECT_TYPE_AUCTIONHOUSE        = 20,
    GAMEOBJECT_TYPE_GUARDPOST           = 21,
    GAMEOBJECT_TYPE_PORTAL              = 22,
    GAMEOBJECT_TYPE_MEETING_STONE       = 23,
    GAMEOBJECT_TYPE_FLAGSTAND           = 24,
    GAMEOBJECT_TYPE_FISHINGHOLE         = 25,
    GAMEOBJECT_TYPE_FLAGDROP            = 26,
    GAMEOBJECT_TYPE_MINI_GAME           = 27,
    GAMEOBJECT_TYPE_LOTTERY_KIOSK       = 28,
    GAMEOBJECT_TYPE_CAPTURE_POINT       = 29,
    GAMEOBJECT_TYPE_AURA_GENERATOR      = 30,
    GAMEOBJECT_TYPE_DUNGEON_DIFFICULTY  = 31,
    GAMEOBJECT_TYPE_BARBER_CHAIR          = 32,   // barbershop?
    GAMEOBJECT_TYPE_DESTRUCTIBLE_BUILDING = 33,
    GAMEOBJECT_TYPE_GUILDBANK           = 34,
    GAMEOBJECT_TYPE_TRAPDOOR            = 35,   // see the Well in Dalaran
} GameObjectType;

@interface Node : WoWObject <UnitPosition> {
    NSString *_name;
    UInt32 _nameEntryID;
    
    // NSURLConnection *_connection;
    // NSMutableData *_downloadData;
}
+ (id)nodeWithAddress: (NSNumber*)address inMemory: (MemoryAccess*)memory;

- (BOOL)validToLoot;

- (GUID)owner;
- (UInt32)nodeType;
- (NodeFlags)flags;

- (UInt8)objectHealth;

- (UInt16)alpha;
//- (void)monitor;

- (NSString*)stringForNodeType: (UInt32)typeID;
- (NSImage*)imageForNodeType: (UInt32)typeID;
- (BOOL)isUseable;
// - (void)loadNodeName;

@end
