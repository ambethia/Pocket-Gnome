//
//  ObjectsController.h
//  Pocket Gnome
//
//  Created by Josh on 2/4/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Controller;
@class MemoryViewController;
@class NodeController;
@class PlayersController;
@class InventoryController;
@class MobController;
@class MovementController;
@class PlayerDataController;

enum Tabs{
	Tab_Players = 0,
	Tab_Mobs,
	Tab_Items,
	Tab_Nodes,	
};

// really just a helper class for our new Objects tab
@interface ObjectsController : NSObject {
	IBOutlet Controller				*controller;
	IBOutlet MemoryViewController	*memoryViewController;
	IBOutlet NodeController			*nodeController;
	IBOutlet PlayersController		*playersController;
	IBOutlet InventoryController	*itemController;
	IBOutlet MobController			*mobController;
	IBOutlet MovementController		*movementController;
	IBOutlet PlayerDataController	*playerController;
	
	IBOutlet NSPopUpButton *moveToNodePopUpButton, *moveToMobPopUpButton;
	
	IBOutlet NSTableView *itemTable, *playersTable, *nodeTable, *mobTable;
	
	IBOutlet NSTabView *tabView;
	
	IBOutlet NSView *view;
	
	NSTimer *_updateTimer;
	
	int _currentTab;		// currently selected tab
	
	NSSize _minSectionSize, _maxSectionSize;
	float _updateFrequency;
	
	NSString *_mobFilterString;
	NSString *_nodeFilterString;
}

@property (readonly) NSView *view;
@property (readonly) NSString *sectionTitle;
@property NSSize minSectionSize;
@property NSSize maxSectionSize;
@property float updateFrequency;

// tables
@property (readonly) NSTableView *itemTable;
@property (readonly) NSTableView *playersTable;
@property (readonly) NSTableView *nodeTable;
@property (readonly) NSTableView *mobTable;

- (BOOL)isTabVisible:(int)tab;

- (void)loadTabData;

- (NSString*)nameFilter;

// TO DO: this should change based on what tab we are viewing!
- (int)objectCount;

// TO DO: when we reload the table, STAY WITH SELECTED ROW!


- (IBAction)filter: (id)sender;
- (IBAction)refreshData: (id)sender;
- (IBAction)updateTracking: (id)sender;
- (IBAction)moveToStart: (id)sender;
- (IBAction)moveToStop: (id)sender;
- (IBAction)resetObjects: (id)sender;
- (IBAction)targetObject: (id)sender;
- (IBAction)faceObject: (id)sender;
- (IBAction)reloadNames: (id)sender;

@end
