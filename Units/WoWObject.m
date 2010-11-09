//
//  WoWObject.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 12/29/07.
//  Copyright 2007 Savory Software, LLC. All rights reserved.
//

#import "WoWObject.h"
#import "Offsets.h"

#define STALE_TIME  (-10.0f)
#define MAX_NOT_IN_LIST_UNTIL_STALE	5

@implementation WoWObject

- (id) init
{
    self = [super init];
    if (self != nil) {
        _baseAddress = nil;
        _infoAddress = nil;
		_notInObjectListCounter = 0;
		_objectFieldAddress = 0;
		_unitFieldAddress = 0;
        self.memoryAccess = nil;
        self.refreshDate = [NSDate distantFuture];
    }
    return self;
}

- (id)initWithAddress: (NSNumber*)address inMemory: (MemoryAccess*)memory {
    
    self = [self init];
    if (self != nil) {
        _baseAddress = [address copy];
        _memory = [memory retain];
        cachedEntryID = 0;
		_notInObjectListCounter = 0;
        cachedGUID = [self GUID];
    }
    return self;
}

+ (id)objectWithAddress: (NSNumber*)address inMemory: (MemoryAccess*)memory {
    if(!address || ![address unsignedIntValue]) return nil;
    
    return [[[WoWObject alloc] initWithAddress: address inMemory: memory] autorelease];
}


- (void) dealloc
{
    [_baseAddress release];
    [_infoAddress release];
    [_memory release];
    self.refreshDate = nil;
    
    [super dealloc];
}

#pragma mark -
#pragma mark NSObject

- (unsigned)hash {
    return [self baseAddress];
}

- (BOOL)isEqual: (id)object {
    if( [object isKindOfClass: [WoWObject class]] )
        return ([self baseAddress] == [object baseAddress]);
    return NO;
}

- (BOOL)isEqualToObject: (WoWObject*)unit {
    return (([self baseAddress] == [unit baseAddress]) && ([self GUID] == [unit GUID]));
}

- (NSString*)description {
    return [NSString stringWithFormat: @"<%@: %d; Addr: %@>",
            [self className],
            [self entryID], 
            [NSString stringWithFormat: @"0x%X", [self baseAddress]]];
}

#pragma mark -
#pragma mark Internal

- (UInt32)baseAddress {
    return [_baseAddress unsignedIntValue];
}

// 1 read, cached
- (UInt32)infoAddress {
    if(!_infoAddress) {
        UInt32 value = 0;
        if([_memory loadDataForObject: self atAddress: ([self baseAddress] + OBJECT_FIELDS_PTR) Buffer: (Byte *)&value BufLength: sizeof(value)] && (value >= 0)) {
            [_infoAddress autorelease];
            _infoAddress = [[NSNumber numberWithUnsignedInt: value] retain];
        }
    }
    
    return _infoAddress ? [_infoAddress unsignedIntValue] : 0;
}

- (UInt32)objectFieldAddress{
	
	if ( _objectFieldAddress ){
		return _objectFieldAddress;
	}
	
	// read it
	[_memory loadDataForObject: self atAddress: ([self baseAddress] + OBJECT_FIELDS_PTR) Buffer: (Byte *)&_objectFieldAddress BufLength: sizeof(_objectFieldAddress)];
	return _objectFieldAddress;
}

- (UInt32)unitFieldAddress{
	
	if ( _unitFieldAddress ){
		return _unitFieldAddress;
	}
	
	// read it
	[_memory loadDataForObject: self atAddress: ([self baseAddress] + OBJECT_UNIT_FIELDS_PTR) Buffer: (Byte *)&_unitFieldAddress BufLength: sizeof(_unitFieldAddress)];

	return _unitFieldAddress;
}

#pragma mark -
#pragma mark Accessors

@synthesize memoryAccess = _memory;
@synthesize refreshDate = _refresh;
@synthesize notInObjectListCounter = _notInObjectListCounter;
@synthesize cachedEntryID;
@synthesize cachedGUID;

- (BOOL)isNPC {
    if([self objectTypeID] == TYPEID_UNIT)
        return YES;
    return NO;
}

- (BOOL)isPlayer {
    if([self objectTypeID] == TYPEID_PLAYER)
        return YES;
    return NO;
}

- (BOOL)isNode {
    if([self objectTypeID] == TYPEID_GAMEOBJECT)
        return YES;
    return NO;
}

- (NSNumber*)ID {
    return [NSNumber numberWithUnsignedInt: [self entryID]];
}

- (UInt32)objectBaseID {
    UInt32 value = 0;
    if([_memory loadDataForObject: self atAddress: ([self baseAddress] + OBJECT_BASE_ID) Buffer: (Byte *)&value BufLength: sizeof(value)])
        return value;
    return 0;
}

- (UInt32)objectTypeID {
    UInt32 value = 0;
    if([_memory loadDataForObject: self atAddress: ([self baseAddress] + OBJECT_TYPE_ID) Buffer: (Byte *)&value BufLength: sizeof(value)])
        return value;
    return 0;
}

// 1 read
- (UInt64)GUID {
    UInt64 value = 0;
    if([_memory loadDataForObject: self atAddress: [self infoAddress] Buffer: (Byte *)&value BufLength: sizeof(value)]){
        return value;
	}
    return 0;
}

- (UInt32)lowGUID {
    return (UInt32)([self GUID] & 0x00000000FFFFFFFFULL);
}

- (UInt32)highGUID {
    return (UInt32)(([self GUID] >> 32) & 0x00000000FFFFFFFFULL);
}

- (UInt32)typeMask {
    UInt32 value = 0;
    if([_memory loadDataForObject: self atAddress: ([self infoAddress] + OBJECT_FIELD_TYPE) Buffer: (Byte *)&value BufLength: sizeof(value)])
        return value;
    return 0;
}

- (UInt32)entryID {
    UInt32 value = 0;
    [_memory loadDataForObject: self atAddress: ([self infoAddress] + OBJECT_FIELD_ENTRY) Buffer: (Byte *)&value BufLength: sizeof(value)];
    
    if(value && (cachedEntryID != value)) {
        cachedEntryID = value;
    }
    
    return cachedEntryID;
}

- (UInt32)cachedEntryID{
	
	if ( cachedEntryID == 0 ){
		return [self entryID];
	}
	
	return cachedEntryID;		
}

// 2 reads (object type, GUID)
- (BOOL)isValid {
    // is the item stale?
    if([self isStale]) return NO;

    // check for valid object type
    // verify GUID
    UInt32 typeID = [self objectTypeID];
    
    if( (typeID > TYPEID_UNKNOWN) && (typeID < TYPEID_MAX))
        return (cachedGUID == [self GUID]);
    return NO;
}

- (BOOL)isStale {
    if( [self.refreshDate timeIntervalSinceNow] < STALE_TIME)
        return YES;
	if ( _notInObjectListCounter >= MAX_NOT_IN_LIST_UNTIL_STALE )
		return YES;

    return NO;
}

- (Position*)position {
    return nil;
}

- (NSString*)name {
    return @"";
}

// 3 reads
- (UInt32)prevObjectAddress {
    UInt32 value = 0, value2 = 0;
    if([_memory loadDataForObject: self atAddress: [self baseAddress] + OBJECT_STRUCT3_POINTER Buffer: (Byte *)&value BufLength: sizeof(value)]) {
        value = value - OBJECT_STRUCT3_POINTER;
        if([_memory loadDataForObject: self atAddress: value Buffer: (Byte *)&value2 BufLength: sizeof(value2)]) {
            if( value2 == [self objectBaseID])
                return value;
        }
    }
    return 0;
}

// 3 reads
- (UInt32)nextObjectAddress {
    UInt32 value = 0, value2 = 0;
    if([_memory loadDataForObject: self atAddress: [self baseAddress] + OBJECT_STRUCT4_POINTER Buffer: (Byte *)&value BufLength: sizeof(value)]) {
        if([_memory loadDataForObject: self atAddress: value Buffer: (Byte *)&value2 BufLength: sizeof(value2)]) {
            if( value2 == [self objectBaseID])
                return value;
        }
    }
    return 0;
}

#pragma mark -
#pragma mark Memory Protocol

- (UInt32)memoryStart {
    return [self baseAddress];
}

- (UInt32)memoryEnd {
    UInt32 value = 0;
    if([_memory loadDataForObject: self atAddress: ([self baseAddress] + OBJECT_FIELDS_END_PTR) Buffer: (Byte*)&value BufLength: sizeof(value)]) {
        return value;
    }
    return 0;
}

- (NSString*)descriptionForOffset: (UInt32)offset {
    NSString *desc = nil;
    
    if(offset < ([self infoAddress] - [self baseAddress])) {
        switch(offset) {
            case OBJECT_BASE_ID:
                desc = @"Object Structure";
                break;
            case OBJECT_FIELDS_PTR:
                desc = @"Object Fields Pointer";
                break;
            case OBJECT_FIELDS_END_PTR:
                desc = @"Object Fields End";
                break;
            case OBJECT_TYPE_ID:
                desc = @"Object Type ID";
                break;
            case OBJECT_GUID_LOW32:
                desc = @"Object GUID (low 32 bits)";
                break;
                
            case OBJECT_STRUCT1_POINTER:
                desc = @"Other Structure Pointer (?)";
                break;
            case OBJECT_STRUCT2_POINTER:
                desc = @"Parent Structure Pointer (?)";
                break;
            case OBJECT_STRUCT3_POINTER:
                desc = @"Previous Structure Pointer";
                break;
            case OBJECT_STRUCT4_POINTER:;
                desc = @"Next Structure Pointer";
                break;
			case OBJECT_UNIT_FIELDS_PTR:;
                desc = @"Unit Fields Pointer";
                break;
			case ITEM_FIELDS_PTR:;
                desc = @"Item Fields Pointer";
                break;
        }
    } else {
        offset = offset - ([self infoAddress] - [self baseAddress]);
        
        switch(offset) {
            case OBJECT_FIELD_GUID:
                desc = @"Object GUID";
                break;
            case OBJECT_FIELD_TYPE:
                desc = @"Object Type";
                break;
            case OBJECT_FIELD_ENTRY:
                desc = @"Object Entry ID";
                break;
            case OBJECT_FIELD_SCALE_X:
                desc = @"Object Scale (float)";
                break;
        }
    }

    return desc;
}

@end
