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


@implementation PluginController

- (id)init {
    self = [super init];
	if ( self != nil ){
		
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(applicationDidFinishLaunching:) name: ApplicationLoadedNotification object: nil];
		
		_plugins = [[NSMutableArray array] retain];
		
		// lets grab a list of the plugins from our directory!
		// TO DO: Error checking, I'm making the assumption that no one will MANUALLY f w/this directory
		NSString *pluginPath = PLUGIN_FOLDER;
		pluginPath = [pluginPath stringByExpandingTildeInPath];
		NSError *error = nil;
		NSFileManager *fileManager = [NSFileManager defaultManager]; 
		NSArray *plugins = [fileManager contentsOfDirectoryAtPath:pluginPath error:&error];
		if ( error == nil ){
			
			// grab all of our plugins!
			for ( NSString *folder in plugins ){
				
				Plugin *plugin = [Plugin pluginWithPath:[NSString stringWithFormat:@"%@/%@", pluginPath, folder]];
				[_plugins addObject:plugin];
			}
		}
		else{
			PGLog(@"[Plugins] Error, unable to load plugins: %@", [error description]);
		}
		
		[NSBundle loadNibNamed: @"Plugins" owner: self];
	}
	
	return self;	
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	
	// load available plugins
	for ( Plugin *plugin in _plugins ){
		PGLog(@"[Plugins] Loading %@", plugin);
		[plugin load];		
	}
}

- (void)dealloc {
	[_plugins release];
	[super dealloc];
}

@synthesize view;
@synthesize minSectionSize;
@synthesize maxSectionSize;

- (NSString*)sectionTitle {
    return @"Plugins";
}

#pragma mark Table Delegate

- (int)numberOfRowsInTableView:(NSTableView *)aTableView {
	return 0;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
    
	/*if ( rowIndex == -1 ) return nil;
	
	if ( aTableView == waypointTable ){
		
		Waypoint *wp = [[self currentRoute] waypointAtIndex: rowIndex];
		if ( [[aTableColumn identifier] isEqualToString: @"Step"] ){
			return [NSNumber numberWithInt: rowIndex+1];
		}
		
		if( [[aTableColumn identifier] isEqualToString: @"Type"] ){
			
			int type = 0;
			
			// now we have a list of actions, choose the first one
			if ( [wp.actions count] > 0 ){
				
				Action *action = [wp.actions objectAtIndex:0];
				
				if ( action.type > ActionType_None && action.type < ActionType_Max ){
					type = action.type;
				}
			}
			
			return [NSNumber numberWithInt: type];
		}
		
		
		if ( [[aTableColumn identifier] isEqualToString: @"Coordinates"] ){
			return [NSString stringWithFormat: @"X: %.1f; Y: %.1f; Z: %.1f", [[wp position] xPosition], [[wp position] yPosition], [[wp position] zPosition]];
		}
		
		if ( [[aTableColumn identifier] isEqualToString: @"Distance"] ){
			Waypoint *prevWP = (rowIndex == 0) ? ([[self currentRoute] waypointAtIndex: [[self currentRoute] waypointCount] - 1]) : ([[self currentRoute] waypointAtIndex: rowIndex-1]);
			float distance = [[wp position] distanceToPosition: [prevWP position]];
			return [NSString stringWithFormat: @"%.2f yards", distance];
		}
		
		if ( [[aTableColumn identifier] isEqualToString: @"Description"] ){
			return wp.title;
		}
	}*/
    
    return nil;
}

#pragma mark UI

- (IBAction) addPlugin: (id)sender{
	
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
		
		NSString *pluginPath = PLUGIN_FOLDER, *errorString = nil;
		pluginPath = [pluginPath stringByExpandingTildeInPath];
		
		// create plugin directory if it doesn't exist!
		if ( ![fileManager fileExistsAtPath: pluginPath] ){
			[fileManager createDirectoryAtPath: pluginPath attributes: nil];
		}
		
		// loop through all selected plugins
        for ( NSString *routePath in [openPanel filenames] ) {
			
			// make sure they have a .plist file!
			tmp = [NSString stringWithFormat:@"%@/Info.plist", routePath];
			if ( ![fileManager fileExistsAtPath: tmp] ){
				NSBeep();
				errorString = [NSString stringWithFormat:@"Plugin is missing the Info.plist file at %@", routePath];
				NSRunAlertPanel(@"Plugin Invalid", errorString, @"Okay", NULL, NULL);
				PGLog(@"[Plugins] Not a valid plugin at %@", routePath);
				continue;
			}
			
			// Check for at least one .lua file, otherwise this could be strange ;)
			NSArray *contents = [fileManager contentsOfDirectoryAtPath:routePath error:&error];
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
				errorString = [NSString stringWithFormat:@"No .lua files found! Invalid plugin. %@", routePath];
				NSRunAlertPanel(@"Error when reading directory contents", errorString, @"Okay", NULL, NULL);
				PGLog(@"[Plugins] %@", errorString);
				continue;
			}
			
			
			// get the name of the last folder
			NSArray *allFolders = [routePath componentsSeparatedByString:@"/"];
			NSString *newPath = [NSString stringWithFormat:@"%@/%@", pluginPath, [allFolders lastObject]];
			
			// check if it exists
			if ( [fileManager fileExistsAtPath: newPath] ){
				
				int res = NSRunAlertPanel(@"Plugin Exists", @"Plugin already exists, would you like to overwrite it?", @"No", @"Yes", NULL);
				// don't overwrite it
				if ( res == NSAlertDefaultReturn ){
					continue;
				}
				// overwrite it
				else{
					NSLog(@"[Plugins] Removing %@", newPath);
					NSError *error;
					if ( ![fileManager removeItemAtPath:newPath error:&error] && error ){
						NSRunAlertPanel(@"Error removing existing plugin", [error description], @"Okay", NULL, NULL);
						NSLog(@"[Plugins] Error removing plugin at path '%@' Info: %@", newPath, [error description]);
						continue;
					}
				}				
			}
			
			// if we get here then we can install it! yay!
			BOOL success = [fileManager copyItemAtPath:routePath toPath:newPath error:&error];
	
			if ( !success ){
				errorString = [NSString stringWithFormat:@"Error: %@ while copying '%@' to '%@'", [error description], routePath, pluginPath];
				NSRunAlertPanel(@"Install Error", errorString, @"Okay", NULL, NULL);
				NSLog(@"[Plugins] Unable to install plugin '%@' due to %@", routePath, [error description]);
			}
			else{
				NSLog(@"[Plugins] Successfully installed plugin to '%@'", newPath);
			}
        }
	}
}

- (IBAction)deletePlugin: (id)sender{
	
}

@end
