//
//  WaypointActionEditor.m
//  Pocket Gnome
//
//  Created by Josh on 1/13/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "WaypointActionEditor.h"

#import "Waypoint.h"
#import "Rule.h"
#import "Spell.h"
#import "RouteCollection.h"
#import "RouteSet.h"
#import "MailActionProfile.h"

#import "Action.h"
#import "Condition.h"
#import "ConditionCell.h"
#import "ConditionController.h"

#import "DurabilityConditionController.h"
#import "InventoryConditionController.h"
#import "PlayerLevelConditionController.h"
#import "PlayerZoneConditionController.h"
#import "QuestConditionController.h"
#import "RouteRunTimeConditionController.h"
#import "RouteRunCountConditionController.h"
#import "InventoryFreeConditionController.h"
#import "MobsKilledConditionController.h"
#import "GateConditionController.h"
#import "StrandStatusConditionController.h"
#import "AuraConditionController.h"

#import "SwitchRouteActionController.h"
#import "RepairActionController.h"
#import "SpellActionController.h"
#import "ItemActionController.h"
#import "MacroActionController.h"
#import "DelayActionController.h"
#import "JumpActionController.h"
#import "QuestTurnInActionController.h"
#import "QuestGrabActionController.h"
#import "InteractObjectActionController.h"
#import "InteractNPCActionController.h"
#import "CombatProfileActionController.h"
#import "VendorActionController.h"
#import "MailActionController.h"
#import "ReverseRouteActionController.h"
#import "JumpToWaypointActionController.h"

#import "WaypointController.h"
#import "SpellController.h"
#import "InventoryController.h"
#import "MacroController.h"
#import "ProfileController.h"
#import "MobController.h"
#import "NodeController.h"

@implementation WaypointActionEditor

static WaypointActionEditor *sharedEditor = nil;

+ (WaypointActionEditor *)sharedEditor {
	if (sharedEditor == nil)
		sharedEditor = [[[self class] alloc] init];
	return sharedEditor;
}

- (id) init {
    self = [super init];
    if(sharedEditor) {
		[self release];
		self = sharedEditor;
    } if (self != nil) {
		sharedEditor = self;
		
		_waypoint = nil;
		_conditionList = [[NSMutableArray array] retain];
		_actionList = [[NSMutableArray array] retain];
		
        [NSBundle loadNibNamed: @"WaypointActionEditor" owner: self];
    }
    return self;
}


- (void)awakeFromNib {
    // set our column to use a Rule Cell
    NSTableColumn *column = [conditionTableView tableColumnWithIdentifier: @"Conditions"];
	[column setDataCell: [[[ConditionCell alloc] init] autorelease]];
	[column setEditable: NO];
	
	
    NSTableColumn *column2 = [actionTableView tableColumnWithIdentifier: @"Actions"];
	[column2 setDataCell: [[[ConditionCell alloc] init] autorelease]];
	[column2 setEditable: NO];
}

#pragma mark UI

- (IBAction)addCondition:(id)sender{
	
	int type = [[addConditionDropDown selectedItem] tag];
	
    ConditionController *newCondition = nil;

	if ( type == VarietyInventory )				newCondition = [[[InventoryConditionController alloc] init] autorelease];
	else if ( type == VarietyDurability )		newCondition = [[[DurabilityConditionController alloc] init] autorelease];
	else if ( type == VarietyPlayerLevel )		newCondition = [[[PlayerLevelConditionController alloc] init] autorelease];
	else if ( type == VarietyPlayerZone )		newCondition = [[[PlayerZoneConditionController alloc] init] autorelease];
	else if ( type == VarietyQuest )			newCondition = [[[QuestConditionController alloc] init] autorelease];
	else if ( type == VarietyRouteRunTime )		newCondition = [[[RouteRunTimeConditionController alloc] init] autorelease];
	else if ( type == VarietyRouteRunCount )	newCondition = [[[RouteRunCountConditionController alloc] init] autorelease];
	else if ( type == VarietyInventoryFree )	newCondition = [[[InventoryFreeConditionController alloc] init] autorelease];
	else if ( type == VarietyMobsKilled )		newCondition = [[[MobsKilledConditionController alloc] init] autorelease];
	else if ( type == VarietyGate )				newCondition = [[[GateConditionController alloc] init] autorelease];
	else if ( type == VarietyStrandStatus )		newCondition = [[[StrandStatusConditionController alloc] init] autorelease];
	else if ( type == VarietyAura )				newCondition = [[[AuraConditionController alloc] init] autorelease];
	
    if ( newCondition ) {
        [_conditionList addObject: newCondition];
        [conditionTableView reloadData];
        [conditionTableView selectRowIndexes: [NSIndexSet indexSetWithIndex: [_conditionList count] - 1] byExtendingSelection: NO];
        
        //[sender selectItemWithTag: 0];
    }
	
}

- (void)addActionWithType:(int)type andAction:(Action*)action{
	ActionController *newAction = nil;
	
	RouteSet *currentRoute = [waypointController currentRouteSet];
	RouteCollection *parentRC = [currentRoute parent];
	
	if ( type == ActionType_Repair )				newAction = [[[RepairActionController alloc] init] autorelease];
	else if ( type == ActionType_SwitchRoute )		newAction = [SwitchRouteActionController switchRouteActionControllerWithRoutes:[parentRC routes]];
	else if ( type == ActionType_Spell )			newAction = [SpellActionController spellActionControllerWithSpells:[spellController playerSpells]];
	else if ( type == ActionType_Item )				newAction = [ItemActionController itemActionControllerWithItems:[inventoryController useableItems]];
	else if ( type == ActionType_Macro)				newAction = [MacroActionController macroActionControllerWithMacros:[macroController macros]];
	else if ( type == ActionType_Delay)				newAction = [[[DelayActionController alloc] init] autorelease];
	else if ( type == ActionType_Jump)				newAction = [[[JumpActionController alloc] init] autorelease];
	else if ( type == ActionType_QuestTurnIn)		newAction = [[[QuestTurnInActionController alloc] init] autorelease];
	else if ( type == ActionType_QuestGrab)			newAction = [[[QuestGrabActionController alloc] init] autorelease];
	else if ( type == ActionType_CombatProfile)		newAction = [CombatProfileActionController combatProfileActionControllerWithProfiles:[profileController combatProfiles]];
	else if ( type == ActionType_Vendor)			newAction = [[[VendorActionController alloc] init] autorelease];
	else if ( type == ActionType_Mail)				newAction = [MailActionController mailActionControllerWithProfiles:[profileController profilesOfClass:[MailActionProfile class]]];
	else if ( type == ActionType_ReverseRoute)		newAction = [[[ReverseRouteActionController alloc] init] autorelease];
	else if ( type == ActionType_InteractNPC){
		NSArray *nearbyMobs = [mobController mobsWithinDistance:8.0f levelRange:NSMakeRange(0,255) includeElite:YES includeFriendly:YES includeNeutral:YES includeHostile:NO];				
		newAction = [InteractNPCActionController interactNPCActionControllerWithUnits:nearbyMobs];
	}
	else if ( type == ActionType_InteractObject){
		NSArray *nodes = [nodeController nodesWithinDistance:8.0f ofType:AnyNode maxLevel:9000];
		newAction = [InteractObjectActionController interactObjectActionControllerWithObjects:nodes];
	}
	else if ( type == ActionType_JumpToWaypoint)		newAction = [JumpToWaypointActionController jumpToWaypointActionControllerWithTotalWaypoints:[[[waypointController currentRoute] waypoints] count]];
	
	if ( action != nil ){
		[newAction setStateFromAction:action];
	}
	
    if ( newAction ) {
        [_actionList addObject: newAction];
        [actionTableView reloadData];
        [actionTableView selectRowIndexes: [NSIndexSet indexSetWithIndex: [_actionList count] - 1] byExtendingSelection: NO];
        
        //[sender selectItemWithTag: 0];
    }
}

- (IBAction)addAction:(id)sender{
	[self addActionWithType:[[addActionDropDown selectedItem] tag] andAction:nil];
}

- (void)clearTables{
	
	// remove all
	[_conditionList removeAllObjects];
	[conditionTableView reloadData];
	
	// for actions we need to remove bindings
	for ( id actionController in _actionList ){
		[actionController removeBindings];
	}

	[_actionList removeAllObjects];
	[actionTableView reloadData];
}

// editor opens! Load info for a given waypoint!
- (void)showEditorOnWindow: (NSWindow*)window withWaypoint: (Waypoint*)wp withAction:(int)type {
	
	_waypoint = [wp retain];
	
	[self clearTables];
	
	// valid waypoint (not sure why it wouldn't be)
	if ( wp ){
		
		// add description
		if ( [wp title] ){
			[waypointDescription setStringValue:[wp title]];
		}
		
		// add any actions
		if ( [wp.actions count] > 0 ){
			for ( Action *action in wp.actions ) {
				[self addActionWithType:[action type] andAction:action];
			}
			
			// do we need to add another? (i.e. if they chose item when spell was selected, lets add an item!)
			BOOL found = NO;
			for ( id actionController in _actionList ){
				if ( [[(ActionController*)actionController action] type] == type )
					found = YES;
			}
			if ( !found ){
				[self addActionWithType:type andAction:nil];
			}
		}
		// add a default
		else if ( type > ActionType_None && type <= ActionType_Max ){

			[self addActionWithType:type andAction:nil];
		}
		
		// add our conditions!
		if ( wp.rule ){
			
			for ( Condition *condition in [wp.rule conditions] ) {
				[_conditionList addObject: [ConditionController conditionControllerWithCondition: condition]];
			}
			
			if( [wp.rule isMatchAll] )
				[conditionMatchingSegment selectSegmentWithTag: 0];
			else
				[conditionMatchingSegment selectSegmentWithTag: 1];
		}
	}

	// reload tables
	[actionTableView reloadData];
	[conditionTableView reloadData];
	
	[NSApp beginSheet: editorPanel
	   modalForWindow: window
		modalDelegate: self
	   didEndSelector: nil
		  contextInfo: [NSNumber numberWithInt:type]];
}

- (IBAction)closeEditor: (id)sender {
    [[sender window] makeFirstResponder: [[sender window] contentView]];
    [NSApp endSheet: editorPanel returnCode: NSOKButton];
    [editorPanel orderOut: nil];
	
	// let our controller know if a change was made
	[waypointController waypointActionEditorClosed:(sender==nil)];
}

- (IBAction)saveWaypoint: (id)sender{

	_waypoint.title = [waypointDescription stringValue];
	
	// save actions
	[_waypoint setActions:nil];
	for ( id actionController in _actionList ){
		[_waypoint addAction:[(ActionController*)actionController action]];
	}
	
	// add the conditions to an array
	NSMutableArray *conditions = [NSMutableArray array];
	for ( id conditionController in _conditionList ){
		Condition *condition = [(ConditionController*)conditionController condition];
		if ( condition ){
			[conditions addObject: condition];
		}	
	}
	
	// create a rule
	Rule *newRule = nil;
	if([conditions count]) {
		newRule = [[Rule alloc] init];
		
		[newRule setName:_waypoint.title];
		[newRule setConditions:conditions];
		[newRule setIsMatchAll: [conditionMatchingSegment isSelectedForSegment: 0]];
		[newRule setTarget: TargetNone];
		[newRule setAction:nil];		// we can have multiple actions, we'll ignore this
	}
	
	_waypoint.rule = newRule;

	[self closeEditor:nil];	
}

- (NSArray*)routes{
	return [waypointController routes];
}

#pragma mark -
#pragma mark TableView Delegate/DataSource

- (void) tableView:(NSTableView *) tableView willDisplayCell:(id) cell forTableColumn:(NSTableColumn *) tableColumn row:(int) row
{
	if( [[tableColumn identifier] isEqualToString: @"Conditions"] ) {
		NSView *view = [[_conditionList objectAtIndex: row] view];
		[(ConditionCell*)cell addSubview: view];
	}
	else if( [[tableColumn identifier] isEqualToString: @"Actions"] ) {
		NSView *view = [[_actionList objectAtIndex: row] view];
		[(ConditionCell*)cell addSubview: view];
	}
}

// Methods from NSTableDataSource protocol
- (int) numberOfRowsInTableView:(NSTableView *) tableView{
	
	if ( tableView == conditionTableView )
		return [_conditionList count];
	else if ( tableView == actionTableView ){
		return [_actionList count];
	}
	
	return 0;
}

- (id) tableView:(NSTableView *) tableView objectValueForTableColumn:(NSTableColumn *) tableColumn row:(int) row{
	return @"";
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
    //[self validateBindings];
}

- (void)tableView: (NSTableView*)tableView deleteKeyPressedOnRowIndexes: (NSIndexSet*)rowIndexes {
    if([rowIndexes count] == 0)   return;
    
	if ( tableView == conditionTableView ){
		int row = [rowIndexes lastIndex];
		while(row != NSNotFound) {
			[_conditionList removeObjectAtIndex: row];
			row = [rowIndexes indexLessThanIndex: row];
		}
		[conditionTableView reloadData];
	}
	else if ( tableView == actionTableView ){
		int row = [rowIndexes lastIndex];
		while(row != NSNotFound) {
			id actionController = [_actionList objectAtIndex:row];
			[actionController removeBindings];
			[_actionList removeObjectAtIndex: row];
			row = [rowIndexes indexLessThanIndex: row];
		}
		[actionTableView reloadData];
	}
}

- (BOOL)tableView:(NSTableView *)tableView shouldTypeSelectForEvent:(NSEvent *)event withCurrentSearchString:(NSString *)searchString {
    return NO;
}

@end
