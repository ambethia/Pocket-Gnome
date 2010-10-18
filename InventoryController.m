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


#import "ObjectsController.h"
#import "PlayerDataController.h"
#import "MacroController.h"
#import "BotController.h"
#import "NodeController.h"
#import "InventoryController.h"
#import "Controller.h"
#import "MemoryViewController.h"
#import "OffsetController.h"

#import "Offsets.h"

#import "Item.h"
#import "WoWObject.h"
#import "Player.h"
#import "Node.h"

#import "MailActionProfile.h"

@implementation InventoryController

static InventoryController *sharedInventory = nil;

+ (InventoryController *)sharedInventory {
	if (sharedInventory == nil)
		sharedInventory = [[[self class] alloc] init];
	return sharedInventory;
}

- (id) init
{
    self = [super init];
	if(sharedInventory) {
		[self release];
		self = sharedInventory;
	} else if(self != nil) {
        sharedInventory = self;
		_itemsPlayerIsWearing = nil;
		_itemsInBags = nil;
		
		// set to 20 to ensure it updates right away
		_updateDurabilityCounter = 20;
		
        // load in item names
        id itemNames = [[NSUserDefaults standardUserDefaults] objectForKey: @"ItemNames"];
        if(itemNames) {
            _itemNameList = [[NSKeyedUnarchiver unarchiveObjectWithData: itemNames] mutableCopy];            
        } else
            _itemNameList = [[NSMutableDictionary dictionary] retain];
        
        // notifications
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(applicationWillTerminate:) 
                                                     name: NSApplicationWillTerminateNotification 
                                                   object: nil];
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(itemNameLoaded:) 
                                                     name: ItemNameLoadedNotification 
                                                   object: nil];
    }
    return self;
}

- (void)dealloc{
	[_objectList release];
	[_objectDataList release];
	[_itemNameList release];
	[_itemsPlayerIsWearing release];
	[_itemsInBags release];
	
	[super dealloc];
}

#pragma mark -

- (void)applicationWillTerminate: (NSNotification*)notification {
    [[NSUserDefaults standardUserDefaults] setObject: [NSKeyedArchiver archivedDataWithRootObject: _itemNameList] forKey: @"ItemNames"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)itemNameLoaded: (NSNotification*)notification {
    Item *item = (Item*)[notification object];
    
    NSString *name = [item name];
    if(name) {
        // log(LOG_ITEM, @"Saving item: %@", item);
        [_itemNameList setObject: name forKey: [NSNumber numberWithInt: [item entryID]]];
    }
}

#pragma mark -

- (Item*)itemForGUID: (GUID)guid {
	
	if ( guid == 0x0 ){
		return nil;
	}
	
	/*if ( GUID_LOW32(guid) != 0x4580000 ){
		NSLog(@"...0x%X", GUID_LOW32(guid));
		return nil;
		
	}*/
	
	NSArray *itemList = [[_objectList copy] autorelease];
	
    for(Item *item in itemList) {
		//NSLog(@"%qd == %qd", [item GUID], guid);
		
        if( [item GUID] == guid )
            return [[item retain] autorelease];
    }
    return nil;
}

- (Item*)itemForID: (NSNumber*)itemID {
    if( !itemID || [itemID intValue] <= 0) return nil;
	NSArray* itemList = [[_objectList copy] autorelease];
    for(Item *item in itemList) {
        if( [itemID isEqualToNumber: [NSNumber numberWithInt: [item entryID]]] )
            return [[item retain] autorelease];
    }
    return nil;
}

- (Item*)itemForName: (NSString*)name {
    if(!name || ![name length]) return nil;
    for(Item* item in _objectList) {
        if([item name]) {
            NSRange range = [[item name] rangeOfString: name 
                                               options: NSCaseInsensitiveSearch | NSAnchoredSearch | NSDiacriticInsensitiveSearch];
            if(range.location != NSNotFound && [item isValid])
                return [[item retain] autorelease];
        }
    }
    return nil;
}

- (NSString*)nameForID: (NSNumber*)itemID {
    NSString *name = [_itemNameList objectForKey: itemID];
    if(name) return name;
    return [NSString stringWithFormat: @"%@", itemID];
}

- (int)collectiveCountForItem: (Item*)refItem {
    if(![refItem isValid]) return 0;
    int count = 0;
	int itemEntryID = [refItem entryID];    // cache this, saves on memory reads
    for ( Item *item in _objectList ) {
		// same type
        if ( [item entryID] == itemEntryID ) {
            count += [item count];
        }
    }
    //log(LOG_ITEM, @"Found count %d for item %@", count, refItem);
    return count;
}

- (int)collectiveCountForItemInBags: (Item*)refItem{
	if(![refItem isValid]) return 0;
    int count = 0;
	int itemEntryID = [refItem entryID];    // cache this, saves on memory reads
    for ( Item* item in [self itemsInBags] ) {
        if ( [item entryID] == itemEntryID ) {
            count += [item count];
        }
    }
    //log(LOG_ITEM, @"Found count %d for item %@", count, refItem);
    return count;
}

- (BOOL)trackingItem: (Item*)anItem {
    for(Item *item in _objectList) {
        if( [item isEqualToObject: anItem] )
            return YES;
    }
    return NO;
}

- (unsigned)itemCount {
    return [_objectList count];
}

#pragma mark -

// this gets the average durability level over all items with durability
- (float)averageItemDurability {
    float durability = 0;
    int count = 0;
    for(Item *item in _objectList) {
        if([[item maxDurability] unsignedIntValue]) {
            durability += (([[item durability] unsignedIntValue]*1.0)/[[item maxDurability] unsignedIntValue]);
            count++;
        }
    }
    return [[NSString stringWithFormat: @"%.2f", durability/count*100.0] floatValue];
}

// this gets the durability average of everything as if it was one item
- (float)collectiveDurability {
    unsigned curDur = 0, maxDur = 0;
    for(Item *item in _objectList) {
        curDur += [[item durability] unsignedIntValue];
        maxDur += [[item maxDurability] unsignedIntValue];
    }
    return [[NSString stringWithFormat: @"%.2f", (1.0*curDur)/(1.0*maxDur)*100.0] floatValue];
}

- (float)averageWearableDurability{
    float durability = 0;
    int count = 0;
    for(Item *item in _itemsPlayerIsWearing) {
        if([[item maxDurability] unsignedIntValue]) {
            durability += (([[item durability] unsignedIntValue]*1.0)/[[item maxDurability] unsignedIntValue]);
            count++;
        }
    }
	
    return [[NSString stringWithFormat: @"%.2f", durability/count*100.0] floatValue];
}

- (float)collectiveWearableDurability;{
    unsigned curDur = 0, maxDur = 0;
    for(Item *item in _itemsPlayerIsWearing) {
        curDur += [[item durability] unsignedIntValue];
        maxDur += [[item maxDurability] unsignedIntValue];
    }
    return [[NSString stringWithFormat: @"%.2f", (1.0*curDur)/(1.0*maxDur)*100.0] floatValue];
}

#pragma mark -

- (NSArray*)inventoryItems {
    return [[_objectList retain] autorelease];
}

- (NSMenu*)inventoryItemsMenu {
    
    NSMenuItem *menuItem;
    NSMenu *menu = [[[NSMenu alloc] initWithTitle: @"Items"] autorelease];
    for(Item *item in _objectList) {
        if( [item name]) {
            menuItem = [[NSMenuItem alloc] initWithTitle: [NSString stringWithFormat: @"%@ - %d", [item name], [item entryID]] action: nil keyEquivalent: @""];
        } else {
            menuItem = [[NSMenuItem alloc] initWithTitle: [NSString stringWithFormat: @"%d", [item entryID]] action: nil keyEquivalent: @""];
        }
        [menuItem setTag: [item entryID]];
        [menu addItem: [menuItem autorelease]];
    }
    
    if( [_objectList count] == 0) {
        menuItem = [[NSMenuItem alloc] initWithTitle: @"There are no available items." action: nil keyEquivalent: @""];
        [menuItem setTag: 0];
        [menu addItem: [menuItem autorelease]];
    }
    
    return menu;
}

// returns all (unique) useable items
- (NSArray*)useableItems{
	
	NSMutableDictionary *useableItems = [NSMutableDictionary dictionary];
    for ( Item *item in _objectList ) {
		NSNumber *entryID = [NSNumber numberWithUnsignedInt: [item cachedEntryID]];
		
        if ( ![useableItems objectForKey:entryID] && [item charges] > 0 ) {
			[useableItems setObject: item forKey: entryID];
		}
	}
	
	NSArray *uniqueItems = [useableItems allValues];
	return [[uniqueItems retain] autorelease];
}

- (NSMenu*)usableInventoryItemsMenu {
    
    // first,  items
    NSMutableDictionary *coalescedItems = [NSMutableDictionary dictionary];
    for(Item *item in _objectList) {
        if( [item charges] > 0) {
            NSNumber *entryID = [NSNumber numberWithUnsignedInt: [item entryID]];
            NSMutableArray *list = nil;
            if( (list = [coalescedItems objectForKey: entryID]) ) {
                [list addObject: item];
            } else {
                [coalescedItems setObject: [NSMutableArray arrayWithObject: item] forKey: entryID];
            }
        }
    }
    
    // now sort those items so they are in alphabetical order
    NSMutableArray *nameMap = [NSMutableArray array];
    for(NSNumber *key in [coalescedItems allKeys]) {
        [nameMap addObject: [NSDictionary dictionaryWithObjectsAndKeys: 
                             [self nameForID: key],                 @"name", 
                             [self itemForID: key],                 @"item",
                             [coalescedItems objectForKey: key],    @"list", nil]];
    }
    [nameMap sortUsingDescriptors: [NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey: @"name" ascending: YES] autorelease]]];
	
    // finally generate the NSMenu from the sorted list of coalesced items 
    NSMenuItem *menuItem;
    NSMenu *menu = [[[NSMenu alloc] initWithTitle: @"Items"] autorelease];
    for(NSDictionary *dict in nameMap) {
        Item *keyItem = [dict objectForKey: @"item"];
        NSArray *itemList = [dict objectForKey: @"list"];
        int count = 0;
        for(Item *item in itemList) {
            count += [item count];
        }
        
        // if we have 0 of this item, don't include it
        if( count > 0 ) {
            int entryID = [keyItem entryID];
            if( [keyItem name] ) {
                menuItem = [[NSMenuItem alloc] initWithTitle: [NSString stringWithFormat: @"%@ [x%d] (%d)", [keyItem name], count, entryID] action: nil keyEquivalent: @""];
            } else {
                menuItem = [[NSMenuItem alloc] initWithTitle: [NSString stringWithFormat: @"%d [x%d]", entryID, count] action: nil keyEquivalent: @""];
            }
            [menuItem setTag: entryID];
            [menu addItem: [menuItem autorelease]];
        }
    }
    
    if( [_objectList count] == 0) {
        menuItem = [[NSMenuItem alloc] initWithTitle: @"There are no available items." action: nil keyEquivalent: @""];
        [menuItem setTag: 0];
        [menu addItem: [menuItem autorelease]];
    }
    
    return menu;
}

- (NSMenu*)prettyInventoryItemsMenu {
    NSMenu *menu = [[[NSMenu alloc] initWithTitle: @"Pretty Items"] autorelease];
    
    NSMenu *useItems = [self usableInventoryItemsMenu];
    NSMenu *allItems = [self inventoryItemsMenu];
    NSMenuItem *anItem;
    
    // make "Usable Items" header
    anItem = [[[NSMenuItem alloc] initWithTitle: @"Usable Items" action: nil keyEquivalent: @""] autorelease];
    [anItem setAttributedTitle: [[[NSAttributedString alloc] initWithString: @"Usable Items" 
                                                                 attributes: [NSDictionary dictionaryWithObjectsAndKeys: [NSFont boldSystemFontOfSize: 0], NSFontAttributeName, nil]] autorelease]];
    [anItem setTag: 0];
    [menu addItem: anItem];
    
    for(NSMenuItem *item in [useItems itemArray]) {
        NSMenuItem *newItem = [item copy];
        [newItem setIndentationLevel: 1];
        [menu addItem: [newItem autorelease]];
    }
    
    [menu addItem: [NSMenuItem separatorItem]];
    
    // make "All Items" header
    anItem = [[[NSMenuItem alloc] initWithTitle: @"All Items" action: nil keyEquivalent: @""] autorelease];
    [anItem setTag: 0];
    [anItem setAttributedTitle: [[[NSAttributedString alloc] initWithString: @"All Items" 
                                                                 attributes: [NSDictionary dictionaryWithObjectsAndKeys: [NSFont boldSystemFontOfSize: 0], NSFontAttributeName, nil]] autorelease]];
    [menu addItem: anItem];
    
    for(NSMenuItem *item in [allItems itemArray]) {
        NSMenuItem *newItem = [item copy];
        [newItem setIndentationLevel: 1];
        [menu addItem: [newItem autorelease]];
    }
    
    return menu;
}

- (int)pvpMarks{
	
	int stacks = 0;
	for ( Item *item in _objectList ){
		
		switch ( [item entryID] ){
			case 20560:             // Alterac Valley Mark of Honor
			case 20559:             // Arathi Basin Mark of Honor
			case 29024:             // Eye of Storm Mark of Honor
			case 47395:             // Isle of Conquest Mark of Honor
			case 42425:             // Strand of the Ancients Mark of Honor
			case 20558:             // Warsong Gulch Mark of Honor
				stacks += [item count];
				break;
		}
	}
	
	return stacks;  
}

// return an array of items for an array of guids
- (NSArray*)itemsForGUIDs: (NSArray*) guids{
	NSMutableArray *items = [NSMutableArray array];
	
	for ( NSNumber *guid in guids ){
		Item *item = [self itemForGUID:[guid longLongValue]];
		if ( item ){
			[items addObject:item];
		}
	}
	
	return items;   
}

// return ONLY the items the player is wearing (herro % durability calculation)
- (NSArray*)itemsPlayerIsWearing{
	NSArray *items = [self itemsForGUIDs:[[playerData player] itemGUIDsPlayerIsWearing]];
	return [[items retain] autorelease];    
}

// will return an array of Item objects
- (NSArray*)itemsInBags{
	
	// will store all of our items
	NSMutableArray *items = [NSMutableArray array];
	
	// grab the GUIDs of our bags
	NSArray *GUIDsBagsOnPlayer = [[playerData player] itemGUIDsOfBags];
	
	// loop through all of our items to find
	for ( Item *item in _objectList ){
		NSNumber *itemContainerGUID = [NSNumber numberWithLongLong:[item containerUID]];
		
		if ( [GUIDsBagsOnPlayer containsObject:itemContainerGUID] ){
			[items addObject:item];
		}
	}
	
	// start with the GUIDs of the items in our backpack
	NSArray *backpackGUIDs = [[playerData player] itemGUIDsInBackpack];
	
	// loop through our backpack guids
	for ( NSNumber *guid in backpackGUIDs ){
		Item *item = [self itemForGUID:[guid longLongValue]];
		if ( item ){
			[items addObject:item];
		}
	}
	
	return [[items retain] autorelease];    
}

- (int)bagSpacesAvailable{
	return [self bagSpacesTotal] - [[self itemsInBags] count];      
}

- (int)bagSpacesTotal{
	
	// grab all of the bags ON the player
	NSArray *bagGUIDs = [[playerData player] itemGUIDsOfBags];
	int totalBagSpaces = 16; // have to start w/the backpack size!
	// loop through our backpack guids
	for ( NSNumber *guid in bagGUIDs ){
		Item *item = [self itemForGUID:[guid longLongValue]];
		if ( item ){
			totalBagSpaces += [item bagSize];
		}
	}
	
	return totalBagSpaces;
}

- (BOOL)arePlayerBagsFull{
	//log(LOG_ITEM, @"%d == %d", [self bagSpacesAvailable], [self bagSpacesTotal]);
	return [self bagSpacesAvailable] == 0;
}

#define MAX_BAGS 4
#define MAX_SLOTSIZE 40         // i think it's really 32, but just to be safe ;)

- (int)mailItemsWithProfile:(MailActionProfile*)profile{
	
	int itemsMailed = 0;
	
	// array of objects which contains:
	//      item ID, slot $, bag #
	Item *allItems[MAX_BAGS+1][MAX_SLOTSIZE] = {{0}};
	int currentSlot = 1;
	
	// backpack items first
	NSArray *backpackGUIDs = [[playerData player] itemGUIDsInBackpack];
	for ( NSNumber *guid in backpackGUIDs ){
		Item *item = [self itemForGUID:[guid unsignedLongLongValue]];
		
		if ( item ){
			allItems[0][currentSlot++] = [item retain];
		}
	}
	
	// now for bags!
	UInt32 bagListOffset = [offsetController offset:@"BagListOffset"];
	MemoryAccess *memory = [controller wowMemoryAccess];
	
	if ( memory && [memory isValid] ){
		
		// loop through all valid bags (up to 4)!
		int bag = 0;
		for ( ; bag < 4; bag++ ){
			
			// valid bag?
			GUID bagGUID = [memory readLongLong:bagListOffset + ( bag * 8)];
			if ( bagGUID > 0x0 ){
				Item *itemBag = [self itemForGUID:bagGUID];
				
				if ( itemBag ){
					int bagSlot = 1;
					int bagSize = [itemBag bagSize];        // 1 read
					for ( ; bagSlot <= bagSize; bagSlot++ ){
						
						// valid item at this slot?
						GUID guid = [itemBag itemGUIDinSlot:bagSlot];
						Item *item = [self itemForGUID:guid];
						if ( item ){
							allItems[bag+1][bagSlot] = [item retain];
						}                                                       
					}
				}
			}
		}
	}
	
	// items to exclude/include!
	NSArray *exclusions = [profile exclusions];
	NSArray *inclusions = [profile inclusions];
	
	// now remove items from the list we shouldn't mail!
	int k = 0;
	for ( ; k < MAX_BAGS; k++ ){
		int j = 0;
		for ( ; j < MAX_SLOTSIZE; j++ ){
			if ( allItems[k][j] != nil ){
				Item *item = allItems[k][j];
				
				// remove exclusions
				if ( exclusions != nil ){
					for ( NSString *itemName in exclusions ){
						if ( [[item name] isCaseInsensitiveLike:itemName] ){
							log(LOG_ITEM, @"[Mail] Removing item %@ to be mailed", item);
							allItems[k][j] = nil;
						}
					}
				}
				
				// check for inclusions
				if ( inclusions != nil ){
					BOOL found = NO;
					for ( NSString *itemName in inclusions ){
						if ( [[item name] isCaseInsensitiveLike:itemName] ){
							found = YES;
							log(LOG_ITEM, @"[Mail] Saving %@ to be mailed", item);
							itemsMailed++;
							
							// in case our exclusion removed it
							allItems[k][j] = item;
						}
					}
					
					// we will want to check for types here, once I figure this out!
					if ( !found ){
						log(LOG_ITEM, @"[Mail] Removing %@ to be mailed", item);
						allItems[k][j] = nil;
					}
				}
			}
		}
	}
	
	// time to mail some items!
	if ( itemsMailed > 0 ){
		
		// open up the mailbox
		Node *mailbox = [nodeController closestNodeWithName:@"Mailbox"];
		
		if ( mailbox ){
			[botController interactWithMouseoverGUID:[mailbox GUID]];
			usleep(500000);
			
			[macroController useMacroOrSendCmd:@"/click MailFrameTab2"];
			usleep(100000);
		}
		else{
			log(LOG_ITEM, @"[Mail] No mailbox found, aborting");
			return 0;
		}
		
		log(LOG_ITEM, @"[Mail] Found %d items to mail! Beginning process with %@!", itemsMailed, mailbox);
		
		int totalAdded = 0;
		
		// while we have items to mail!
		while ( itemsMailed > 0 ){
			
			// we have items to mail!
			if ( totalAdded > 0 ){
				log(LOG_ITEM, @"[Mail] Sending %d items", totalAdded );
				itemsMailed -= totalAdded;
				
				// send the mail
				NSString *macroCommand = [NSString stringWithFormat:@"/script SendMail( \"%@\", \" \", \" \");", profile.sendTo];
				[macroController useMacroOrSendCmd:macroCommand];
				usleep(100000);
				totalAdded = 0;
				continue;
			}
			
			int k = 0;
			for ( ; k < MAX_BAGS; k++ ){
				// time to mail!
				if ( totalAdded == 12 ){
					break;
				}
				
				int j = 0;
				for ( ; j < MAX_SLOTSIZE; j++ ){
					
					// time to mail!
					if ( totalAdded == 12 ){
						break;
					}
					
					// we have an item to mail!
					if ( allItems[k][j] != nil ){
						log(LOG_ITEM, @"[%d] Found item %@ to mail", totalAdded, allItems[k][j]);
						
						// move the item to the mail
						NSString *macroCommand = [NSString stringWithFormat:@"/script UseContainerItem(%d, %d);", k, j];
						[macroController useMacroOrSendCmd:macroCommand];
						usleep(50000);
						
						totalAdded++;
						allItems[k][j] = nil;
					}
				}
			}
		}
	}
	
	return itemsMailed;
}

- (Item*)getBagItem: (int)bag withSlot:(int)slot{
	
	int currentSlot = 1;
	
	// backpack!
	if ( bag == 0 ){
		
		NSArray *backpackGUIDs = [[playerData player] itemGUIDsInBackpack];
		NSLog(@"Backpack");
		for ( NSNumber *guid in backpackGUIDs ){
			Item *item = [self itemForGUID:[guid unsignedLongLongValue]];
			
			if ( item ){
				NSLog(@" {%d, %d} %@", 0, currentSlot++, [item name]);
				return [[item retain] autorelease];
			}
		}               
	}
	
	else{
		UInt32 bagListOffset = 0xD92660;
		MemoryAccess *memory = [controller wowMemoryAccess];
		
		if ( memory && [memory isValid] ){
			
			// loop through all valid bags (up to 4)!
			int bag = 0;
			for ( ; bag < 4; bag++ ){
				
				// valid bag?
				GUID bagGUID = [memory readLongLong:bagListOffset + ( bag * 8)];
				if ( bagGUID > 0x0 ){
					Item *itemBag = [self itemForGUID:bagGUID];
					
					if ( itemBag ){
						NSLog(@"Bag: %@", [itemBag name]);
						
						int bagSlot = 1;
						int bagSize = [itemBag bagSize];        // 1 read
						for ( ; bagSlot <= bagSize; bagSlot++ ){
							
							// valid item at this slot?
							GUID guid = [itemBag itemGUIDinSlot:bagSlot];
							Item *item = [self itemForGUID:guid];
							if ( item ){
								NSLog(@" {%d, %d} %@", bag+1, bagSlot, [item name]);
								return [[item retain] autorelease];
							}                                                       
						}
					}
				}
			}
		}
	}
	
	return nil;
}

#pragma mark Sub Class implementations

- (void)objectAddedToList:(WoWObject*)obj{
	
	// load item name
	NSNumber *itemID = [NSNumber numberWithInt: [(Item*)obj entryID]];
	if ( [_itemNameList objectForKey: itemID] ) {
		[(Item*)obj setName: [_itemNameList objectForKey: itemID]];
	}
	else if ( ![(Item*)obj name] ){
		[(Item*)obj loadName];
	}
}

- (id)objectWithAddress:(NSNumber*) address inMemory:(MemoryAccess*)memory{
	return [Item itemWithAddress:address inMemory:memory];
}

- (NSString*)updateFrequencyKey{
	return @"InventoryControllerUpdateFrequency";
}


- (void)refreshData {
	
	// remove old objects
	[_objectDataList removeAllObjects];
	
	if ( ![playerData playerIsValid:self] ) return;
	
	// why do we only update on every 20th read?
	//      to save memory reads of course!
	int freq = (int)(20.0f / _updateFrequency);
	
	if ( _updateDurabilityCounter > freq || _itemsPlayerIsWearing == nil || _itemsInBags == nil ){
		
		// release the old arrays
		_itemsPlayerIsWearing = nil;
		_itemsInBags = nil;
		
		// grab the new ones
		_itemsPlayerIsWearing = [[self itemsPlayerIsWearing] retain];
		_itemsInBags = [[self itemsInBags] retain];
		
		_updateDurabilityCounter = 0;
	}
	
	_updateDurabilityCounter++;
	
	// is tab viewable?
	if ( ![objectsController isTabVisible:Tab_Items] )
		return;
	
    NSSortDescriptor *nameDesc = [[[NSSortDescriptor alloc] initWithKey: @"name" ascending: YES] autorelease];
    [_objectList sortUsingDescriptors: [NSArray arrayWithObject: nameDesc]];
    
    for ( Item *item in _objectList ) {
        NSString *durString;
        NSNumber *minDur = [item durability], *maxDur = [item maxDurability], *durPercent = nil;
        if([maxDur intValue] > 0) {
            durString = [NSString stringWithFormat: @"%@/%@", minDur, maxDur];
            durPercent = [NSNumber numberWithFloat: [[NSString stringWithFormat: @"%.2f", 
                                                      (([minDur unsignedIntValue]*1.0)/[maxDur unsignedIntValue])*100.0] floatValue]];
        } else {
            durString = @"-";
            durPercent = [NSNumber numberWithFloat: 101.0f];
        }
		
		// where is the item?
		NSString *location = @"Bank";
		if ( [_itemsPlayerIsWearing containsObject:item] ){
			location = @"Wearing";
		}
		else if ( [_itemsInBags containsObject:item] ){
			location = @"Player Bag";
		}
		else if ( [item itemType] == ItemType_Money || [item itemType] == ItemType_Key ){
			location = @"Player";
		}
        
        [_objectDataList addObject: [NSDictionary dictionaryWithObjectsAndKeys: 
									 item,                                                @"Item",
									 ([item name] ? [item name] : @""),                   @"Name",
									 [NSNumber numberWithUnsignedInt: [item cachedEntryID]],    @"ItemID",
									 [NSNumber numberWithUnsignedInt: [item isBag] ? [item bagSize] : [item count]],      @"Count",
									 [item itemTypeString],                               @"Type",
									 [item itemSubtypeString],                            @"Subtype",
									 durString,                                           @"Durability",
									 durPercent,                                          @"DurabilityPercent",
									 location,                                                                                    @"Location",
									 [NSNumber numberWithInt:[item notInObjectListCounter]],      @"Invalid",
									 nil]];
    }
	
	// sort
	[_objectDataList sortUsingDescriptors: [[objectsController itemTable] sortDescriptors]];
	
	// reload table
	[objectsController loadTabData];
	
    //log(LOG_ITEM, @"enumerateInventory took %.2f seconds...", [date timeIntervalSinceNow]*-1.0);
}

- (WoWObject*)objectForRowIndex:(int)rowIndex{
	if ( rowIndex >= [_objectDataList count] ) return nil;
	return [[_objectDataList objectAtIndex: rowIndex] objectForKey: @"Item"];
}

#pragma mark -
#pragma mark TableView Delegate & Datasource

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
    if ( rowIndex == -1 || rowIndex >= [_objectDataList count] ) return nil;
	
    return [[_objectDataList objectAtIndex: rowIndex] objectForKey: [aTableColumn identifier]];
}

- (void)tableDoubleClick: (id)sender{
	[memoryViewController showObjectMemory: [[_objectDataList objectAtIndex: [sender clickedRow]] objectForKey: @"Item"]];
	[controller showMemoryView];
}

@end
