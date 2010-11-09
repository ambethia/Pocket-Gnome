//
//  PluginController.h
//  Pocket Gnome
//
//  Created by Josh on 10/19/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//
#import <Cocoa/Cocoa.h>

typedef enum {
	E_PLUGIN_LOADED,
	E_PLUGIN_CONFIG,
	E_PLAYER_DIED,
	E_PLAYER_FOUND,
	E_BOT_START,
	E_BOT_STOP,
	
	E_MAX,
} PG_EVENT_TYPE;

@class LuaController;

@interface PluginController : NSObject {

	IBOutlet LuaController *luaController;
	
	IBOutlet NSTableView *pluginTable;
	IBOutlet NSTextField *pluginLinkTextField;
	
	NSMutableArray *_plugins;
	
	IBOutlet NSView *view;
	NSSize minSectionSize, maxSectionSize;
	
	NSMutableDictionary *_eventSelectors;
	NSMutableDictionary *_eventListeners;
}

@property (readonly) NSArray *plugins;
@property (readonly) NSNumber *totalPlugins;
@property (readonly) NSView *view;
@property (readonly) NSString *sectionTitle;
@property NSSize minSectionSize;
@property NSSize maxSectionSize;

- (BOOL)performEvent:(PG_EVENT_TYPE)eventType withObject:(id)obj;
- (void)loadPluginAtPath:(NSString *)path;
- (IBAction)addPlugin: (id)sender;
- (IBAction)deletePlugin: (id)sender;
- (IBAction)setEnabled: (id)sender;
- (IBAction)configurePlugin: (id)sender;

@end
