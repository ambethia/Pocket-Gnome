//
//  Plugin.m
//  Pocket Gnome
//
//  Created by Josh on 10/19/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "Plugin.h"

@interface Plugin (Internal)
- (void)loadInfo;
@end


@implementation Plugin

- (id) init
{
    self = [super init];
    if (self != nil) {
        _path = nil;
		_info = nil;
		_enabled = NSOnState;
    }
    return self;
}

- (id)initWithPath: (NSString*)path {
    self = [self init];
    if (self != nil) {
        _path = [path retain];
		
		// no need for this since lua controller needs to validate before instantiating
		/*if ( ![self isValidPluginAtPath:path] ){
			[self release];
			return nil;
		}*/
		
		// if we get here then we are good! Yay!
		[self loadInfo];
		
    }
    return self;
}

+ (id)pluginWithPath: (NSString*)path {
	return [[[Plugin alloc] initWithPath: path] autorelease];
}

-(BOOL)loadNib:(NSString *)filename {
	NSNib *nib = [[NSNib alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", _path, filename, nil]]];
	return [nib instantiateNibWithOwner:self topLevelObjects:nil];
}

- (NSString*)description{
    return [NSString stringWithFormat: @"<Plugin: %@, Version: %@>", [self name], [self version]];
}

- (void)loadInfo{
	NSString *infoPath = [NSString stringWithFormat:@"%@/Info.plist", _path];
	_info = [[NSDictionary dictionaryWithContentsOfFile: infoPath] retain];
}

#pragma mark Descriptors

- (BOOL)enabled{
	return _enabled;
}

- (void)setEnabled:(BOOL)enabled{
	_enabled = enabled;
}

- (NSString*)name{
	if ( !_info )	return nil;
	return [_info objectForKey:@"Plugin Name"];
}

- (NSString*)desc{
	if ( !_info )	return nil;
	return [_info objectForKey:@"Description"];
}

- (NSString*)version{
	if ( !_info )	return nil;
	return [_info objectForKey:@"Version"];
}

- (NSString*)author{
	if ( !_info )	return nil;
	return [_info objectForKey:@"Author"];
}

- (NSString*)releasedate{
	if ( !_info )	return nil;
	return [_info objectForKey:@"Release Date"];
}

- (NSString*)path{
	return [[[_path copy] retain] autorelease];
}

@end
