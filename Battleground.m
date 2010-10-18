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
 * $Id: Battleground.m 325 2010-04-01 22:59:14Z ootoaoo $
 *
 */

#import "Battleground.h"
#import "RouteCollection.h"

@interface Battleground ()
@property (readwrite, retain) NSString *name;
@property (readwrite) int zone;
@end

@implementation Battleground

- (id) init{
    self = [super init];
    if ( self != nil ){
		
		_name = nil;
        _zone = -1;
		_queueID = -1;
		_enabled = YES;
		_routeCollection = nil;
		_changed = NO;
    }
    return self;
}

- (id)initWithName:(NSString*)name andZone:(int)zone andQueueID:(int)queueID{
	self = [self init];
    if (self != nil) {
		_name = [name retain];
		_zone = zone;
		_queueID = queueID;
		_enabled = YES;	
	}
	return self;
}


+ (id)battlegroundWithName: (NSString*)name andZone: (int)zone andQueueID: (int)queueID{
    return [[[Battleground alloc] initWithName: name andZone: zone andQueueID: queueID] autorelease];
}

- (id)initWithCoder:(NSCoder *)decoder{
	self = [self init];
	if ( self ) {
        _zone = [[decoder decodeObjectForKey: @"Zone"] intValue];
		_queueID = [[decoder decodeObjectForKey: @"QueueID"] intValue];
        _name = [[decoder decodeObjectForKey: @"Name"] retain];
		_enabled = [[decoder decodeObjectForKey: @"Enabled"] boolValue];
		self.routeCollection = [decoder decodeObjectForKey:@"RouteCollection"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder{
	[coder encodeObject: [NSNumber numberWithInt:self.zone] forKey: @"Zone"];
	[coder encodeObject: [NSNumber numberWithInt:self.queueID] forKey: @"QueueID"];
    [coder encodeObject: self.name forKey: @"Name"];
	[coder encodeObject: [NSNumber numberWithBool:self.enabled] forKey: @"Enabled"];
	[coder encodeObject: self.routeCollection forKey:@"RouteCollection"];
}

- (id)copyWithZone:(NSZone *)zone{
    Battleground *copy = [[[self class] allocWithZone: zone] initWithName: self.name andZone:self.zone andQueueID: self.queueID];
	
	_enabled = self.enabled;
	copy.routeCollection = self.routeCollection;
	
    return copy;
}

- (void) dealloc {
    self.name = nil;
    [super dealloc];
}

@synthesize zone = _zone;
@synthesize queueID = _queueID;
@synthesize name = _name;
@synthesize enabled = _enabled;
@synthesize routeCollection = _routeCollection;
@synthesize changed = _changed;

- (NSString*)description{
	return [NSString stringWithFormat: @"<%@; Addr: 0x%X>", self.name, self];
}

#pragma mark Accessors

- (void)setRouteCollection:(RouteCollection *)rc{
	
	// only set changed to yes if it's a different RC!
	if ( ![[rc UUID] isEqualToString:[_routeCollection UUID]] ){
		self.changed = YES;
	}
	
	_routeCollection = [rc retain];
}

- (void)setName:(NSString*)name{
	_name = [[name copy] retain];
	self.changed = YES;
}

- (void)setEnabled:(BOOL)enabled{
	_enabled = enabled;
	self.changed = YES;
}

- (void)setChanged:(BOOL)changed{
	_changed = changed;
	//PGLog(@"%@ set to %d", self, changed);
}

#pragma mark -

- (BOOL)isValid{
	if ( self.routeCollection ){
		return YES;
	}
	return NO;
}

@end
