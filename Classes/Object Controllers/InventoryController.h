/*
 * Copyright (c) 2007-2010 Savory Software, LLC, http://pg.savorydeviate.com/
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * $Id$
 *
 */

#import <Cocoa/Cocoa.h>
#import "ObjectController.h"

@class Item;
@class MailActionProfile;

@class PlayerDataController;
@class MemoryViewController;
@class ObjectsController;
@class BotController;
@class MacroController;
@class NodeController;
@class OffsetController;

@interface InventoryController : ObjectController {
    IBOutlet MemoryViewController       *memoryViewController;
	IBOutlet ObjectsController          *objectsController;
	IBOutlet OffsetController			*offsetController;
	
	// only used for mailing
	IBOutlet BotController                  *botController;
	IBOutlet MacroController                *macroController;
	IBOutlet NodeController                 *nodeController;
	
	int _updateDurabilityCounter;
	
	NSArray *_itemsPlayerIsWearing, *_itemsInBags;
    NSMutableDictionary *_itemNameList;
}

+ (InventoryController *)sharedInventory;

// general
- (unsigned)itemCount;

// query
- (Item*)itemForGUID: (GUID)guid;
- (Item*)itemForID: (NSNumber*)itemID;
- (Item*)itemForName: (NSString*)itemName;
- (NSString*)nameForID: (NSNumber*)itemID;

- (int)collectiveCountForItem: (Item*)item;
- (int)collectiveCountForItemInBags: (Item*)item;

- (float)averageItemDurability;
- (float)collectiveDurability;
- (float)averageWearableDurability;
- (float)collectiveWearableDurability;

// list
- (NSArray*)inventoryItems;
- (NSMenu*)inventoryItemsMenu;
- (NSMenu*)usableInventoryItemsMenu;
- (NSMenu*)prettyInventoryItemsMenu;
- (NSArray*)itemsPlayerIsWearing;
- (NSArray*)itemsInBags;
- (NSArray*)useableItems;

- (int)bagSpacesAvailable;
- (int)bagSpacesTotal;
- (BOOL)arePlayerBagsFull;

// Total number of marks (from all BG)
- (int)pvpMarks;

- (Item*)getBagItem: (int)bag withSlot:(int)slot;
- (int)mailItemsWithProfile:(MailActionProfile*)profile;

//- (NSMutableArray*)itemsInBags;
@end