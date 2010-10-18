//
//  Item.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 12/20/07.
//  Copyright 2007 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MemoryAccess.h"
#import "WoWObject.h"

#define ItemNameLoadedNotification @"ItemNameLoadedNotification"

typedef enum {
	ItemType_Consumable     = 0,
	ItemType_Container,
	ItemType_Weapon,
	ItemType_Gem,
	ItemType_Armor,
	ItemType_Reagent,
	ItemType_Projectile,
	ItemType_TradeGoods,
	ItemType_Generic,
	ItemType_Recipe,
	ItemType_Money,
	ItemType_Quiver,
	ItemType_Quest,
	ItemType_Key,
	ItemType_Permanent,
	ItemType_Misc,
	ItemType_Glyph,
    ItemType_Max            = 16
} ItemType;

@interface Item : WoWObject {
    NSString *_name;
	
	UInt32 _itemFieldsAddress;
    
    NSURLConnection *_connection;
    NSMutableData *_downloadData;
}
+ (id)itemWithAddress: (NSNumber*)address inMemory: (MemoryAccess*)memory;

- (NSString*)name;
- (void)setName: (NSString*)name;
- (void)loadName;

- (ItemType)itemType;
- (NSString*)itemTypeString;
+ (NSString*)stringForItemType: (ItemType)type;
- (NSString*)itemSubtypeString;

- (GUID)ownerUID;
- (GUID)containerUID;
- (GUID)creatorUID;
- (GUID)giftCreatorUID;
- (UInt32)count;
- (UInt32)duration;
- (UInt32)charges;
- (NSNumber*)durability;
- (NSNumber*)maxDurability;

- (UInt32)flags;
- (UInt32)infoFlags;
- (UInt32)infoFlags2;

// Enchantment info
- (UInt32)hasPermEnchantment;
- (UInt32)hasTempEnchantment;

- (BOOL)isBag;
- (BOOL)isSoulbound;

- (UInt32)bagSize;
- (UInt64)itemGUIDinSlot: (UInt32)slotNum;

@end
