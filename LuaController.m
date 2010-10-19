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

@implementation LuaController

- (id) init{
    self = [super init];
    if (self != nil) {

		// fire up wax!
		wax_start();
		
		// get the lua state
		lua_State *L = wax_currentLuaState();
		
		// get our plugin path
		NSString *pluginPath = APPLICATION_SUPPORT_FOLDER;
		pluginPath = [NSString stringWithFormat:@"%@/plugins/", [pluginPath stringByExpandingTildeInPath]];
		
		NSLog(@"Executing plugins in path: %@", pluginPath);
		
		// file to load
		//NSString *pluginToLoad = [NSString stringWithFormat:@"%@init.lua", pluginPath];
		
		// load all of our scripts!
		if (luaL_dofile(L, "/Volumes/HD/Users/Josh/Library/Application Support/PocketGnome/plugins/init.lua") != 0) {
			fprintf(stderr,"Fatal error opening wax scripts: %s\n", lua_tostring(L,-1));
		}
	}
	
	return self;
}

@end
