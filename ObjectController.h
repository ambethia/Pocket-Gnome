//
//  ObjectController.h
//  Pocket Gnome
//
//  Created by Josh on 2/4/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Controller;
@class PlayerDataController;

@class MemoryAccess;
@class WoWObject;

// super class
@interface ObjectController : NSObject {
	
	IBOutlet Controller				*controller;
	IBOutlet PlayerDataController	*playerData;

	NSMutableArray *_objectList;
	NSMutableArray *_objectDataList;
	
	NSTimer *_updateTimer;
	
	IBOutlet NSView *view;
	NSSize minSectionSize, maxSectionSize;
	float _updateFrequency;
}

@property (readonly) NSView *view;
@property (readonly) NSString *sectionTitle;
@property NSSize minSectionSize;
@property NSSize maxSectionSize;
@property (readwrite) float updateFrequency;

- (void)addAddresses: (NSArray*)addresses;

- (void)resetAllObjects;

//
// to be implemented by sub classes
//

- (NSArray*)allObjects;

- (void)refreshData;

- (unsigned int)objectCount;

- (unsigned int)objectCountWithFilters;

- (id)objectWithAddress:(NSNumber*) address inMemory:(MemoryAccess*)memory;

- (void)objectAddedToList:(WoWObject*)obj;

- (NSString*)updateFrequencyKey;

- (void)tableDoubleClick: (id)sender;

- (WoWObject*)objectForRowIndex:(int)rowIndex;

// for tables

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
- (void)tableView: (NSTableView *)aTableView willDisplayCell: (id)aCell forTableColumn: (NSTableColumn *)aTableColumn row: (int)aRowIndex;
- (BOOL)tableView:(NSTableView *)aTableView shouldSelectTableColumn:(NSTableColumn *)aTableColumn;
- (void)sortUsingDescriptors:(NSArray*)sortDescriptors;

@end
