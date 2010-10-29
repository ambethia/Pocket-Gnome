//
//  LuaController.m
//  Pocket Gnome
//
//  Created by Josh on 10/14/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "LuaController.h"
#import "lua.h"
#import "lauxlib.h"
#import "Plugin.h"

//#include "loadlib.h"
#include "luaconf.h"

@interface LuaController (Internal)
- (void)addPath:(NSString*)newPath;
@end

@implementation LuaController

- (id)init{
    self = [super init];
    if (self != nil) {

		// fire up wax!
		wax_start();
		
		_path = [[NSString stringWithFormat:@"%s", LUA_PATH_DEFAULT] retain];
	}
	
	return self;
}

- (void)dealloc{
	[_path release];
	[super dealloc];
}

- (BOOL)loadPlugin:(Plugin*)plugin{
	
	// get the lua state
	lua_State *L = wax_currentLuaState();
	
	if ( L ) {
		
		[self addPath:[plugin path]];

		NSString *fullPathToFile = [NSString stringWithFormat:@"%@/AppDelegate.lua", [plugin path]];
		
		if (luaL_dofile(L, [fullPathToFile UTF8String]) != 0) {
			PGLog(@"[LUA] Error loading lua file '%@' Error: %s", fullPathToFile, lua_tostring(L,-1));
			
			// disable plugin
			[plugin setEnabled:NO];
			
			return NO;	// we could continue here, but I'd rather throw an error + not continue to try to load them
		}
		
		/*
		NSFileManager *fileManager = [NSFileManager defaultManager];
	
		// get the contents of our plugin
		NSError *error = nil;
		NSArray *pluginFiles = [fileManager contentsOfDirectoryAtPath:[plugin path] error:&error];
		
		// loop through all files in the directory
		for ( NSString *file in pluginFiles ){

			NSArray *split = [file componentsSeparatedByString:@"."];
			if ( [[split lastObject] isEqualToString:@"lua"] ){
				
				NSString *fullPathToFile = [NSString stringWithFormat:@"%@/%@", [plugin path], file];
				
				if (luaL_dofile(L, [fullPathToFile UTF8String]) != 0) {
					PGLog(@"[LUA] Error loading lua file '%@' Error: %s", fullPathToFile, lua_tostring(L,-1));
					
					// disable plugin
					[plugin setEnabled:NO];
					
					return NO;	// we could continue here, but I'd rather throw an error + not continue to try to load them
				}
			}				
		}*/
	}
	else{
		PGLog(@"[LUA] Unable to load plugin '%@', lua state is invalid", plugin);
		return NO;
	}
	
	return YES;
}


- (BOOL)unloadPlugin:(Plugin*)plugin{
	
	return NO;
}

// from loadlib.c
#define AUXMARK        "\1"
#define setprogdir(L)        ((void)0)
- (void)addPath:(NSString*)newPath{
	
	NSLog(@"Old path: %@", _path);
	NSString *oldPath = [_path copy];
	[_path release];
	_path = [[NSString stringWithFormat:@"%@%@/?.lua;", oldPath, newPath] retain];
	
	lua_State *L = wax_currentLuaState();
	/*if ( L ){
		// we need to add this plugin as a path :/
		//setpath(L, "path", LUA_PATH, [_path UTF8String]);   set field `path'
		//void setpath (lua_State *L, const char *fieldname, const char *envname, const char *def) {   
		NSLog(@"%s", [_path UTF8String]);
		NSLog(@"1");
		const char *path = getenv(LUA_PATH);
		NSLog(@"2")
		if (path == NULL){  // no environment variable?
			NSLog(@"3");
			lua_pushstring(L, [_path UTF8String]);  // use default 
		}
		else {
			NSLog(@"4");
			// replace ";;" by ";AUXMARK;" and then AUXMARK by default path
			path = luaL_gsub(L, path, LUA_PATHSEP LUA_PATHSEP, LUA_PATHSEP AUXMARK LUA_PATHSEP);
			NSLog(@"5");
			luaL_gsub(L, path, AUXMARK, [_path UTF8String]);
			NSLog(@"6");
			lua_remove(L, -2);
			NSLog(@"7");
		}
		NSLog(@"8");
		setprogdir(L);
		NSLog(@"9");
		lua_setfield(L, -2, "path");
		NSLog(@"10");
	}*/
	
	NSLog(@"New path: %@", _path);
}

@end
