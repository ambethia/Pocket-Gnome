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
 * $Id: OffsetController.m 422 2010-04-17 01:40:31Z ootoaoo $
 *
 */

#import "OffsetController.h"
#import "MemoryAccess.h"
#import "Controller.h"


// Rough estimate of where the text segment ends (0xB32E98 for 3.3.5a)
#define TEXT_SEGMENT_MAX_ADDRESS				0xB32E98

@interface OffsetController (Internal)

- (void)loadEveryOffset;
- (void)findOffsets: (const void*)data Len:(unsigned long)len;
- (NSData*)getAllMemory;

BOOL bDataCompare(const unsigned char* pData, const unsigned char* bMask, const char* szMask);

// new scans
- (NSDictionary*) findPattern: (unsigned char*)bMask 
			   withStringMask:(char*)szMask 
					 withData:(const void*)dw_Address 
					  withLen:(unsigned long)dw_Len;
@end



@implementation OffsetController

static OffsetController* sharedController = nil;

+ (OffsetController *)sharedController {
	if (sharedController == nil)
		sharedController = [[[self class] alloc] init];
	return sharedController;
}

- (id)init{
    self = [super init];
	if ( sharedController ){
		[self release];
		self = sharedController;
	}
    else if (self != nil) {
		
		sharedController = self;
		
		offsets = [[NSMutableDictionary alloc] init];
		_offsetsLoaded = NO;
		
		_offsetDictionary = [[NSDictionary dictionaryWithContentsOfFile: [[NSBundle mainBundle] pathForResource: @"OffsetSignatures" ofType: @"plist"]] retain];
		if ( !_offsetDictionary ){
			PGLog(@"[Offsets] Error, offset dictionary not found!");
		}
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(memoryIsValid:) name: MemoryAccessValidNotification object: nil];
    }
    return self;
}

- (void)dealloc {
	[offsets release];
	[_offsetDictionary release];
	[super dealloc];
}

- (void)memoryIsValid: (NSNotification*)notification {
    [self loadEveryOffset];
}

// tries to find all of our offsets!
- (void)loadEveryOffset{
	
	/* We used to prevent offset reloading, but PG could re-attach to a different wow version (i.e. we close the cata beta)
	if ( _offsetsLoaded )
		return;
	*/
	
	// remove old offsets
	[offsets removeAllObjects];
	
	// find the offsets!
	NSData *rawMemory = [self getAllMemory];
	[self findOffsets: [rawMemory bytes] Len:[rawMemory length]];
	
	// print out the offsets we have!
	for ( NSString *key in [_offsetDictionary allKeys] ){
		UInt32 offset = [self offset:key];
		if ( offset > 0 ){
			NSLog(@"%@: 0x%X", key, offset);
		}
	}
	
	// print out ones we didn't find
	for ( NSString *key in [_offsetDictionary allKeys] ){
		
		if ( [self offset:key] == 0 ){
			NSLog(@"[Offset] Error! No offset found for key %@", key);
		}
	}
	
	NSLog(@"[Offset] Loaded %d offsets!", [offsets count]);
	
	// can hard code some here
	
	_offsetsLoaded = YES;
	[[NSNotificationCenter defaultCenter] postNotificationName: OffsetsLoaded object: nil];
}

// we now no longer have to check start address! Yay new sweet method from Pocket Goblin!
- (void)findOffsets: (const void*)data Len:(unsigned long)len{
	
	if ( IS_PPC ){
		PGLog(@"[Offset] Power PC is not currently supported by Pocket Gnome!");
		return;
	}
	
	if ( _offsetDictionary ){
		
		NSArray *allKeys = [_offsetDictionary allKeys];
		
		// Intel or PPC?
		NSString *arch = @"Intel";
		NSRange range;
		
		// this will be a key, such as PLAYER_NAME_STATIC
		for ( NSString *key in allKeys ){
			
			// grab our offset masks for our appropriate instruction set
			NSDictionary *offsetData = [[_offsetDictionary valueForKey:key] valueForKey:arch];
			
			// Keys within offsetData:
			//	Mask
			//	Signature
			//	StartOffset
			//	Count	(which pattern # is the correct offset? Sadly we have to use this if there isn't a unique function using an offset)
			
			// lets get the raw data from our objects!
			NSString *dictMask					= [offsetData objectForKey: @"Mask"];
			NSString *dictSignature				= [offsetData objectForKey: @"Signature"];
			NSString *dictCount					= [offsetData objectForKey: @"Count"];
			NSString *dictAdditionalOffset		= [offsetData objectForKey: @"AdditionalOffset"];
			NSString *dictSubtractOffset		= [offsetData objectForKey: @"SubtractOffset"];
			BOOL useAddress						= [[offsetData objectForKey: @"UseAddress"] boolValue];
			
			// no offset data found, move on to the next one!
			if ( [dictMask length] == 0 || [dictSignature length] == 0 )
				continue;
			
			// what is the count #?
			unsigned int count = 1;
			if ( dictCount != nil ){
				count = [dictCount intValue];
			}
			
			unsigned long additionalOffset = 0x0;
			if ( [dictAdditionalOffset length] > 0 ){
				range.location = 2;
				range.length = [dictAdditionalOffset length]-range.location;
				
				const char *szAdditionalOffsetInHex = [[dictAdditionalOffset substringWithRange:range] UTF8String];
				additionalOffset = strtol(szAdditionalOffsetInHex, NULL, 16);
			}
			
			long subtractOffset = 0x0;
			if ( [dictSubtractOffset length] > 0 ){
				range.location = 2;
				range.length = [dictSubtractOffset length]-range.location;
				
				const char *szSubtractOffsetInHex = [[dictSubtractOffset substringWithRange:range] UTF8String];
				subtractOffset = strtol(szSubtractOffsetInHex, NULL, 16);
			}
			
			// allocate our bytes variable which will store our signature
			Byte *bytes = calloc( [dictSignature length]/2, sizeof( Byte ) );
			unsigned int i = 0, k = 0;
			
			// incrementing by 4 (to skip the beginning \x)
			for ( ;i < [dictSignature length]; i+=4 ){
				range.length = 2;
				range.location = i+2;
				
				const char *sigMask = [[dictSignature substringWithRange:range] UTF8String];
				long one = strtol(sigMask, NULL, 16);
				bytes[k++] = (Byte)one;
			}
			
			// get our mask
			const char *szMaskUTF8 = [dictMask UTF8String];
			char *szMask = strdup(szMaskUTF8);
			
			NSDictionary *offsetDict = nil;
			
			offsetDict = [self findPattern:bytes
							withStringMask:szMask 
									withData:data
									withLen:len];
			
			// we have results! yay!
			if ( [offsetDict count] ){
				
				// the key is the ADDRESS in which we found the offset!
				NSArray *allKeys = [[offsetDict allKeys] sortedArrayUsingSelector:@selector(compare:)];
				int i = 1;
				
				for ( NSNumber *address in allKeys ){
					
					UInt32 offset = [[offsetDict objectForKey:address] unsignedIntValue];
					
					if ( count == i ){
						
						// we are looking for the ADDRESS at which this sig was found (good for identifying the start of a function!)
						if ( useAddress ){
							[offsets setObject: [NSNumber numberWithUnsignedLong:([address unsignedLongValue] + additionalOffset - subtractOffset)] forKey:key];
							break;
						}
						// the offset we wanted that is in the signature
						else{
							[offsets setObject: [NSNumber numberWithUnsignedLong:(offset + additionalOffset - subtractOffset)] forKey:key];
							break;
						}
					}
					i++;
				}
			}
		}
	}
	// technically should never be here
	else{
		PGLog(@"[Offsets] No offset dictionary found, PG will be unable to function!");
	}
}

- (NSData*)getAllMemory{
	
	// this will store all the raw data!
	NSMutableData *data = [[NSMutableData alloc] init];

	// get the WoW PID
    pid_t wowPID = 0;
    ProcessSerialNumber wowPSN = [controller getWoWProcessSerialNumber];
    OSStatus err = GetProcessPID(&wowPSN, &wowPID);
	
    if ( (err == noErr) && (wowPID > 0) ){
		
        mach_port_t MySlaveTask;
        kern_return_t KernelResult = task_for_pid(current_task(), wowPID, &MySlaveTask);
		
		// try to get a task for this process
		
        if ( KernelResult == KERN_SUCCESS ){
            
			// sweet lets start grabbing memory and copying it into our process! yay!
            vm_address_t SourceAddress = 0;
            vm_size_t SourceSize = 0;
            vm_region_basic_info_data_t SourceInfo;
            mach_msg_type_number_t SourceInfoSize = VM_REGION_BASIC_INFO_COUNT;
            mach_port_t ObjectName = MACH_PORT_NULL;
            
            vm_size_t ReturnedBufferContentSize;
            Byte *ReturnedBuffer = nil;
			
            while ( KERN_SUCCESS == ( KernelResult = vm_region(MySlaveTask,&SourceAddress,&SourceSize,VM_REGION_BASIC_INFO,(vm_region_info_t) &SourceInfo,&SourceInfoSize,&ObjectName) ) ){
				
				
				// don't read too much!
				if ( SourceAddress + SourceSize > TEXT_SEGMENT_MAX_ADDRESS ){
					
					// we're just too far
					if ( SourceAddress >= TEXT_SEGMENT_MAX_ADDRESS ){
						NSLog(@"0x%X > 0x%X Breaking!", SourceAddress, TEXT_SEGMENT_MAX_ADDRESS);
						break;
					}
				}
				
				NSRange dataRange = NSMakeRange(SourceAddress, SourceSize);
				
				NSLog(@"[Offset] Success for reading from 0x%X to 0x%X  Protection: 0x%X", dataRange.location, dataRange.length + dataRange.location, SourceInfo.protection);
				
				// increase length
				[data increaseLengthBy:dataRange.length];
				
				// ensure we have access to this block
                if ( ( SourceInfo.protection & VM_PROT_READ ) ) {
                    NS_DURING {
                        ReturnedBuffer = malloc(SourceSize);
                        ReturnedBufferContentSize = SourceSize;
                        if ( (KERN_SUCCESS == vm_read_overwrite(MySlaveTask,SourceAddress,SourceSize,(vm_address_t)ReturnedBuffer,&ReturnedBufferContentSize)) &&
                            (ReturnedBufferContentSize > 0) )
                        {
							
							[data replaceBytesInRange:dataRange withBytes:ReturnedBuffer];
						}
                    } NS_HANDLER {
                    } NS_ENDHANDLER
                    
                    if ( ReturnedBuffer != nil ) {
                        free( ReturnedBuffer );
                        ReturnedBuffer = nil;
                    }
                }
				// unable to read data, so lets just insert and zero it out!
				else{
					[data resetBytesInRange:dataRange];
					
					NSLog(@"[Offset] Unable to read block, flags: 0x%X", SourceInfo.protection);
				}
				
				// reset some values to search some more
                SourceAddress += SourceSize;
			}
		}
	}
	
	NSLog(@"[Offset] Total data: 0x%X", [data length]);
	
	return [[data retain] autorelease];	
}

BOOL bDataCompare(const unsigned char* pData, const unsigned char* bMask, const char* szMask){
	for(;*szMask;++szMask,++pData,++bMask){
		if(*szMask=='x' && *pData!=*bMask ){
			return false;
		}
	}
	return true;
}

#pragma mark Public

- (unsigned long) offset: (NSString*)key{
	NSNumber *offset = [offsets objectForKey: key];
	if ( offset ){
		return [offset unsignedLongValue];
	}
	return 0;
}

- (NSDictionary*)offsetWithByteSignature: (NSString*)signature 
								withMask:(NSString*)mask{
	
	if ( IS_PPC) {
		NSLog(@"[Offset] No support for PowerPC!");
		return nil;		
	}
	
	// grab all memory into our own memory space!
	NSData *data = [self getAllMemory];
	
	// convert to Byte*
	NSUInteger newLength = [data length];
	Byte *byteData = (Byte*)malloc(newLength);
	memcpy(byteData, [data bytes], newLength);
	
	// the list we'll return!
	NSDictionary *offsetDict = nil;
	
	// we're good to go!
	if ( data != nil ){
		
		// allocate our bytes variable which will store our signature
		Byte *bytes = calloc( [signature length]/2, sizeof( Byte ) );
		unsigned int i = 0, k = 0;
		NSRange range;
		
		// incrementing by 4 (to skip the beginning \x)
		for ( ;i < [signature length]; i+=4 ){
			range.length = 2;
			range.location = i+2;
			
			const char *sigMask = [[signature substringWithRange:range] UTF8String];
			long one = strtol(sigMask, NULL, 16);
			bytes[k++] = (Byte)one;
		}
		
		// get our mask
		const char *szMaskUTF8 = [mask UTF8String];
		char *szMask = strdup(szMaskUTF8);
		
		offsetDict = [self findPattern:bytes
						withStringMask:szMask 
								withData:byteData
								withLen:[data length]];
	}
	else {
		PGLog(@"[Offset] Unable to read memory!");
	}
	
	// free our buffer
	if ( byteData )
		free( byteData );
	
	return [[offsetDict retain] autorelease];
}

- (NSDictionary*) findPattern: (unsigned char*)bMask 
			   withStringMask:(char*)szMask 
					 withData:(const void*)dw_Address 
					  withLen:(unsigned long)dw_Len
{
	unsigned long i = 0;
	NSMutableDictionary *list = [NSMutableDictionary dictionary];
	
	for ( ; i < dw_Len; i++ ){
		
		if ( bDataCompare( (unsigned char*)( dw_Address+i ),bMask,szMask) ){
			
			const unsigned char *pData = (unsigned char*)( dw_Address+i );
			char *mask = szMask;
			unsigned long j = 0;
			for ( ;*mask;++mask,++pData){
				if ( j && *mask == 'x' ){
					break;
				}
				if ( *mask == '?' ){
					j++;
				}
			}
			
			unsigned long offset = 0, k;
			for (k=0;j>0;j--,k++){
				--pData;
				offset <<= 8;  
				offset ^= (long)*pData & 0xFF;   
			}
			
			if ( offset > 0x0 || i > 0 ){
				//NSLog(@" [Offset] Found 0x%X, adding to dictionary at 0x%X", offset, i);
				[list setObject:[NSNumber numberWithUnsignedInt:offset] forKey:[NSNumber numberWithUnsignedInt:i]];
			}
		}
	}
	
	return [[list retain] autorelease];
}

@end

/*
 
 Official place for notes on offsets!!
 
 GetNumCompanions
 0x0		- Number of Pets
 0x4		- Pointers to list of pets
 0x10	- Number of mounts
 0x14	- Pointer to list of mounts
 
 PLAYER_NAME_LIST	- Basically you have a bunch of linked lists here, wish I understand some calling functions better
 0x10	- Friends list
 0x14	- Guildies
 0x24	- People within range
 
 PLAYER_GUID_NAME	- This has the player's 64-bit GUID + name!
 0x0		- 64-bit GUID
 0x8		- Player name
 
 lua_GetInboxNumItems
 First offset
 0x0 = # of total items
 0x4 = # of items in the window
 
 */
