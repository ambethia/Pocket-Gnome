//
//  LuaController.h
//  Pocket Gnome
//
//  Created by Josh on 10/14/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "wax/wax.h"

@class Plugin;
@class Controller;

@interface LuaController : NSObject {
	
	IBOutlet Controller *controller;

	time_t _startTime;

	Plugin *_currentExecutingPlugin;
}

@property (readonly) Plugin *currentExecutingPlugin;

+ (LuaController *)sharedController;

- (BOOL)loadPlugin:(Plugin*)plugin;
- (BOOL)unloadPlugin:(Plugin*)plugin;

- (void)doSomething;

@end
