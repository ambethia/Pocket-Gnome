//
//  Plugin.m
//  Pocket Gnome
//
//  Created by Josh on 10/19/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "Plugin.h"


@implementation Plugin

- (id) init
{
    self = [super init];
    if (self != nil) {
        _path = nil;
    }
    return self;
}

- (id)initWithPath: (NSString*)path {
    self = [self init];
    if (self != nil) {
        _path = [path retain];
    }
    return self;
}


+ (id)pluginWithPath: (NSString*)path {
	return [[[Plugin alloc] initWithPath: path] autorelease];
}

// load our plugin
- (void)load{
	
	// grab the info.plist
	
	PGLog(@"going! %@", _path);
}

- (BOOL)enabled{
	return YES;
}

- (void)setEnabled:(BOOL)enabled{
	
}

- (NSString*)description{
    return [NSString stringWithFormat: @"<Plugin: %@>", _path];
}

@end
