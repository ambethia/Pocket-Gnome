//
//  LootController.m
//  Pocket Gnome
//
//  Created by Josh on 6/7/09.
//  Copyright 2009 Savory Software, LLC. All rights reserved.
//

#import <Carbon/Carbon.h>

#import "LootController.h"

#import	"Controller.h"
#import "InventoryController.h"
#import "ChatController.h"
#import "PlayerDataController.h"
#import "OffsetController.h"
#import "MacroController.h"

#import "Item.h"
#import "Offsets.h"


@interface LootController (Internal)
- (void)addItem: (int)itemID Quantity:(int)quantity Location:(int)location;
- (void)lootingComplete;
- (void)itemLooted: (NSArray*)data;
@end

@implementation LootController

- (id)init{
    self = [super init];
    if (self != nil) {
		
		_itemsLooted = [[NSMutableDictionary alloc] init];
		_lastLootedItem = 0;
		_shouldMonitor = NO;
		
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

- (void)dealloc {
	[_itemsLooted release];
	[super dealloc];
}

- (void)resetLoot{
	[_itemsLooted removeAllObjects];
}

// return a copy of our list
- (NSDictionary*)itemsLooted{
	return [[[NSDictionary alloc] initWithDictionary:_itemsLooted] autorelease];
}

// save a copy of this item as it was looted
- (void)addItem: (int)itemID Quantity:(int)quantity Location:(int)location{
	
	NSString *key = [NSString stringWithFormat:@"%d",itemID];

	// item exists in our list, increment
	if ( [_itemsLooted objectForKey:key] ){
		[_itemsLooted setValue:[NSNumber numberWithInt:[[_itemsLooted objectForKey:key] intValue]+quantity] forKey:key];
	}
	// new object
	else{
		[_itemsLooted setObject:[NSNumber numberWithInt:1] forKey:key];
	}
	
	// pass the item ID and the location
	NSArray *data = [NSArray arrayWithObjects:[NSNumber numberWithInt:itemID], [NSNumber numberWithInt:location], nil];
	[self itemLooted:data];
}

// this will continuously check to see if we are looting!
- (void)lootMonitor{
	
	// Player is invalid, lets stop monitoring!
	if ( !_shouldMonitor )
		return;
	
	MemoryAccess *memory = [controller wowMemoryAccess];
	
	if ( memory ){
		UInt32 lootedItem = 0, quantity = 0;
		unsigned long offset = [offsetController offset:@"ITEM_IN_LOOT_WINDOW"];
		
		// check for our first looted item
		if ( [memory loadDataForObject: self atAddress: offset Buffer: (Byte *)&lootedItem BufLength: sizeof(lootedItem)] ){
			
			// make sure we have a new item
			if ( lootedItem > 0 && _lastLootedItem == 0 && _lastLootedItem != lootedItem ){
				_lastLootedItem = lootedItem;
				
				// grab the quantity
				[memory loadDataForObject: self atAddress: offset + LOOT_QUANTITY Buffer: (Byte *)&quantity BufLength: sizeof(quantity)];
				
				// add our item
				[self addItem:lootedItem Quantity:quantity Location:0];
				
				// check for more to add
				int i = 1;
				while ([memory loadDataForObject: self atAddress: offset + (LOOT_NEXT * (i)) Buffer: (Byte *)&lootedItem BufLength: sizeof(lootedItem)] && lootedItem > 0 ){
					[memory loadDataForObject: self atAddress: offset + (LOOT_NEXT * (i)) + LOOT_QUANTITY Buffer: (Byte *)&quantity BufLength: sizeof(quantity)];
					[self addItem:lootedItem Quantity:quantity Location:i];
					i++;
				}
				
				[self lootingComplete];
			}
			// reset so we can continue scanning again
			else if ( lootedItem == 0 ){
				_lastLootedItem = 0;
			}
		}
	}
	
	// keep monitoring
	[self performSelector:@selector(lootMonitor) withObject:nil afterDelay:0.1f];
}


#define MAX_ITEMS_IN_LOOT_WINDOW			10		// I don't actually know if this is correct, just an estimate
- (BOOL)isLootWindowOpen{
	MemoryAccess *memory = [controller wowMemoryAccess];
	if ( !memory )
		return NO;
	
	UInt32 item = 0;
	UInt32 offset = [offsetController offset:@"ITEM_IN_LOOT_WINDOW"];
	int i = 0;
	
	for ( ; i < MAX_ITEMS_IN_LOOT_WINDOW; i++ ){
		[memory loadDataForObject: self atAddress: offset + (LOOT_NEXT * (i)) Buffer: (Byte *)&item BufLength: sizeof(item)];
		if ( item > 0 ){
			return YES;
		}
	}
	
	return NO;
}

// simply loots an item w/a macro or sends the command
- (void)lootItem:(int)slotNum{
	NSString *lootSlot = [NSString stringWithFormat: @"/script LootSlot(%d);%c", slotNum, '\n'];
	NSString *lootBoP = [NSString stringWithFormat: @"/script ConfirmLootSlot(%d);%c", slotNum, '\n'];
	
	// use macro to loot
	BOOL success = [macroController useMacroWithCommand:lootSlot];
	if ( !success ){
		
		// hit escape to close the chat window if it's open
		if ( [controller isWoWChatBoxOpen] ){
			log(LOG_GENERAL, @"[Loot] Sending escape to close open chat!");
			[chatController sendKeySequence: [NSString stringWithFormat: @"%c", kEscapeCharCode]];
			usleep(100000);
		}
		
		[chatController enter];             // open/close chat box
		usleep(100000);
		[chatController sendKeySequence: [NSString stringWithFormat: @"/script LootSlot(%d);%c", slotNum, '\n']];
		usleep(500000);
	}
	
	success = [macroController useMacroWithCommand:lootBoP];
	if ( !success ){
		
		// hit escape to close the chat window if it's open
		if ( [controller isWoWChatBoxOpen] ){
			log(LOG_GENERAL, @"[Loot] Sending escape to close open chat!");
			[chatController sendKeySequence: [NSString stringWithFormat: @"%c", kEscapeCharCode]];
			usleep(100000);
		}
		
		[chatController enter];             // open/close chat box
		usleep(100000);
		[chatController sendKeySequence: [NSString stringWithFormat: @"/script ConfirmLootSlot(%d);%c", slotNum, '\n']];
		usleep(500000);
	}
}

// auto loot? PLAYER_AUTOLOOT{INT} = [Pbase + 0xD8] + 0x1010
- (void)acceptLoot{
	
	UInt32 item;
	int i = 0;
	unsigned long offset = [offsetController offset:@"ITEM_IN_LOOT_WINDOW"];
	MemoryAccess *memory = [controller wowMemoryAccess];
	while ( offset && memory && [memory loadDataForObject: self atAddress: offset + (LOOT_NEXT * (i)) Buffer: (Byte *)&item BufLength: sizeof(item)] && i < MAX_ITEMS_IN_LOOT_WINDOW ) {
		if ( item > 0 ){
			[self lootItem:i+1];
			[self lootItem:i+2];
		}
		
		i++;
	}
}

#pragma mark Notification Firing Mechanisms

- (void)lootingComplete{
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(lootingComplete) object: nil];
	
	// Only call our notifier if the loot window isn't open!
	if ( ![self isLootWindowOpen] ){
		[[NSNotificationCenter defaultCenter] postNotificationName: AllItemsLootedNotification object: nil];
	}
	// Lets check again shortly!
	else{
		[self performSelector: @selector(lootingComplete) withObject: nil afterDelay: 0.1f];
	}
}

// future improvement: we could just monitor the items in our bag? (only drawback here is the object list is only updated every second)
- (void)itemLooted: (NSArray*)data{
	MemoryAccess *memory = [controller wowMemoryAccess];
	if ( !memory )
		return;
	
	int location = [[data objectAtIndex:1] intValue];
	UInt32 itemID = 0;
	unsigned long offset = [offsetController offset:@"ITEM_IN_LOOT_WINDOW"];
	
	// check to see if the item is still in the list!
	if ( [memory loadDataForObject: self atAddress: offset + (LOOT_NEXT * (location)) Buffer: (Byte *)&itemID BufLength: sizeof(itemID)] && itemID > 0 ){
		[self performSelector:@selector(itemLooted:) withObject:data afterDelay:0.1f];
		return;
	}

	// fire off the notification
	[[NSNotificationCenter defaultCenter] postNotificationName: ItemLootedNotification object: [data objectAtIndex:0]];
}

#pragma mark Notifications

// lets stop monitoring!
- (void)playerIsInvalid: (NSNotification*)not {
    [NSObject cancelPreviousPerformRequestsWithTarget: self];
	_shouldMonitor = NO;
}

// start monitoring!
- (void)playerIsValid: (NSNotification*)not {
	_shouldMonitor = YES;
	// Fire off a thread to start monitoring our loot
	[self performSelector:@selector(lootMonitor) withObject:nil afterDelay:0.1f];
}

@end
