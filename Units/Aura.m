//
//  Aura.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 10/22/08.
//  Copyright 2008 Jon Drummond. All rights reserved.
//

#import "Aura.h"

@implementation Aura

+ (id)auraEntryID: (UInt32)entryID GUID: (GUID)guid bytes: (UInt32)bytes duration: (UInt32)duration expiration: (UInt32)expiration {
    Aura *aura = [[Aura alloc] init];
    if(aura) {
        aura.guid = guid;
        aura.entryID = entryID;
        aura.bytes = bytes;
        aura.duration = duration;
        aura.expiration = expiration;
    }
    return [aura autorelease];
}

- (void) dealloc
{
    [super dealloc];
}


@synthesize guid;
@synthesize entryID;
@synthesize bytes;
@synthesize duration;
@synthesize expiration;

- (UInt32)stacks {
    return (([self bytes] >> 16) & 0xFF);
}

- (UInt32)level {
    return (([self bytes] >> 8) & 0xFF);
}

- (BOOL)isDebuff {
    return (([self bytes] >> 7) & 1);
}

- (BOOL)isActive {
     return (([self bytes] >> 5) & 1);
}

- (BOOL)isPassive {
    return (([self bytes] >> 4) & 1) && ![self isActive];
}

- (BOOL)isHidden {
    return (([self bytes] >> 7) & 1);
}
@end
