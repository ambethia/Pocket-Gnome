//
//  Corpse.m
//  Pocket Gnome
//
//  Created by Josh on 5/25/09.
//  Copyright 2009 Savory Software, LLC. All rights reserved.
//

#import "Corpse.h"
#import "WoWObject.h"
#import "Position.h"

@implementation Corpse

+ (id)corpseWithAddress: (NSNumber*)address inMemory: (MemoryAccess*)memory {
    return [[[Corpse alloc] initWithAddress: address inMemory: memory] autorelease];
}

- (NSString*)description {
    return [NSString stringWithFormat: @"<%@: %d; Addr: %@, Parent: %d>",
            [self className],
            [self entryID], 
            [NSString stringWithFormat: @"0x%X", [self baseAddress]],
			[self parentLowGUID]];
}

- (UInt32)parentLowGUID{
	
	UInt32 value = 0;
    if([_memory loadDataForObject: self atAddress: ([self infoAddress] + CorpseField_OwnerGUID) Buffer: (Byte *)&value BufLength: sizeof(value)]) {
		return value;
	}
	
	return 0;
}

- (Position*)position{
	float pos[3] = {-1.0f, -1.0f, -1.0f };
    if([_memory loadDataForObject: self atAddress: ([self baseAddress] + CorpseField_XLocation) Buffer: (Byte *)&pos BufLength: sizeof(float)*3])
        return [Position positionWithX: pos[0] Y: pos[1] Z: pos[2]];
    return nil;
}

@end
