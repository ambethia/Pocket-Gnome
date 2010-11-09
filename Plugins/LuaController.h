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

}

+ (LuaController *)sharedController;

- (Plugin *)loadPluginAtPath:(NSString*)path;
- (BOOL)unloadPlugin:(Plugin*)plugin;

@end
