//
//  LootController.h
//  Pocket Gnome
//
//  Created by Josh on 6/7/09.
//  Copyright 2009 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define ItemLootedNotification @"ItemLootedNotification"
#define AllItemsLootedNotification @"AllItemsLootedNotification"

@class Controller;
@class InventoryController;
@class ChatController;
@class PlayerDataController;
@class OffsetController;
@class MacroController;

@interface LootController : NSObject {
    IBOutlet Controller             *controller;
	IBOutlet InventoryController	*itemController;
	IBOutlet ChatController			*chatController;
	IBOutlet PlayerDataController	*playerDataController;
	IBOutlet OffsetController		*offsetController;
	IBOutlet MacroController		*macroController;
	
	NSMutableDictionary	*_itemsLooted;
	
	int		_lastLootedItem;
	BOOL _shouldMonitor;
}

- (NSDictionary*)itemsLooted;
- (void)resetLoot;

- (BOOL)isLootWindowOpen;
- (void)acceptLoot;
@end
