//
//  ProcedureController.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 1/4/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Behavior.h"
#import "Procedure.h"

@class FileController;

@interface ProcedureController : NSObject {
    IBOutlet id ruleEditor;
    IBOutlet id spellController;
    IBOutlet id itemController;
	IBOutlet FileController		*fileController;

    IBOutlet NSView *view;
    IBOutlet id procedureEventSegment;
    IBOutlet NSTableView *ruleTable;
    IBOutlet NSMenu *actionMenu;
    IBOutlet NSPanel *renamePanel;
	
	IBOutlet NSTextField *combatPriorityTextField;

    Behavior *_behavior;
    NSMutableArray *_behaviors;
    BOOL validSelection;
	NSString *_nameBeforeRename;
    
    NSSize minSectionSize, maxSectionSize;
}

@property BOOL validSelection;
@property (readonly) NSView *view;
@property (readonly) NSString *sectionTitle;
@property NSSize minSectionSize;
@property NSSize maxSectionSize;

- (NSArray*)behaviors;
- (Behavior*)currentBehavior;
- (void)setCurrentBehavior: (Behavior*)protocol;
- (Procedure*)currentProcedure;

- (IBAction)tableRowDoubleClicked: (id)sender;

// import/export
- (void)importBehaviorAtPath: (NSString*)path;
- (IBAction)importBehavior: (id)sender;
- (IBAction)exportBehavior: (id)sender;

// behavior actions
- (IBAction)createBehavior: (id)sender;
- (IBAction)loadBehavior: (id)sender;
- (IBAction)removeBehavior: (id)sender;
- (IBAction)renameBehavior: (id)sender;
- (IBAction)duplicateBehavior: (id)sender;
- (IBAction)closeRename: (id)sender;
- (IBAction)setBehaviorEvent: (id)sender;
- (IBAction)showInFinder: (id)sender;

// rule actions
- (IBAction)addRule: (id)sender;
- (IBAction)deleteRule: (id)sender;

@end
