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
#import "Controller.h"

#include "luaconf.h"
#include "sys/time.h"

@interface LuaController (Internal)
- (void)addPath:(NSString*)newPath;
static int L_RegisterEvent(lua_State *L);
@end

@implementation LuaController

static LuaController *sharedController = nil;

+ (LuaController*)sharedController{
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

		// lets figure out when the app is done launching!
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(applicationDidFinishLaunching:) name: ApplicationLoadedNotification object: nil];
		
		
		_currentExecutingPlugin = nil;
		
		// fire up wax!
		wax_start();
		
		// set up anything custom here!
		//RegisterEvent
		
		// get the lua state
		lua_State *L = wax_currentLuaState();
		
		lua_register(L, "RegisterEvent", L_RegisterEvent);
	}
	
	return self;
}

- (void)dealloc{

	// close lua state!
	lua_State *L = wax_currentLuaState();
	lua_close(L);
	
	[super dealloc];
}

@synthesize currentExecutingPlugin = _currentExecutingPlugin;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	_startTime = [controller currentTime];
}

- (BOOL)loadPlugin:(Plugin*)plugin{
	

	// get the plugins state, or create it!
	/*lua_State *L = [plugin L];
	if ( !L ){
		[plugin setL:];	
	}*/
	
	// get the lua state
	lua_State *L = wax_currentLuaState();
	
	if ( L ) {
		
		_currentExecutingPlugin = [plugin retain];
		
		NSString *fullPathToFile = [NSString stringWithFormat:@"%@/AppDelegate.lua", [plugin path]];
		
		NSLog(@"Go %@", plugin);
		if (luaL_dofile(L, [fullPathToFile UTF8String]) != 0) {
			PGLog(@"[LUA] Error loading lua file '%@' Error: %s", fullPathToFile, lua_tostring(L,-1));
			
			// disable plugin
			[plugin setEnabled:NO];
			[plugin release];
			_currentExecutingPlugin = nil;
			
			return NO;	// we could continue here, but I'd rather throw an error + not continue to try to load them
		}
		
		[plugin release];
		_currentExecutingPlugin = nil;
		
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
		[plugin release];
		return NO;
	}
	
	
	return YES;
}

// in it's current state tick will only fire for the LAST loaded file :(
- (void)tick{
	
	return;
	
	lua_State *L = wax_currentLuaState();
	
	/* the function name */
	lua_getfield(L, LUA_GLOBALSINDEX, "tick");
	//lua_getglobal(L, "tick");
	
	// get current time in milliseconds
	UInt32 elapsed = [controller currentTime] - _startTime;
	
	/* the first argument */
	lua_pushnumber(L, elapsed );
	
	/* call the function with 2
	 arguments, return 1 result */
	lua_call(L, 1, 0);
	
	[self performSelector:@selector(tick) withObject:nil afterDelay:0.1];
}

- (void)doSomething{
	
	// start our tick function!
	[self tick];
}

- (BOOL)unloadPlugin:(Plugin*)plugin{
	
	return NO;
}

// custom LUA functions

static int L_RegisterEvent(lua_State *L) {
	const char *eventString = luaL_checkstring(L, 1);
    NSLog(@"Registering event %s", eventString);
	
	const char *funcString = luaL_checkstring(L, 2);
	NSLog(@"to function %s", funcString);
	
	
	
	NSLog(@" just executed %@", [[LuaController sharedController] currentExecutingPlugin]);
	return 0;
}

@end
