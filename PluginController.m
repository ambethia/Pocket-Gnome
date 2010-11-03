//
//  PluginController.m
//  Pocket Gnome
//
//  Created by Josh on 10/19/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//
#import "PluginController.h"
#import "Plugin.h"
#import "Controller.h"
#import "NSAttributedString+Hyperlink.h"
#import "LuaController.h"

@interface PluginController (Internal)
- (NSString*)pluginPath;
- (void)getPlugins;
- (void)loadAllPlugins;
- (void)unloadPlugin:(Plugin*)plugin;
- (void)installCore;
- (BOOL)installPluginAtPath:(NSString*)path;
- (void)associateEvents;
@end

@implementation PluginController

- (id)init {
    self = [super init];
	if ( self != nil ){
		
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(applicationDidFinishLaunching:) name: ApplicationLoadedNotification object: nil];
		
		_plugins = [[NSMutableArray array] retain];
		_eventListeners = [[[NSMutableDictionary alloc] init] retain];
		_eventSelectors = [[[NSMutableDictionary alloc] init] retain];
		
		// associate all of our events! Go Go!
		[self associateEvents];
		
		// TO DO: REMOVE THIS ON RELEASE! DUH!
		NSFileManager *fileManager = [NSFileManager defaultManager]; 
		NSString *pluginPath = [self pluginPath];
		NSError *error;
		
		// remove folder if it exists already
		if ( [fileManager fileExistsAtPath: pluginPath] ){
			if ( ![fileManager removeItemAtPath:pluginPath error:&error] && error ){
				PGLog(@"[Plugins] Error removing plugin folder:", [error description]);
			}
		}
		
		[NSBundle loadNibNamed: @"Plugins" owner: self];
	}
	
	return self;	
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	
	// create a clickable link
	[pluginLinkTextField setAllowsEditingTextAttributes: YES];
	[pluginLinkTextField setSelectable: YES];
	[pluginLinkTextField setAlignment:NSRightTextAlignment];
	NSURL* url = [NSURL URLWithString:@"http://pg.savorydeviate.com/plugins/"];
	NSMutableAttributedString* string = [[NSMutableAttributedString alloc] init];
	[string appendAttributedString: [NSAttributedString hyperlinkFromString:@"Find Plugins Here!" withURL:url]];
	[pluginLinkTextField setAttributedStringValue: string];
	
	// do we need to install/update the core?
	[self installCore];

	// get all plugins!
	[self getPlugins];

	// fire plugins loaded event!
	[self performEvent:E_PLUGIN_LOADED withObject:nil];
}

- (void)dealloc {
	[_plugins release];
	[super dealloc];
}

@synthesize view;
@synthesize minSectionSize;
@synthesize maxSectionSize;
@synthesize plugins = _plugins;

- (NSString*)sectionTitle {
    return @"Plugins";
}

#pragma mark Table Delegate

- (int)numberOfRowsInTableView:(NSTableView *)aTableView {
	return [_plugins count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
	
	if ( rowIndex == -1 ) return nil;
	if ( rowIndex >= [_plugins count] ) return nil;
	
	Plugin *plugin = [_plugins objectAtIndex:rowIndex];
	
	if ( [[aTableColumn identifier] isEqualToString: @"Plugin Name"] ){
		return [plugin name];
	}
	else if ( [[aTableColumn identifier] isEqualToString: @"Description"] ){
		return [plugin desc];
	}
	else if ( [[aTableColumn identifier] isEqualToString: @"Version"] ){
		return [plugin version];
	}
	else if ( [[aTableColumn identifier] isEqualToString: @"Author"] ){
		return [plugin author];
	}
	else if ( [[aTableColumn identifier] isEqualToString: @"Release Date"] ){
		return [plugin releasedate];
	}
	else if ( [[aTableColumn identifier] isEqualToString: @"Enabled"] ){
		return [NSNumber numberWithInt:[plugin enabled]];
	}
	
    return nil;
}

- (IBAction)setEnabled: (id)sender{
	
	Plugin *plugin = [_plugins objectAtIndex:[sender clickedRow]];

	// plugin is enabled, disable it please!
	if ( [plugin enabled] ){
		[plugin setEnabled:NSOffState];
		[self unloadPlugin:plugin];
	}
	// enable it
	else {
		[plugin setEnabled:NSOnState];
		//[self loadPlugin: plugin];
	}
}

#pragma mark UI

- (IBAction)addPlugin: (id)sender{
	
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	
	[openPanel setCanChooseDirectories: YES];
	[openPanel setCanCreateDirectories: NO];
	[openPanel setPrompt: @"Select Plugin Directory"];
	[openPanel setCanChooseFiles: NO];
    [openPanel setAllowsMultipleSelection: YES];
	[openPanel setDirectory:@"~/Desktop"];
	
	int ret = [openPanel runModalForTypes: nil];
    
	if ( ret == NSFileHandlingPanelOKButton ) {
		
		NSString *tmp = nil;
		NSError *error = nil;
		NSFileManager *fileManager = [NSFileManager defaultManager]; 
		
		NSString *pluginPath = [self pluginPath];
		NSString *errorString = nil;
		
		// create plugin directory if it doesn't exist!
		if ( ![fileManager fileExistsAtPath: pluginPath] ){
			[fileManager createDirectoryAtPath: pluginPath attributes: nil];
		}
		
		// loop through all selected plugins
        for ( NSString *pluginPathInPanel in [openPanel filenames] ) {
			
			// make sure they have a .plist file!
			tmp = [NSString stringWithFormat:@"%@/Info.plist", pluginPathInPanel];
			if ( ![fileManager fileExistsAtPath: tmp] ){
				NSBeep();
				errorString = [NSString stringWithFormat:@"Plugin is missing the Info.plist file at %@", pluginPathInPanel];
				NSRunAlertPanel(@"Plugin Invalid", errorString, @"Okay", NULL, NULL);
				PGLog(@"[Plugins] Not a valid plugin at %@", pluginPathInPanel);
				continue;
			}
			
			// Check for at least one .lua file, otherwise this could be strange ;)
			NSArray *contents = [fileManager contentsOfDirectoryAtPath:pluginPathInPanel error:&error];
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
					NSBeep();
					NSRunAlertPanel(@"Error when reading directory contents", @"No .lua files found! Invalid plugin.", @"Okay", NULL, NULL);
					PGLog(@"[Plugins] No .lua files found!");
					continue;
				}				
			}
			else{
				NSBeep();
				errorString = [NSString stringWithFormat:@"No .lua files found! Invalid plugin. %@", pluginPathInPanel];
				NSRunAlertPanel(@"Error when reading directory contents", errorString, @"Okay", NULL, NULL);
				PGLog(@"[Plugins] %@", errorString);
				continue;
			}
			
			
			// get the name of the last folder
			NSArray *allFolders = [pluginPathInPanel componentsSeparatedByString:@"/"];
			NSString *newPath = [NSString stringWithFormat:@"%@/%@", pluginPath, [allFolders lastObject]];

			// check if it exists
			if ( [fileManager fileExistsAtPath: newPath] ){
				
				int res = NSRunAlertPanel(@"Plugin Exists", @"Plugin already exists, would you like to overwrite it?", @"No", @"Yes", NULL);
				// don't overwrite it
				if ( res == NSAlertDefaultReturn ){
					continue;
				}			
			}
			
			// if we get to here then we can actually install it!
			BOOL success = [self installPluginAtPath:pluginPathInPanel];
			
			if ( !success ){
				errorString = [NSString stringWithFormat:@"Error: %@ while copying '%@' to '%@'", [error description], pluginPathInPanel, newPath];
				NSRunAlertPanel(@"Install Error", errorString, @"Okay", NULL, NULL);
			}
        }
	}
}

- (IBAction)deletePlugin: (id)sender{
	
	int selectedRow = [pluginTable selectedRow];
	
	Plugin *plugin = [_plugins objectAtIndex:selectedRow];

	int res = NSRunAlertPanel(@"Delete Confirmation", [NSString stringWithFormat:@"Are you sure you want to delete '%@'?", [plugin name]], @"Yes", @"No", NULL);
	
	// update it!
	if ( res == NSAlertDefaultReturn ){
		PGLog(@"[Plugins] Deleting %@", plugin);
		
		[self willChangeValueForKey: @"totalPlugins"];
		
		// delete it!
		NSError *error = nil;
		NSFileManager *fileManager = [NSFileManager defaultManager]; 
		
		// remove folder if it exists already
		if ( ![fileManager removeItemAtPath:[plugin path] error:&error] && error ){
			NSRunAlertPanel(@"Delete Error", [NSString stringWithFormat:@"Unable to delete plugin '%@', Error: %@", [plugin name], [error description]], @"Okay", NULL, NULL);
			PGLog(@"[Plugins] Unable to delete plugin %@, error: %@", [plugin path], [error description]);
			return;
		}

		// unload the plugin
		[self unloadPlugin:plugin];
		
		// remove it from our list
		[_plugins removeObjectAtIndex:selectedRow];
		
		[self didChangeValueForKey: @"totalPlugins"];
		
		// reload our table since we just deleted one!
		[pluginTable reloadData];
	}
}

- (IBAction)configurePlugin: (id)sender {
	int selectedRow = [pluginTable selectedRow];
	
	Plugin *plugin = [_plugins objectAtIndex:selectedRow];
	
	if([plugin respondsToSelector:@selector(pluginConfig)]) {
		[plugin performSelector:@selector(pluginConfig)];
	}
}

- (NSNumber*)totalPlugins{
	return [NSNumber numberWithInt:[_plugins count]];
}

#pragma mark Helpers

- (void)loadPluginAtPath:(NSString *)path {

	Plugin *plugin = [luaController loadPluginAtPath:path];
	
	if(plugin != nil) {
		[_plugins addObject:plugin];
		
		SEL selector = nil;
		NSMutableArray *listeners = nil;
		NSString *eventSelector = nil;
		// as we're loading this plugin, we want to search for some selectors
		// loop through all known selectors
		PGLog(@"[Plugins] Finding selectors for %@", [plugin name]);
		for ( NSNumber *key in _eventSelectors ) {
			eventSelector = [_eventSelectors objectForKey:key];
			selector = NSSelectorFromString(eventSelector);
			
			NSLog(@" searching for %@", eventSelector);
			
			// does the plugin respond to this exact selector?
			if ( [plugin respondsToSelector:selector] ) {
				listeners = [_eventListeners valueForKey:eventSelector];
				if(listeners == nil) {
					listeners = [[NSMutableArray alloc] initWithCapacity:1];
					[_eventListeners setObject:listeners forKey:eventSelector];
				}
				[listeners addObject:plugin];
				NSLog(@"  found");
			}
			
			// search for the selector w/no arguments
			else if( [eventSelector hasSuffix:@":"] ) {
				eventSelector = [eventSelector substringToIndex:[eventSelector length]-1];
				NSLog(@" []searching for %@", [eventSelector substringToIndex:[eventSelector length]-1]);
				selector = NSSelectorFromString(eventSelector);
				if ( [plugin respondsToSelector:selector] ) {
					listeners = [_eventListeners valueForKey:eventSelector];
					if ( listeners == nil ) {
						listeners = [[NSMutableArray alloc] initWithCapacity:1];
						[_eventListeners setObject:listeners forKey:eventSelector];
					}
					[listeners addObject:plugin];
					NSLog(@"  found");
				}
			}
		}
	}
}

- (BOOL)doSelector:(SEL)selector onObject:(id)object withObject:(id)obj{
	
	id result = nil;
	
	if ( obj != nil ){
		result = [object performSelector:selector withObject:obj];
	}
	else {
		result = [object performSelector:selector];
	}
	
	// then we have a return value! w00t!
	if ( [[result className] isEqualToString:@"NSConcreteValue"] ){
		// lame but it works
		int buffer[30] = {0};
		[result getValue:buffer];
		return (BOOL)buffer[0];
	}
	
	return YES;	
}

- (BOOL)performEvent:(PG_EVENT_TYPE)eventType withObject:(id)obj {
	
	PGLog(@"[Plugins] Firing event %d with object %@", eventType, obj);
	
	// find our selector
	NSString *eventSelector = [_eventSelectors objectForKey:[NSNumber numberWithInt:eventType]];
	bool param = [eventSelector hasSuffix:@":"];
	NSArray *eventListeners = [_eventListeners objectForKey:eventSelector];
	SEL selector = nil;
	
	// we have some listeners!
	if ( eventListeners != nil ) {
		selector = NSSelectorFromString(eventSelector);
		
		// do we have a parameter?
		if ( param ) {
			// call individually so we can get any return values!
			for ( id object in eventListeners ){
				if ( ![self doSelector:selector onObject:object withObject:obj] ){
					PGLog(@"[Plugins] Event %d cancelled by plugin %@ with object %@", eventType, object, obj);
					return NO;
				}
			}
		}
		// no parameter :(
		else {
			// call individually so we can get any return values!
			for ( id object in eventListeners ){
				if ( ![self doSelector:selector onObject:object withObject:nil] ){
					PGLog(@"[Plugins] Event %d cancelled by plugin %@ with object %@", eventType, object, obj);
					return NO;
				}
			}
		}
	}
	// we have a parameter, but we couldn't find a selector - lets send w/o an arg
	else if ( param ) {
		eventSelector = [eventSelector substringToIndex:[eventSelector length]-1];
		eventListeners = [_eventListeners objectForKey:eventSelector];
		if ( eventListeners != nil ) {
			// call individually so we can get any return values!
			for ( id object in eventListeners ){
				if ( ![self doSelector:selector onObject:object withObject:nil] ){
					PGLog(@"[Plugins] Event %d cancelled by plugin %@ with object %@", eventType, object, obj);
					return NO;
				}
			}
		}
	}
	return YES;
}

// this just populates our _plugins array, it does NOT load anything into lua
- (void)getPlugins{
	
	// lets grab a list of the plugins from our directory!
	NSString *pluginPath = [self pluginPath];
	NSError *error = nil;
	NSFileManager *fileManager = [NSFileManager defaultManager]; 
	NSArray *plugins = [fileManager contentsOfDirectoryAtPath:pluginPath error:&error];
	if ( error == nil ){
		
		// grab all of our plugins!
		for ( NSString *folder in plugins ){

			[self loadPluginAtPath:[NSString stringWithFormat:@"%@/%@", pluginPath, folder]];
		}
	}
	else{
		PGLog(@"[Plugins] Error, unable to load plugins: %@", [error description]);
	}
}

// this will install the Core PG files if we need to!
// TO DO: This WILL reinstall if someone manually deletes them from app support, should we allow users to delete?
- (void)installCore{
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSError *error = nil;
	NSString *pluginsInResources = [NSString stringWithFormat:@"%@/plugins/", [[NSBundle mainBundle] resourcePath]];
	NSString *pluginsPath = [self pluginPath];
	
	// create plugin directory if it doesn't exist!
	if ( ![fileManager fileExistsAtPath: pluginsPath] ){
		[fileManager createDirectoryAtPath: pluginsPath attributes: nil];
	}
	
	// get a list of plugins that are available + what came with PG
	NSArray *existingPlugins = [fileManager contentsOfDirectoryAtPath:pluginsPath error:&error];
	NSArray *resourcePlugins = [fileManager contentsOfDirectoryAtPath:pluginsInResources error:&error];
	
	// do we need to install for the first time?
	if ( existingPlugins && [existingPlugins count] == 0 && resourcePlugins && [resourcePlugins count] > 0 ){
		PGLog(@"[Plugins] Core isn't installed, installing!");
		
		// loop through all core plugins to install
		for ( NSString *resourcePlugin in resourcePlugins ){
			[self installPluginAtPath:[NSString stringWithFormat:@"%@%@", pluginsInResources, resourcePlugin]];
		}
		
		return;
	}

	// check for updates
	if ( resourcePlugins && [resourcePlugins count] > 0 ){
	
		// loop through to check for a match!
		for ( NSString *resourcePlugin in resourcePlugins ){
			
			for ( NSString *existingPlugin in existingPlugins ){
				
				// match found, check versions
				if ( [resourcePlugin isEqualToString:existingPlugin] ){
					
					// get full paths
					NSString *resourceInfoPath = [NSString stringWithFormat:@"%@%@/Info.plist", pluginsInResources, resourcePlugin];
					NSString *existingInfoPath = [NSString stringWithFormat:@"%@/%@/Info.plist", pluginsPath, resourcePlugin];
							
					// get data from the plist files
					NSDictionary *resourceInfo = [NSDictionary dictionaryWithContentsOfFile: resourceInfoPath];
					NSDictionary *existingInfo = [NSDictionary dictionaryWithContentsOfFile: existingInfoPath];
					
					// get versions
					NSString *newVersion = [resourceInfo objectForKey:@"Version"];
					NSString *oldVersion = [existingInfo objectForKey:@"Version"];
					
					// are the versions different?
					if ( ![newVersion isEqualToString:oldVersion] ){
						
						NSString *updateString = [NSString stringWithFormat:@"There is an update available for plugin '%@' version %@. Would you like to update to version %@?", resourcePlugin, oldVersion, newVersion];
						
						int res = NSRunAlertPanel(@"Plugin Update", updateString, @"Yes", @"No", NULL);
						
						// update it!
						if ( res == NSAlertDefaultReturn ){
							PGLog(@"[Plugins] Updating plugin %@", existingPlugin);
							[self installPluginAtPath:[NSString stringWithFormat:@"%@%@", pluginsInResources, resourcePlugin]];
						}
					}
				}
			}
		}
	}
}

- (BOOL)installPluginAtPath:(NSString*)path{
	
	PGLog(@"[Plugins] Installing plugin at path %@", path);
	
	NSError *error = nil;
	NSFileManager *fileManager = [NSFileManager defaultManager]; 
	
	// get the plugin path
	NSString *pluginPath = [self pluginPath];
	
	// get just the plugin name
	NSArray *allFolders = [path componentsSeparatedByString:@"/"];
	NSString *newPath = [NSString stringWithFormat:@"%@/%@", pluginPath, [allFolders lastObject]];
	
	// remove folder if it exists already
	if ( [fileManager fileExistsAtPath: newPath] ){
		if ( ![fileManager removeItemAtPath:newPath error:&error] && error ){
			PGLog(@"[Plugins] Unable to install plugin %@, error: %@", newPath, [error description]);
			return NO;
		}
	}
				
	// install it!
	BOOL success = [fileManager copyItemAtPath:path toPath:newPath error:&error];
	
	if ( !success || error ){
		PGLog(@"[Plugins] Error installing plugin to '%@'", newPath);
		return NO;
	}
	else{
		PGLog(@"[Plugins] Successfully installed plugin to '%@'", newPath);
		return YES;
	}
	
	return NO;
}

- (void)unloadPlugin:(Plugin*)plugin{
	
	PGLog(@"[Plugins] Unloading %@", plugin);
}
	

- (NSString*)pluginPath{
	NSString *pluginPath = PLUGIN_FOLDER;
	pluginPath = [pluginPath stringByExpandingTildeInPath];
	return [[pluginPath retain] autorelease];
}

#pragma mark Initializers

// this will just link our enums to actual selectors!
- (void)associateEvents{

	// kind of sucks, but a good way to make an association ;)
	[_eventSelectors setObject:@"ePluginLoaded"				forKey:[NSNumber numberWithInt:E_PLUGIN_LOADED]];
	[_eventSelectors setObject:@"ePluginLoadConfig"			forKey:[NSNumber numberWithInt:E_PLUGIN_CONFIG]];
	[_eventSelectors setObject:@"ePlayerDied"				forKey:[NSNumber numberWithInt:E_PLAYER_DIED]];
	[_eventSelectors setObject:@"ePlayerFound:"				forKey:[NSNumber numberWithInt:E_PLAYER_FOUND]];
	[_eventSelectors setObject:@"eBotStart"					forKey:[NSNumber numberWithInt:E_BOT_START]];
	[_eventSelectors setObject:@"eBotStop"					forKey:[NSNumber numberWithInt:E_BOT_STOP]];
	

}

@end
