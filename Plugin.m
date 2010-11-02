//
//  Plugin.m
//  Pocket Gnome
//
//  Created by Josh on 10/19/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "Plugin.h"

@interface Plugin (Internal)
- (BOOL)isValidPluginAtPath:(NSString*)path;
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
		L = nil;
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

@synthesize L;


- (NSString*)description{
    return [NSString stringWithFormat: @"<Plugin: %@, Version: %@>", [self name], [self version]];
}

- (BOOL)isValidPluginAtPath:(NSString*)path{
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	// make sure they have a .plist file!
	NSString *infoPath = [NSString stringWithFormat:@"%@/Info.plist", path];
	if ( ![fileManager fileExistsAtPath: infoPath] ){
		PGLog(@"[Plugin] Not a valid plugin at %@, missing Info.plist", path);
		return NO;
	}
	
	// check for at least one .lua file
	NSError *error = nil; 
	NSArray *contents = [fileManager contentsOfDirectoryAtPath:path error:&error];
	if ( contents && [contents count] > 0 ){
		BOOL foundLua = NO;
		for ( NSString *file in contents ){
			NSArray *split = [file componentsSeparatedByString:@"."];
			if ( [[split lastObject] isEqualToString:@"lua"] ){
				foundLua = YES;
				break;
			}				
		}
		
		// no lua files found :(
		if ( !foundLua ){
			PGLog(@"[Plugin] Not a valid plugin at %@, no .lua files found", path);
			return NO;
		}				
	}
	//luacontroller needs to do all of this anyway
	
	return YES;
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
