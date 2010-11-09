//
//  Aura.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 10/22/08.
//  Copyright 2008 Jon Drummond. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface Aura : NSObject {
    GUID  guid;
    UInt32  entryID;        // spell ID
    UInt32  bytes;          // [8 unk ] [8 stack count ] [8 unk ] [8 unk ]
    UInt32  duration;       // milliseconds
    UInt32  expiration;     // game time
}

+ (id)auraEntryID: (UInt32)entryID GUID: (GUID)guid bytes: (UInt32)bytes duration: (UInt32)duration expiration: (UInt32)expiration;

@property (readwrite, assign) GUID guid;
@property (readwrite, assign) UInt32 entryID;
@property (readwrite, assign) UInt32 bytes;
@property (readonly) UInt32 stacks;
@property (readonly) UInt32 level;
@property (readonly) BOOL isDebuff;
@property (readonly) BOOL isActive;
@property (readonly) BOOL isPassive;
@property (readwrite, assign) UInt32 duration;
@property (readwrite, assign) UInt32 expiration;

@end
