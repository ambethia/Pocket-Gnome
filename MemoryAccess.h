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

#import <Cocoa/Cocoa.h>


@interface MemoryAccess : NSObject
{
    pid_t AppPid;
    mach_port_t MySlaveTask;
    AuthorizationRef gAuth;
    
    int readsProcessed;
    float throughput;
	
	// statistics info
	int _totalReadsProcessed;
	int _totalWritesProcessed;
    NSDate *_startTime;
	
    NSMutableDictionary *_loaderDict;
}

// we shouldn't really use this
+ (MemoryAccess*)sharedMemoryAccess;


- (id)init;
- (id)initWithPID:(pid_t)PID;
- (BOOL)isValid;

@property float throughput;
@property (readonly) NSDictionary *operationsDictionary;

- (void)resetLoadCount;
- (void)printLoadCount;
- (int)loadCount;

// for statistics
- (float)readsPerSecond;
- (float)writesPerSecond;
- (void)resetCounters;
- (NSDictionary*)operationsByClassPerSecond;

// save record to application addresses
- (BOOL)saveDataForAddress: (UInt32)address Buffer: (Byte *)DataBuffer BufLength: (vm_size_t)Bytes;

// force a save
- (BOOL)saveDataForAddressForce:(UInt32)Address Buffer:(Byte *)DataBuffer BufLength:(vm_size_t)Bytes;

// load record from application addresses
- (BOOL)loadDataForObject: (id)object atAddress: (UInt32)address Buffer: (Byte *)DataBuffer BufLength: (vm_size_t)Bytes;
//- (BOOL)loadDataForAddress: (UInt32)address Buffer: (Byte *)DataBuffer BufLength: (vm_size_t)Bytes;

// raw reading, minimal error checking, actual return result
- (kern_return_t)readAddress: (UInt32)address Buffer: (Byte *)DataBuffer BufLength: (vm_size_t)Bytes;

- (int)readInt: (UInt32)address withSize:(size_t)size;
- (long long)readLongLong: (UInt32)address;
- (NSNumber*)readNumber: (UInt32)address withSize:(size_t)size;

// must be null terminated!
- (NSString*)readString: (UInt32)address;

@end