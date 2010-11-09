//
//  CorpseController.m
//  Pocket Gnome
//
//  Created by Josh on 5/25/09.
//  Copyright 2009 Savory Software, LLC. All rights reserved.
//

#import "CorpseController.h"
#import "Corpse.h"
#import "MemoryAccess.h"
#import "Controller.h"
#import "Position.h"


@implementation CorpseController

- (id) init
{
    self = [super init];
    if (self != nil) {
        _corpseList = [[NSMutableArray array] retain];
    }
    return self;
}

- (void) dealloc
{
    [_corpseList release];
    [super dealloc];
}

- (int)totalCorpses{
	return [_corpseList count];
}

- (Position *)findPositionbyGUID: (GUID)GUID{
	
	
	// Loop through the corpses
	for(Corpse *corpse in _corpseList) {
		
		// found
		if ( [corpse parentLowGUID] == GUID ){
			//log(LOG_GENERAL, @"Player corpse found: %qu", GUID);
			
			return [corpse position];
		}
		//log(LOG_GENERAL, @"Corpse: %@ Name: %@", corpse, [corpse name]);
	}
	
	return nil;
}

- (void)addAddresses: (NSArray*)addresses {
	
    NSMutableDictionary *addressDict = [NSMutableDictionary dictionary];
    NSMutableArray *objectsToRemove = [NSMutableArray array];
    NSMutableArray *dataList = _corpseList;
    MemoryAccess *memory = [controller wowMemoryAccess];
    if(![memory isValid]) return;
    
    //[self willChangeValueForKey: @"corpseCount"];
	
    // enumerate current object addresses
    // determine which objects need to be removed
    for(WoWObject *obj in dataList) {
        if([obj isValid]) {
            [addressDict setObject: obj forKey: [NSNumber numberWithUnsignedLongLong: [obj baseAddress]]];
        } else {
            [objectsToRemove addObject: obj];
        }
    }
    
    // remove any if necessary
    if([objectsToRemove count]) {
        [dataList removeObjectsInArray: objectsToRemove];
    }
    
    // add new objects if they don't currently exist
    NSDate *now = [NSDate date];
    for(NSNumber *address in addresses) {
		
        if( ![addressDict objectForKey: address] ) {
            [dataList addObject: [Corpse corpseWithAddress: address inMemory: memory]];
        } else {
            [[addressDict objectForKey: address] setRefreshDate: now];
        }
    }
    
    //[self didChangeValueForKey: @"corpseCount"];
    //[self updateTracking: nil];
}

@end
