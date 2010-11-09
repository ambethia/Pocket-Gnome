//
//  WaypointController.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 12/16/07.
//  Copyright 2007 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Route;
@class RouteSet;
@class RouteCollection;
@class Waypoint;
@class Controller;
@class PlayerDataController;
@class BotController;
@class FileController;
@class MobController;
@class MovementController;
@class CombatController;

@class BetterTableView;
@class PTHotKey;
@class SRRecorderControl;

@class BetterSegmentedControl;
@class RouteVisualizationView;

@interface WaypointController : NSObject {

    IBOutlet Controller				*controller;
    IBOutlet PlayerDataController	*playerData;
    IBOutlet MobController			*mobController;
    IBOutlet BotController			*botController;
    IBOutlet MovementController		*movementController;
    IBOutlet CombatController		*combatController;
	//IBOutlet ProfileController		*profileController;
	IBOutlet FileController			*fileController;

    IBOutlet BetterTableView *waypointTable;
	IBOutlet NSOutlineView *routesTable;
    
    IBOutlet NSView *view;
    IBOutlet RouteVisualizationView *visualizeView;
    IBOutlet NSPanel *visualizePanel;
    IBOutlet NSMenu *actionMenu;
    IBOutlet NSMenu *testingMenu;

    // waypoint action editor
    IBOutlet NSPanel *wpActionPanel;
    IBOutlet NSTabView *wpActionTabs;
    IBOutlet NSTextField *wpActionDelayText;
    IBOutlet BetterSegmentedControl *wpActionTypeSegments;
    IBOutlet NSPopUpButton *wpActionIDPopUp;
    Waypoint *_editWaypoint;
	
    // waypoint recording
    IBOutlet NSButton *automatorStartStopButton;
    IBOutlet NSPanel *automatorPanel;
    IBOutlet NSTextField *automatorIntervalValue;
    IBOutlet NSProgressIndicator *automatorSpinner;
    IBOutlet RouteVisualizationView *automatorVizualizer;
    
    IBOutlet SRRecorderControl *shortcutRecorder;
	IBOutlet SRRecorderControl *automatorRecorder;
    
    IBOutlet id routeTypeSegment;
    RouteSet *_currentRouteSet;
	Route *_currentRoute;
    PTHotKey *addWaypointGlobalHotkey;
	PTHotKey *automatorGlobalHotkey;
    BOOL validSelection, validWaypointCount;
	BOOL isAutomatorRunning, disableGrowl;
    NSSize minSectionSize, maxSectionSize;
	
	IBOutlet NSPanel *descriptionPanel;
	NSString *_descriptionMultiRows;
	NSIndexSet *_selectedRows;
	
	NSString *_nameBeforeRename;
	
	IBOutlet NSButton		*scrollWithRoute;
	IBOutlet NSTextField	*waypointSectionTitle;
	
	// temp for route collections
	NSMutableArray *_routeCollectionList;
	RouteCollection *_currentRouteCollection;
	BOOL _validRouteSelection;
	IBOutlet NSButton *startingRouteButton;
	IBOutlet NSTabView *waypointTabView;
	
	BOOL _validRouteSetSelected;
	BOOL _validRouteCollectionSelected;
	
	// for teh n00bs
	BOOL _firstTimeEverOnTheNewRouteCollections;
	IBOutlet NSPanel *helpPanel;
}

- (void)saveRoutes;

@property (readonly) NSView *view;
@property (readonly) NSString *sectionTitle;
@property NSSize minSectionSize;
@property NSSize maxSectionSize;

@property BOOL validSelection;
@property BOOL validWaypointCount;
@property BOOL isAutomatorRunning;
@property BOOL disableGrowl;
@property (readonly) Route *currentRoute;
@property (readwrite, retain) RouteSet *currentRouteSet;
@property (readonly, retain) RouteCollection *currentRouteCollection;
@property (readwrite, retain) NSString *descriptionMultiRows;

@property BOOL validRouteSelection;
@property BOOL validRouteSetSelected;
@property BOOL validRouteCollectionSelected;

- (NSArray*)routeCollections;
- (NSArray*)routes;
- (RouteCollection*)routeCollectionForUUID: (NSString*)UUID;

// route actions
- (IBAction)setRouteType: (id)sender;
- (IBAction)loadRoute: (id)sender;
- (IBAction)waypointMenuAction: (id)sender;
- (IBAction)closeDescription: (id)sender;

// importing/exporting
- (void)importRouteAtPath: (NSString*)path;

- (IBAction)visualize: (id)sender;
- (IBAction)closeVisualize: (id)sender;
- (IBAction)moveToWaypoint: (id)sender;
- (IBAction)testWaypointSequence: (id)sender;
- (IBAction)stopMovement: (id)sender;
- (IBAction)closestWaypoint: (id)sender;

// waypoint automation
- (IBAction)openAutomatorPanel: (id)sender;
- (IBAction)closeAutomatorPanel: (id)sender;
- (IBAction)startStopAutomator: (id)sender;
- (IBAction)resetAllWaypoints: (id)sender;

// waypoint actions
- (IBAction)addWaypoint: (id)sender;
- (IBAction)removeWaypoint: (id)sender;
- (IBAction)editWaypointAction: (id)sender;
- (void)waypointActionEditorClosed: (BOOL)change;

// new action/conditions
- (void)selectCurrentWaypoint:(int)index;

- (void)setCurrentRouteSet: (RouteSet*)routeSet;

// new Route Collection stuff
- (IBAction)deleteRouteButton: (id)sender;
- (IBAction)deleteRouteMenu: (id)sender;
- (IBAction)addRouteSet: (id)sender;
- (IBAction)addRouteCollection: (id)sender;
- (IBAction)closeHelpPanel: (id)sender;
- (IBAction)startingRouteClicked: (id)sender;
- (IBAction)importRoute: (id)sender;
- (IBAction)exportRoute: (id)sender;
- (IBAction)renameRoute: (id)sender;
- (IBAction)duplicateRoute: (id)sender;
- (IBAction)showInFinder: (id)sender;

// TO DO: add import/export/show/duplicate

@end
