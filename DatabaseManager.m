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
 * $Id: DatabaseManager.m 315 2010-04-12 04:12:45Z Tanaris4 $
 *
 */

#import "DatabaseManager.h"
#import "Controller.h"
#import "OffsetController.h"


@implementation DatabaseManager

- (id) init{
    self = [super init];
    if ( self != nil ){
		
		_tables = [[NSMutableDictionary dictionary] retain];
		_dataLoaded = NO;
		
//		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(offsetsLoaded:) name: OffsetsLoaded object: nil];
	}
	return self;
}

- (void)dealloc{
	[super dealloc];
}

#pragma mark -

typedef struct ClientDb {
    UInt32 _vtable;                     // 0x0
    UInt32 isLoaded;            // 0x4
    UInt32 numRows;                     // 0x8                          // 49379
    UInt32 maxIndex;            // 0xC                          // 74445
    UInt32 minIndex;            // 0x10                         // 1
	UInt32 stringTablePtr;  // 0x14
	UInt32 _vtable2;                // 0x18
	// array of row pointers after this...
	UInt32 row1;                    // 0x1C                         // this points to the first actual row in the database (in theory we could use this, then loop until we hit numRows and we have all the rows)
	UInt32 row2;                    // 0x20
	
} ClientDb;

// huge thanks to Apoc! Code below from him
- (BOOL)unPackRow:(UInt32)addressOfStruct withStruct:(void*)obj withStructSize:(size_t)structSize{
	
	//NSLog(@"Obj address3: 0x%X", obj);
	
	MemoryAccess *memory = [controller wowMemoryAccess];
	if ( !memory || ![memory isValid] ){
		return NO;
	}
	
	Byte byteBuffer[0x5000] = {0};
	
	byteBuffer[0] = [memory readInt:addressOfStruct withSize:sizeof(Byte)];
	int currentAddress = 1;
	int i = 0;
	const int size = 0x2C0;
	
	for ( i = addressOfStruct + 1; currentAddress < size; ++i ){
		
		byteBuffer[currentAddress++] = [memory readInt:i withSize:sizeof(Byte)];
		
		Byte atI = [memory readInt:i withSize:sizeof(Byte)];
		Byte prevI = [memory readInt:i - 1 withSize:sizeof(Byte)];
		
		if ( atI == prevI ){
			
			Byte j = 0;
			for ( j = [memory readInt:i + 1 withSize:sizeof(Byte)]; j != 0; byteBuffer[currentAddress++] = [memory readInt:i withSize:sizeof(Byte)] ){
				j--;
			}
			i += 2;
			if ( currentAddress < size ){
				byteBuffer[currentAddress++] = [memory readInt:i withSize:sizeof(Byte)];
			}
		}
	}
	
	memcpy( obj, &byteBuffer, structSize);
	
	return YES;
}

- (BOOL)getObjectForRow:(int)index withTable:(ClientDbType)tableOffset withStruct:(void*)obj withStructSize:(size_t)structSize{
	
	NSNumber *table = [NSNumber numberWithInt:tableOffset];
	
	MemoryAccess *memory = [controller wowMemoryAccess];
	if ( !memory || ![memory isValid] ){
		return NO;
	}
	
	//NSLog(@"Obj address2: 0x%X", obj);
	
	// snag our address
	NSNumber *addr = [_tables objectForKey:table];
	UInt32 dbAddress = 0x0;
	if ( addr ){
		dbAddress = [addr unsignedIntValue];
	}
	
	//NSLog(@"[Db] Loading data for index %d", index);
	
	// time to load our data
	ClientDb db;
	if ( dbAddress && [memory loadDataForObject:self atAddress:dbAddress Buffer:(Byte *)&db BufLength:sizeof(db)] ){
		//NSLog(@"[Db] Loaded database '%@' with base pointer 0x%X and row2: 0x%X", table, dbAddress, db.row2);
		
		// time to snag our row!
		if ( index >= db.minIndex && index <= db.maxIndex ){
			
			UInt32 rowPointer = db.row2 + ( 4 * (index - db.minIndex) );
			//NSLog(@"[Db] Row pointer: 0x%X %d", rowPointer, (index - db.minIndex));
			UInt32 structAddress = [memory readInt:rowPointer withSize:sizeof(UInt32)];
			
			// we don't have a pointer to a struct, quite unfortunate
			if ( structAddress == 0 ){
				return NO;
			}
			
			//NSLog(@"[Db] We have a valid struct address! Row is pointing to 0x%X", structAddress);
			
			if ( tableOffset == Spell_ ){
				if ( [self unPackRow:structAddress withStruct:obj withStructSize:structSize] ){
					return YES;
				}
			}
			// no unpacking necessary!
			else{
				PGLog(@"loading at 0x%X", structAddress);
				[memory loadDataForObject:self atAddress:structAddress Buffer:obj BufLength:structSize];
				return YES;
			}
		}
	}
	
	return NO;      
}

#pragma mark Notifications

- (void)offsetsLoaded: (NSNotification*)notification {
	
	if ( _dataLoaded )
		return;
	
	// lets load all of our valid offsets for all of our client DBs! (should be pretty patch safe, time will tell!)
	MemoryAccess *memory = [controller wowMemoryAccess];
	if ( memory && [memory isValid] ){
        
		UInt32 firstOffset = [offsetController offset:@"ClientDb_RegisterBase"] + 0x21;
		NSLog(@"first is what? 0x%X", firstOffset);
		
		int i = 0;
		for ( ; i < 0xEC; i++ ){
			UInt32 ptr = [memory readInt:firstOffset + (0x29*i) withSize:sizeof(UInt32)];
			UInt32 offset = [memory readInt:firstOffset + (0x29*i) + 0x8 withSize:sizeof(UInt32)];
			UInt32 tableAddress = [memory readInt:ptr withSize:sizeof(UInt32)];
			
			[_tables setObject:[NSNumber numberWithUnsignedInt:tableAddress] forKey:[NSNumber numberWithInt:offset]];       // 0x194
			
			PGLog(@"[%d] Adding address 0x%X for 0x%X", i, tableAddress, offset);
		}
	}
	
	_dataLoaded = YES;
}

@end