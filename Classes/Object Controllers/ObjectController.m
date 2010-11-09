//
//  ObjectController.m
//  Pocket Gnome
//
//  Created by Josh on 2/4/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "ObjectController.h"
#import "Controller.h"
#import "PlayerDataController.h"

#import "WoWObject.h"

#import "MemoryAccess.h"

@implementation ObjectController


- (id)init{
    self = [super init];
	if ( self != nil ) {
		
		_updateFrequency = 1.0f;
		
		_objectList		= [[NSMutableArray array] retain];
		_objectDataList = [[NSMutableArray array] retain];
		
		_updateTimer = nil;
		
		// wow memory access validity
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(memoryAccessValid:) 
                                                     name: MemoryAccessValidNotification 
                                                   object: nil];
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(memoryAccessInvalid:) 
                                                     name: MemoryAccessInvalidNotification 
                                                   object: nil];
	}
	
	return self;
}

- (void)awakeFromNib {
    self.minSectionSize = [self.view frame].size;
    self.maxSectionSize = NSZeroSize;
    
    self.updateFrequency = [[NSUserDefaults standardUserDefaults] floatForKey: [self updateFrequencyKey]];
}

- (void)dealloc{
	[_objectList release];
	[_objectDataList release];
	
	[super dealloc];
}

@synthesize view;
@synthesize minSectionSize;
@synthesize maxSectionSize;
@synthesize updateFrequency = _updateFrequency;

#pragma mark Storage

- (void)addAddresses: (NSArray*) addresses {
    NSMutableDictionary *addressDict = [NSMutableDictionary dictionary];
    NSMutableArray *objectsToRemove = [NSMutableArray array];
    NSMutableArray *dataList = _objectList;
    MemoryAccess *memory = [controller wowMemoryAccess];
    if ( ![memory isValid] ) return;
    
    //[self willChangeValueForKey: @"objectCount"];
	
    // enumerate current object addresses
    // determine which objects need to be removed
    for ( WoWObject *obj in dataList ) {
		
		NSNumber *address = [NSNumber numberWithUnsignedLong:[obj baseAddress]];
		
		// if our object is in the list, update it!
		if ( [addresses containsObject:address] ){
			obj.notInObjectListCounter = 0;
		}
		// otherwise increment, it's not in the list :(  (we could just remove it?)
		else{
			obj.notInObjectListCounter++;
		}
		
		// check if we should remove the object
        if ( ![obj isStale] ) {		//[(Node*)obj validToLoot]
            [addressDict setObject: obj forKey: [NSNumber numberWithUnsignedLongLong: [obj baseAddress]]];
        }
		else{
            [objectsToRemove addObject: obj];
        }
    }
	
    // remove any if necessary
    if ( [objectsToRemove count] ) {
        [dataList removeObjectsInArray: objectsToRemove];
    }
    
	// 1 read
	UInt32 playerBaseAddress = [playerData baselineAddress];
	
    // add new objects if they don't currently exist
	NSDate *now = [NSDate date];
    for ( NSNumber *address in addresses ) {
		
		// skip current player
        if ( playerBaseAddress == [address unsignedIntValue] )
            continue;
		
		// new object
        if ( ![addressDict objectForKey: address] ) {
			id obj = [self objectWithAddress:address inMemory:memory];
  
			if ( obj ){
				// fire this off, sometimes we will want to do something when we get a new object (i.e. load the objects name?)
				[self objectAddedToList:obj];
				
				// add the new object to our master list
				[dataList addObject: obj];    
			}
			else{
				log(LOG_GENERAL, @"[ObjectController] I can has never be here? Calling class: %@", [self class]);
			}
        }
		// we do this here to ensure ONLY the objects in the actual WoW list are updated
		else {
			[[addressDict objectForKey: address] setRefreshDate: now];
		}
    }
    
    //[self didChangeValueForKey: @"objectCount"];
}

- (void)resetAllObjects{
	//[self willChangeValueForKey: @"objectCount"];
    [_objectList removeAllObjects];
    //[self didChangeValueForKey: @"objectCount"];
}

#pragma mark Notifications

- (void)memoryAccessValid: (NSNotification*)notification {
    MemoryAccess *memory = [controller wowMemoryAccess];
    if ( !memory ) return;
	
    log(LOG_GENERAL, @"Reloading memory access for %d objects.", [_objectList count]);
    for ( WoWObject *obj in _objectList ) {
        [obj setMemoryAccess: memory];
    }
}

- (void)memoryAccessInvalid: (NSNotification*)notification {
	[self resetAllObjects];
}

#pragma mark Accessors

- (void)setUpdateFrequency: (float)frequency {
    if(frequency < 0.1) frequency = 0.1;
    
    [self willChangeValueForKey: @"updateFrequency"];
    _updateFrequency = [[NSString stringWithFormat: @"%.2f", frequency] floatValue];
    [self didChangeValueForKey: @"updateFrequency"];
	
    [[NSUserDefaults standardUserDefaults] setFloat: _updateFrequency forKey: [self updateFrequencyKey]];
	
    [_updateTimer invalidate];
    _updateTimer = [NSTimer scheduledTimerWithTimeInterval: frequency target: self selector: @selector(refreshData) userInfo: nil repeats: YES];	
}

- (NSString*)sectionTitle {
    return @"Unknown";
}

#pragma mark Should be implemented by the sub class

- (NSArray*)allObjects{
	return nil;
}

- (void)refreshData {
}

- (unsigned int)objectCount{
	return [_objectList count];
}

- (unsigned int)objectCountWithFilters{
	return [_objectList count];
}
			 
- (void)objectAddedToList:(WoWObject*)obj{
}

- (id)objectWithAddress:(NSNumber*) address inMemory:(MemoryAccess*)memory{
	return nil;
}

- (NSString*)updateFrequencyKey{
	return @"ObjectControllerUpdateFrequency";
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex{
	return nil;
}

- (void)tableView: (NSTableView *)aTableView willDisplayCell: (id)aCell forTableColumn: (NSTableColumn *)aTableColumn row: (int)aRowIndex{
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectTableColumn:(NSTableColumn *)aTableColumn{
	return YES;
}

- (void)sortUsingDescriptors:(NSArray*)sortDescriptors{
	[_objectDataList sortUsingDescriptors: sortDescriptors];
}

- (void)tableDoubleClick: (id)sender{
}

- (WoWObject*)objectForRowIndex:(int)rowIndex{
	return nil;
}

@end
