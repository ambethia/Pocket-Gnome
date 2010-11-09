//
//  IgnoreEntry.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 7/19/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import "IgnoreEntry.h"


@implementation IgnoreEntry

- (id) init
{
    self = [super init];
    if (self != nil) {
        self.ignoreType = [NSNumber numberWithInt: 0];
        self.ignoreValue = nil;
    }
    return self;
}

+ (id)entry {
    return [[[IgnoreEntry alloc] init] autorelease];
}

- (id)initWithCoder:(NSCoder *)decoder
{
	self = [super init];
	if(self) {
        self.ignoreType = [decoder decodeObjectForKey: @"IgnoreType"];
        self.ignoreValue = [decoder decodeObjectForKey: @"IgnoreValue"];
    }
	return self;
}

-(void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject: self.ignoreType forKey: @"IgnoreType"];
    [coder encodeObject: self.ignoreValue forKey: @"IgnoreValue"];
}

- (id)copyWithZone:(NSZone *)zone
{
    IgnoreEntry *copy = [[[self class] allocWithZone: zone] init];
    
    copy.ignoreType = self.ignoreType;
    copy.ignoreValue = self.ignoreValue;
    
    return copy;
}

- (void) dealloc
{
    self.ignoreType = nil;
    self.ignoreValue = nil;
    [super dealloc];
}


- (IgnoreType)type {
    return [self.ignoreType intValue];
}

@synthesize ignoreType = _ignoreType;
@synthesize ignoreValue = _ignoreValue;

@end
