//
//  Node.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 12/27/07.
//  Copyright 2007 Savory Software, LLC. All rights reserved.
//

#import "Node.h"
#import "ObjectConstants.h"

enum NodeDataFields
{
    GAMEOBJECT_POS_X            = 0x104,
    GAMEOBJECT_POS_Y            = 0x108,
    GAMEOBJECT_POS_Z            = 0x10C,
};

#define NODE_NAMESTRUCT_POINTER_OFFSET     0x1BC

enum eNodeNameStructFields {
    NAMESTRUCT_NAME_PTR         = 0x94,
    NAMESTRUCT_ENTRY_ID         = 0xA4,
};

@interface Node ()
@property (readwrite, retain) NSString *name;
@end

@implementation Node

+ (id)nodeWithAddress: (NSNumber*)address inMemory: (MemoryAccess*)memory {
    return [[[Node alloc] initWithAddress: address inMemory: memory] autorelease];
}

- (void) dealloc
{
    [_name release];
    [super dealloc];
}


- (NSString*)description {
    return [NSString stringWithFormat: @"<Node: \"%@\" (%d)>", [self name], [self entryID]];
}

- (NSString*)name {
    // if we already have a name saved, return it
    if(_name && [_name length]) {
        if(_nameEntryID == [self entryID])
            return [[_name retain] autorelease];
    }
    
    // if we don't, load the name out of memory
    if([self objectTypeID] == TYPEID_GAMEOBJECT) {
        //+0x218
        //----
        //+0x74 - pointer to string
        //+0x84 - node entry ID
        //+0xA8 - node name as string
        
        // get the address from the object itself
        UInt32 value = 0;
        if([_memory loadDataForObject: self atAddress: ([self baseAddress] + NODE_NAMESTRUCT_POINTER_OFFSET) Buffer: (Byte *)&value BufLength: sizeof(value)])
        {
            UInt32 entryID = 0, stringPtr = 0;
            
            // verify that the entry IDs match, then follow the pointer to the string value
            if([_memory loadDataForObject: self atAddress: (value + NAMESTRUCT_NAME_PTR) Buffer: (Byte *)&stringPtr BufLength: sizeof(stringPtr)] &&
               [_memory loadDataForObject: self atAddress: (value + NAMESTRUCT_ENTRY_ID) Buffer: (Byte *)&entryID BufLength: sizeof(entryID)])
            {
                if( (entryID == [self entryID]) && stringPtr )
                {
                    char name[65];
                    name[64] = 0;
                    if([_memory loadDataForObject: self atAddress: stringPtr Buffer: (Byte *)&name BufLength: sizeof(name)-1])
                    {
                        NSString *newName = [NSString stringWithUTF8String: name];
                        if([newName length]) {
                            [self setName: newName];
                            return newName;
                        }
                    }
                }
            }
        }
    }
    return @"";
}

- (void)setName: (NSString*)name {
    id temp = nil;
    [name retain];
    @synchronized (@"Name") {
        temp = _name;
        _name = name;
        _nameEntryID = [self entryID];
    }
    [temp release];
}


// 1 read
- (Position*)position {
    float pos[3] = {-1.0f, -1.0f, -1.0f };
    [_memory loadDataForObject: self atAddress: ([self baseAddress] + GAMEOBJECT_POS_X) Buffer: (Byte *)&pos BufLength: sizeof(float)*3];
    return [Position positionWithX: pos[0] Y: pos[1] Z: pos[2]];
}

- (NodeFlags)flags {
    UInt32 value = 0;
    if([_memory loadDataForObject: self atAddress: ([self unitFieldAddress] + GAMEOBJECT_FLAGS) Buffer: (Byte *)&value BufLength: sizeof(value)]) {
        return value;
    }
    return 0;
}

- (GUID)owner {
    UInt64 value = 0;
    if([_memory loadDataForObject: self atAddress: ([self unitFieldAddress] + OBJECT_FIELD_CREATED_BY) Buffer: (Byte *)&value BufLength: sizeof(value)]) {
        return value;
    }
    return 0;
}

// this could be ENTIRELY wrong, but just my guess, from 0-255
//	I use it for the gates in strand
- (UInt8)objectHealth{
    UInt8 value = 0;
    if([_memory loadDataForObject: self atAddress: ([self unitFieldAddress] + GAMEOBJECT_BYTES_1 + 0x3) Buffer: (Byte *)&value BufLength: sizeof(value)]) {
        return value;
    }
    return -1;
}

- (UInt32)nodeType {
    UInt32 value = 0;
    if([_memory loadDataForObject: self atAddress: ([self unitFieldAddress] + GAMEOBJECT_BYTES_1) Buffer: (Byte *)&value BufLength: sizeof(value)]) {
        return ((CFSwapInt32HostToLittle(value) >> 8) & 0xFF);
    }
    return -1;
}

// 0-255,  0 being not visible
- (UInt16)alpha{
	UInt16 value = 0;
    if([_memory loadDataForObject: self atAddress: ([self baseAddress] + 0xC0) Buffer: (Byte *)&value BufLength: sizeof(value)]) {
        return value;
    }
    return 0;
}

// 1 read
- (BOOL)validToLoot {
    UInt32 value = 0;
    if([_memory loadDataForObject: self atAddress: ([self unitFieldAddress] + GAMEOBJECT_BYTES_1) Buffer: (Byte *)&value BufLength: sizeof(value)]) {
        return (CFSwapInt32HostToLittle(value) & 0xFF);
    }
    return NO;
}

- (NSImage*)imageForNodeType: (UInt32)typeID {
    switch(typeID) {
        case GAMEOBJECT_TYPE_DOOR:
            return [NSImage imageNamed: @"BinderGossipIcon"];
            break;
        case GAMEOBJECT_TYPE_BUTTON:
            return [NSImage imageNamed: @"BinderGossipIcon"];
            break;
        case GAMEOBJECT_TYPE_QUESTGIVER:
            return [NSImage imageNamed: @"AvailableQuestIcon"];
            break;
        case GAMEOBJECT_TYPE_CONTAINER:
            return [NSImage imageNamed: @"BinderGossipIcon"];
            break;
        case GAMEOBJECT_TYPE_BINDER:
            return [NSImage imageNamed: @"BinderGossipIcon"];
            break;
        case GAMEOBJECT_TYPE_GENERIC:
            return [NSImage imageNamed: @"GossipGossipIcon"];
            break;
        case GAMEOBJECT_TYPE_TRAP:
            return [NSImage imageNamed: @"WarnTriangle"];
            break;
        case GAMEOBJECT_TYPE_CHAIR:
            return [NSImage imageNamed: @"BinderGossipIcon"];
            break;
        case GAMEOBJECT_TYPE_SPELL_FOCUS:
            return [NSImage imageNamed: @"WarnTriangle"];
            break;
        case GAMEOBJECT_TYPE_TEXT:
            return [NSImage imageNamed: @"TrainerGossipIcon"];
            break;
        case GAMEOBJECT_TYPE_GOOBER:
            return [NSImage imageNamed: @"BinderGossipIcon"];
            break;
        case GAMEOBJECT_TYPE_DUEL_ARBITER:
            return [NSImage imageNamed: @"MinimapGuideFlag"];
            break;
        case GAMEOBJECT_TYPE_TRANSPORT:
            return [NSImage imageNamed: @"TaxiGossipIcon"];
            break;
        case GAMEOBJECT_TYPE_MO_TRANSPORT:
            return [NSImage imageNamed: @"TaxiGossipIcon"];
            break;
        case GAMEOBJECT_TYPE_FISHING_BOBBER:
            return [NSImage imageNamed: @"BinderGossipIcon"];
            break;
        case GAMEOBJECT_TYPE_RITUAL:
            return [NSImage imageNamed: @"BinderGossipIcon"];
            break;
        case GAMEOBJECT_TYPE_MAILBOX:
            return [NSImage imageNamed: @"VendorGossipIcon"];
            break;
        case GAMEOBJECT_TYPE_AUCTIONHOUSE:
            return [NSImage imageNamed: @"BankerGossipIcon"];
            break;
        case GAMEOBJECT_TYPE_GUARDPOST:
            return [NSImage imageNamed: @"Combat"];
            break;
        case GAMEOBJECT_TYPE_PORTAL:
            return [NSImage imageNamed: @"BinderGossipIcon"];
            break;
        case GAMEOBJECT_TYPE_MEETING_STONE:
            return [NSImage imageNamed: @"BinderGossipIcon"];
            break;
        case GAMEOBJECT_TYPE_FLAGSTAND:
            return [NSImage imageNamed: @"MinimapGuideFlag"];
            break;
        case GAMEOBJECT_TYPE_FISHINGHOLE:
            return [NSImage imageNamed: @"ResourceBlip"];
            break;
        case GAMEOBJECT_TYPE_GUILDBANK:
            return [NSImage imageNamed: @"BankerGossipIcon"];
            break;
        default:
            return [NSImage imageNamed: @"Scroll"];
    }
}

- (NSString*)stringForNodeType: (UInt32)typeID {
    switch(typeID) {
        case GAMEOBJECT_TYPE_DOOR:
            return @"Door";
            break;
        case GAMEOBJECT_TYPE_BUTTON:
            return @"Button";
            break;
        case GAMEOBJECT_TYPE_QUESTGIVER:
            return @"Quest Giver";
            break;
        case GAMEOBJECT_TYPE_CONTAINER:
            return ((([self flags] & 4) == 4) ? @"Container (Quest)" : @"Container");
            break;
        case GAMEOBJECT_TYPE_BINDER:
            return @"Binder";
            break;
        case GAMEOBJECT_TYPE_GENERIC:
            return @"Generic/Sign";
            break;
        case GAMEOBJECT_TYPE_TRAP:
            return @"Trap/Fire";
            break;
        case GAMEOBJECT_TYPE_CHAIR:
            return @"Chair";
            break;
        case GAMEOBJECT_TYPE_SPELL_FOCUS:
            return @"Spell Focus";
            break;
        case GAMEOBJECT_TYPE_TEXT:
            return @"Text/Book";
            break;
        case GAMEOBJECT_TYPE_GOOBER:
            return @"Goober";
            break;
        case GAMEOBJECT_TYPE_AREADAMAGE:
            return @"Area Damage";
            break;
        case GAMEOBJECT_TYPE_CAMERA:
            return @"Camera";
            break;
        case GAMEOBJECT_TYPE_MAP_OBJECT:
            return @"Map Object";
            break;
        case GAMEOBJECT_TYPE_DUEL_ARBITER:
            return @"Duel Arbiter";
            break;
        case GAMEOBJECT_TYPE_TRANSPORT:
            return @"Transport";
            break;
        case GAMEOBJECT_TYPE_MO_TRANSPORT:
            return @"Transport";
            break;
        case GAMEOBJECT_TYPE_FISHING_BOBBER:
            return @"Fishing Bobber";
            break;
        case GAMEOBJECT_TYPE_RITUAL:
            return @"Ritual/Summon";
            break;
        case GAMEOBJECT_TYPE_MAILBOX:
            return @"Mailbox";
            break;
        case GAMEOBJECT_TYPE_AUCTIONHOUSE:
            return @"Auction House";
            break;
        case GAMEOBJECT_TYPE_GUARDPOST:
            return @"Guard Post";
            break;
        case GAMEOBJECT_TYPE_PORTAL:
            return @"Spell/Portal";
            break;
        case GAMEOBJECT_TYPE_MEETING_STONE:
            return @"Meeting Stone";
            break;
        case GAMEOBJECT_TYPE_FLAGSTAND:
            return @"Flag Stand";
            break;
        case GAMEOBJECT_TYPE_FISHINGHOLE:
            return @"Fishing Hole";
            break;
        case GAMEOBJECT_TYPE_GUILDBANK:
            return @"Guild Bank";
            break;
        case GAMEOBJECT_TYPE_AURA_GENERATOR:
            return @"Aura Generator";
            break;
        case GAMEOBJECT_TYPE_BARBER_CHAIR:
            return @"Barbershop";
            break;
        case GAMEOBJECT_TYPE_DESTRUCTIBLE_BUILDING:
            return @"Destructible Object";
            break;
        case GAMEOBJECT_TYPE_TRAPDOOR:
            return @"Teleport/Transport";
            break;
        default:
            return [NSString stringWithFormat: @"Unknown (%d)", typeID];
    }
}

- (BOOL)isUseable {
    switch([self nodeType]) {
        case GAMEOBJECT_TYPE_DOOR:
        case GAMEOBJECT_TYPE_BUTTON:
        case GAMEOBJECT_TYPE_QUESTGIVER:
        case GAMEOBJECT_TYPE_CONTAINER:
        case GAMEOBJECT_TYPE_BINDER:
        case GAMEOBJECT_TYPE_CHAIR:
        case GAMEOBJECT_TYPE_TEXT:
        case GAMEOBJECT_TYPE_GOOBER:
        case GAMEOBJECT_TYPE_RITUAL:
        case GAMEOBJECT_TYPE_MAILBOX:
		case GAMEOBJECT_TYPE_AUCTIONHOUSE:
        case GAMEOBJECT_TYPE_PORTAL:
        case GAMEOBJECT_TYPE_MEETING_STONE:
        case GAMEOBJECT_TYPE_FLAGSTAND:
        case GAMEOBJECT_TYPE_GUILDBANK:
        case GAMEOBJECT_TYPE_TRAPDOOR:
            return YES;
            break;
        default:
            return NO;
    }
}

#pragma mark Deprecated Thottbot Loading

/*

- (void)loadNodeName {
    return;
    [_connection cancel];
    [_connection release];
    _connection = [[NSURLConnection alloc] initWithRequest: [NSURLRequest requestWithURL: [NSURL URLWithString: [NSString stringWithFormat: @"http://thottbot.com/o%d", [self entryID]]]] delegate: self];
    if(_connection) {
        [_downloadData release];
        _downloadData = [[NSMutableData data] retain];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [_downloadData setLength: 0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [_downloadData appendData: data];
}

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error
{
    // release the connection, and the data object
    [_connection release];  _connection = nil;
    [_downloadData release]; _downloadData = nil;
 
    // inform the user
    log(LOG_GENERAL, @"Connection failed! Error - %@ %@",
          [error localizedDescription],
          [[error userInfo] objectForKey:NSErrorFailingURLStringKey]);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    // get the download as a string
    NSString *wowhead = [[[NSString alloc] initWithData: _downloadData encoding: NSUTF8StringEncoding] autorelease];
    
    // release the connection, and the data object
    [_connection release];  _connection = nil;
    [_downloadData release]; _downloadData = nil;
    
    // parse out the name
    if(wowhead && [wowhead length]) {
        NSScanner *scanner = [NSScanner scannerWithString: wowhead];
        
        // get the spell name
        int scanSave = [scanner scanLocation];
        if([scanner scanUpToString: @"<div class=\"sitetitle\"><font size=\"+2\"><b>Object: " intoString: nil] && [scanner scanString: @"<div class=\"sitetitle\"><font size=\"+2\"><b>Object: " intoString: nil]) {
            NSString *newName = nil;
            if([scanner scanUpToString: @"</b></font></div>" intoString: &newName]) {
                if(newName && [newName length]) {
                    [self setName: newName];
                    [[NSNotificationCenter defaultCenter] postNotificationName: NodeNameLoadedNotification object: self];
                }
            }
        } else {
            [scanner setScanLocation: scanSave];
        }
    }
}
*/

@end
