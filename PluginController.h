//
//  PluginController.h
//  Pocket Gnome
//
//  Created by Josh on 10/19/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//
#import <Cocoa/Cocoa.h>


@interface PluginController : NSObject {

	IBOutlet NSTableView *pluginTable;
	
	NSMutableArray *_plugins;
	
	IBOutlet NSView *view;
	NSSize minSectionSize, maxSectionSize;
}

@property (readonly) NSNumber *totalPlugins;
@property (readonly) NSView *view;
@property (readonly) NSString *sectionTitle;
@property NSSize minSectionSize;
@property NSSize maxSectionSize;

- (IBAction)addPlugin: (id)sender;
- (IBAction)deletePlugin: (id)sender;
- (IBAction)setEnabled: (id)sender;

@end
