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
 * $Id: FileObject.m 315 2010-04-23 04:12:45Z Tanaris4 $
 *
 */

#import "FileObject.h"

@interface FileObject ()
@property (readwrite, retain) NSString *UUID;

- (NSString*)generateUUID;
@end

@implementation FileObject

- (id) init{
    self = [super init];
    if (self != nil) {
		self.changed = NO;
		self.name = nil;
		
		// create a new UUID
		self.UUID = [self generateUUID];
		
		_observers = nil;
		
		// start observing! (so we can detect changes)
		[self performSelector:@selector(addObservers) withObject:nil afterDelay:1.0f];
	}
	
    return self;
}

- (void)dealloc{
	[self removeObserver:self forKeyPath:@"name"];
	for ( NSString *observer in _observers ){
		[self removeObserver:self forKeyPath:observer];
	}
	
	[_observers release]; _observers = nil;
	[super dealloc];
}

@synthesize changed = _changed;
@synthesize UUID = _UUID;
@synthesize	name = _name;

// called when loading from disk!
- (id)initWithCoder:(NSCoder *)decoder{
	if ( !self ){
		self = [self init];
	}
	
	if ( self ) {
		self.UUID = [decoder decodeObjectForKey: @"UUID"];
		self.name = [decoder decodeObjectForKey: @"Name"];
		
		// create a new UUID?
		if ( !self.UUID || [self.UUID length] == 0 ){
			self.UUID = [self generateUUID];
			self.changed = YES;
		}
	}

	return self;
}

// called when we're saving a file
- (void)encodeWithCoder:(NSCoder *)coder{
	[coder encodeObject: self.UUID forKey: @"UUID"];
	[coder encodeObject: self.name forKey: @"Name"];
}

- (id)copyWithZone:(NSZone *)zone{
	return nil;
}

- (NSString*)generateUUID{
	CFUUIDRef uuidObj = CFUUIDCreate(nil);
	NSString *uuid = (NSString*)CFUUIDCreateString(nil, uuidObj);
	CFRelease(uuidObj);
	
	return [uuid retain];
}

- (void)updateUUUID{
	self.UUID = [self generateUUID];
}

- (void)setChanged:(BOOL)val{
	//PGLog(@"[Changed] Set from %d to %d for %@", _changed, val, self);
	_changed = val;
}

// observations (to detect when an object changes)
- (void)addObservers{
	[self addObserver: self forKeyPath: @"name" options: NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context: nil];
	for ( NSString *observer in _observers ){
		[self addObserver: self forKeyPath: observer options: NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context: nil];
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
	PGLog(@"%@ changed! %@ %@", self, keyPath, change);
	self.changed = YES;
}

@end
