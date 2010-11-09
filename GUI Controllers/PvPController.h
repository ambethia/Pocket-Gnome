//
//  PvPController.h
//  Pocket Gnome
//
//  Created by Josh on 2/24/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class WaypointController;
@class FileController;

@class PvPBehavior;
@class RouteSet;

@interface PvPController : NSObject {
	
	IBOutlet WaypointController *waypointController;
	IBOutlet FileController		*fileController;
	
	IBOutlet NSPanel *renamePanel;
	IBOutlet NSView *view;
	
    NSSize minSectionSize, maxSectionSize;
	
	PvPBehavior *_currentBehavior;
	
	NSString *_nameBeforeRename;
	
	NSMutableArray *_behaviors;
}

@property (readonly) NSView *view;
@property (readonly) NSString *sectionTitle;
@property NSSize minSectionSize;
@property NSSize maxSectionSize;

@property (readonly) BOOL validBehavior;
@property (readwrite, retain) PvPBehavior *currentBehavior;
@property (readonly, retain) NSArray *behaviors;

- (void)setCurrentBehavior: (PvPBehavior*)behavior;
- (void)importBehaviorAtPath: (NSString*)path;
- (IBAction)createBehavior: (id)sender;
- (IBAction)renameBehavior: (id)sender;
- (IBAction)closeRename: (id)sender;
- (IBAction)duplicateBehavior: (id)sender;
- (IBAction)deleteBehavior: (id)sender;
- (IBAction)importBehavior: (id)sender;
- (IBAction)exportBehavior: (id)sender;

- (IBAction)showInFinder: (id)sender;
- (IBAction)saveAllObjects: (id)sender;

- (IBAction)test: (id)sender;

@end
