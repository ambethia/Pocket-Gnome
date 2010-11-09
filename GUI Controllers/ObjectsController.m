//
//  ObjectController.m
//  Pocket Gnome
//
//  Created by Josh on 2/4/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "ObjectsController.h"
#import "PlayersController.h"
#import "MovementController.h"
#import "PlayerDataController.h"

#import "Controller.h"
#import "MobController.h"
#import "NodeController.h"
#import "ImageAndTextCell.h"

@interface ObjectsController (Internal)
- (id)currentController;
- (WoWObject*)selectedObject;
@end

@implementation ObjectsController

- (id) init{
    self = [super init];
	if ( self != nil ){
		
		// default to players tab
		_currentTab = [[NSUserDefaults standardUserDefaults] integerForKey:@"DefaultObjectTab"];
		
		_updateFrequency = 1.0f;
		
		_mobFilterString = nil;
		_nodeFilterString = nil;
		
		[[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(viewLoaded:) 
                                                     name: DidLoadViewInMainWindowNotification 
                                                   object: nil];

		[NSBundle loadNibNamed: @"Objects" owner: self];
	}
	
	return self;
}

- (void)viewLoaded: (NSNotification*)notification {
	
    if ( [notification object] == self.view ) {
		// select the saved tab!
		[tabView selectTabViewItemWithIdentifier:[NSString stringWithFormat:@"%d",_currentTab]];
    } 
}

- (void)awakeFromNib {
    self.minSectionSize = [self.view frame].size;
    self.maxSectionSize = NSZeroSize;
	
	NSString *key = [[self currentController] updateFrequencyKey];
	if ( key ){
		self.updateFrequency = [[NSUserDefaults standardUserDefaults] floatForKey:key];
	}
	
	[mobTable setDoubleAction: @selector(tableDoubleClick:)];
    [mobTable setTarget: self];
	[playersTable setDoubleAction: @selector(tableDoubleClick:)];
    [playersTable setTarget: self];
	[itemTable setDoubleAction: @selector(tableDoubleClick:)];
    [itemTable setTarget: self];
	[nodeTable setDoubleAction: @selector(tableDoubleClick:)];
    [nodeTable setTarget: self];
	
    ImageAndTextCell *imageAndTextCell = [[[ImageAndTextCell alloc] init] autorelease];
    [imageAndTextCell setEditable: NO];
    [[mobTable tableColumnWithIdentifier: @"Name"] setDataCell: imageAndTextCell];
    [[playersTable tableColumnWithIdentifier: @"Class"] setDataCell: imageAndTextCell];
    [[playersTable tableColumnWithIdentifier: @"Race"] setDataCell: imageAndTextCell];
    [[playersTable tableColumnWithIdentifier: @"Gender"] setDataCell: imageAndTextCell];
    [[nodeTable tableColumnWithIdentifier: @"Name"] setDataCell: imageAndTextCell];
}

- (void)dealloc{
	[super dealloc];
}

@synthesize view;
@synthesize minSectionSize = _minSectionSize;
@synthesize maxSectionSize = _maxSectionSize;
@synthesize updateFrequency = _updateFrequency;

@synthesize mobTable;
@synthesize itemTable;
@synthesize playersTable;
@synthesize nodeTable;

- (NSString*)sectionTitle {
    return @"Objects";
}

- (void)setUpdateFrequency: (float)frequency {
    if(frequency < 0.1) frequency = 0.1;
    
    [self willChangeValueForKey: @"updateFrequency"];
    _updateFrequency = [[NSString stringWithFormat: @"%.2f", frequency] floatValue];
    [self didChangeValueForKey: @"updateFrequency"];
    
	NSString *key = [[self currentController] updateFrequencyKey];
	if ( key ){
		[[NSUserDefaults standardUserDefaults] setFloat: _updateFrequency forKey: [[self currentController] updateFrequencyKey]];
	}
	
	// let our individual controllers know!
	[(ObjectController*)[self currentController] setUpdateFrequency:_updateFrequency];
	
	[_updateTimer invalidate];
    _updateTimer = [NSTimer scheduledTimerWithTimeInterval: frequency target: self selector: @selector(updateCount) userInfo: nil repeats: YES];	
}

- (int)objectCount{
	
	return [playersController objectCount] + [mobController objectCount] + [itemController objectCount] + [nodeController objectCount];
}

// just returns the controller that is currently being viwed
- (id)currentController{
	if ( _currentTab == Tab_Players ){
		return playersController;
	}
	else if ( _currentTab == Tab_Mobs ){
		return mobController;
	}
	else if ( _currentTab == Tab_Items ){
		return itemController;
	}
	else if ( _currentTab == Tab_Nodes ){
		return nodeController;
	}
	
	return nil;
}

- (NSTableView*)currentTable{
	if ( _currentTab == Tab_Players ){
		return playersTable;
	}
	else if ( _currentTab == Tab_Mobs ){
		return mobTable;
	}
	else if ( _currentTab == Tab_Items ){
		return itemTable;
	}
	else if ( _currentTab == Tab_Nodes ){
		return nodeTable;
	}
	
	return nil;	
}

- (BOOL)isTabVisible:(int)tab{
	
	if ( _currentTab == Tab_Players && [[playersTable window] isVisible] ){
		return YES;
	}
	else if ( _currentTab == Tab_Mobs && [[mobTable window] isVisible] ){
		return YES;
	}
	else if ( _currentTab == Tab_Items && [[itemTable window] isVisible] ){
		return YES;
	}
	else if ( _currentTab == Tab_Nodes && [[nodeTable window] isVisible] ){
		return YES;
	}

	return NO;
}

- (void)loadTabData{
	
	if ( _currentTab == Tab_Players ){
		[playersTable reloadData];
	}
	else if ( _currentTab == Tab_Mobs ){
		[mobTable reloadData];
	}
	else if ( _currentTab == Tab_Items ){
		[itemTable reloadData];
	}
	else if ( _currentTab == Tab_Nodes ){
		[nodeTable reloadData];
	}
}

- (NSString*)nameFilter{
	if ( _currentTab == Tab_Nodes )
		return [[_nodeFilterString retain] autorelease];
	else if ( _currentTab == Tab_Mobs )
		return [[_mobFilterString retain] autorelease];
	
	return nil;
}

- (WoWObject*)selectedObject{
	int selectedRow = [[self currentTable] selectedRow];
    if ( selectedRow == -1 ) return nil;
	
	WoWObject *obj = [(ObjectController*)[self currentController] objectForRowIndex:selectedRow];
	return obj;
}

#pragma mark Menus

- (void)setMobMenu{
	
	id selectedObject = [[moveToMobPopUpButton selectedItem] representedObject];
	
	NSMenu *mobMenu = [[[NSMenu alloc] initWithTitle: @"Currently Selected Mob"] autorelease];
	NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle: @"Currently Selected Mob" action: nil keyEquivalent: @""] autorelease];	
	[item setTag: -1];
	[item setIndentationLevel: 1];
	[mobMenu addItem: item];
	
	// add a separator
	item = [NSMenuItem separatorItem];
	[mobMenu addItem: item];
	
	BOOL previousMobFound = NO;
	
	// add UNIQUE items to the menu
	for ( NSString *mobName in [mobController uniqueMobsAlphabetized] ){
		item = [[[NSMenuItem alloc] initWithTitle: [NSString stringWithFormat: @"Closest %@", mobName] action: nil keyEquivalent: @""] autorelease];
		[item setTag: 0];
		[item setIndentationLevel: 1];
		[item setRepresentedObject: mobName];
		[mobMenu addItem: item];
		
		if ( selectedObject && [mobName isEqualToString:selectedObject] ){
			previousMobFound = YES;
		}
	}
	
	// should we keep the selected item in the menu if it's not found nearby?
	if ( selectedObject && !previousMobFound ){
		item = [[[NSMenuItem alloc] initWithTitle: [NSString stringWithFormat: @"Closest %@", selectedObject] action: nil keyEquivalent: @""] autorelease];
		[item setTag: 0];
		[item setIndentationLevel: 1];
		[item setRepresentedObject: selectedObject];
		[mobMenu addItem: item];
	}
	
	[moveToMobPopUpButton setMenu:mobMenu];	
	
	if ( selectedObject ){
		[moveToMobPopUpButton selectItemWithTitle: [NSString stringWithFormat: @"Closest %@", selectedObject]];
	}
	else{
		[moveToMobPopUpButton selectItemWithTag:-1];
	}
}

- (void)setNodeMenu{
	
	id selectedObject = [[moveToNodePopUpButton selectedItem] representedObject];
	
	NSMenu *nodeMenu = [[[NSMenu alloc] initWithTitle: @"Currently Selected Node"] autorelease];
	NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle: @"Currently Selected Node" action: nil keyEquivalent: @""] autorelease];	
	[item setTag: -1];
	[item setIndentationLevel: 1];
	[nodeMenu addItem: item];
	
	// add a separator
	item = [NSMenuItem separatorItem];
	[nodeMenu addItem: item];
	
	BOOL previousNodeFound = NO;
	
	// add UNIQUE items to the menu
	for ( NSString *nodeName in [nodeController uniqueNodesAlphabetized] ){
		item = [[[NSMenuItem alloc] initWithTitle: [NSString stringWithFormat: @"Closest %@", nodeName] action: nil keyEquivalent: @""] autorelease];
		[item setTag: 0];
		[item setIndentationLevel: 1];
		[item setRepresentedObject: nodeName];
		[nodeMenu addItem: item];
		
		if ( selectedObject && [nodeName isEqualToString:selectedObject] ){
			previousNodeFound = YES;
		}
	}
	
	// should we keep the selected item in the menu if it's not found nearby?
	if ( selectedObject && !previousNodeFound ){
		item = [[[NSMenuItem alloc] initWithTitle: [NSString stringWithFormat: @"Closest %@", selectedObject] action: nil keyEquivalent: @""] autorelease];
		[item setTag: 0];
		[item setIndentationLevel: 1];
		[item setRepresentedObject: selectedObject];
		[nodeMenu addItem: item];
	}
	
	[moveToNodePopUpButton setMenu:nodeMenu];	
	
	if ( selectedObject ){
		[moveToNodePopUpButton selectItemWithTitle: [NSString stringWithFormat: @"Closest %@", selectedObject]];
	}
	else{
		[moveToNodePopUpButton selectItemWithTag:-1];
	}
}

#pragma mark -
#pragma mark TableView Delegate & Datasource

- (int)numberOfRowsInTableView:(NSTableView *)aTableView {
	
	if ( aTableView == playersTable ){
		return [playersController objectCountWithFilters];
	}
	else if ( aTableView == mobTable ){
		return [mobController objectCountWithFilters];
	}
	else if ( aTableView == itemTable ){
		return [itemController objectCountWithFilters];
	}
	else if ( aTableView == nodeTable ){
		return [nodeController objectCountWithFilters];
	}
	
	return 0;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
    if(rowIndex == -1) return nil;
	
	if ( aTableView == playersTable ){
		return [playersController tableView:aTableView objectValueForTableColumn:aTableColumn row:rowIndex];
	}
	else if ( aTableView == mobTable ){
		return [mobController tableView:aTableView objectValueForTableColumn:aTableColumn row:rowIndex];
	}
	else if ( aTableView == itemTable ){
		return [itemController tableView:aTableView objectValueForTableColumn:aTableColumn row:rowIndex];
	}
	else if ( aTableView == nodeTable ){
		return [nodeController tableView:aTableView objectValueForTableColumn:aTableColumn row:rowIndex];
	}
	
	return nil;
}

- (void)tableView:(NSTableView *)aTableView sortDescriptorsDidChange:(NSArray *)oldDescriptors {
	
	if ( aTableView == playersTable ){
		[playersController sortUsingDescriptors:[aTableView sortDescriptors]];
		[aTableView reloadData];
	}
	else if ( aTableView == mobTable ){
		[mobController sortUsingDescriptors:[aTableView sortDescriptors]];
		[aTableView reloadData];
	}
	else if ( aTableView == itemTable ){
		[itemController sortUsingDescriptors:[aTableView sortDescriptors]];
		[aTableView reloadData];
	}
	else if ( aTableView == nodeTable ){
		[nodeController sortUsingDescriptors:[aTableView sortDescriptors]];
		[aTableView reloadData];
	}
}

- (void)tableView: (NSTableView *)aTableView willDisplayCell: (id)aCell forTableColumn: (NSTableColumn *)aTableColumn row: (int)aRowIndex{
	
	if ( aTableView == mobTable ){
		[mobController tableView:aTableView willDisplayCell:aCell forTableColumn:aTableColumn row:aRowIndex];
	}
	else if ( aTableView == playersTable ){
		[playersController tableView:aTableView willDisplayCell:aCell forTableColumn:aTableColumn row:aRowIndex];
	}
	else if ( aTableView == nodeTable ){
		[nodeController tableView:aTableView willDisplayCell:aCell forTableColumn:aTableColumn row:aRowIndex];
	}
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    return NO;
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectTableColumn:(NSTableColumn *)aTableColumn{
	
	if ( aTableView == mobTable ){
		return [mobController tableView:(NSTableView *)aTableView shouldSelectTableColumn:(NSTableColumn *)aTableColumn];
	}
	else if ( aTableView == playersTable ){
		return [playersController tableView:(NSTableView *)aTableView shouldSelectTableColumn:(NSTableColumn *)aTableColumn];
	}
	
	return YES;
}

- (void)itemTableDoubleClick: (id)sender {
    if( [sender clickedRow] == -1 ) return;
    
    //[memoryViewController showObjectMemory: [[_itemDataList objectAtIndex: [sender clickedRow]] objectForKey: @"Item"]];
    //[controller showMemoryView];
}

// called when a tab is changed
- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem{
	
	_currentTab = [[tabViewItem identifier] intValue];
	
	// refresh data
	[(ObjectController*)[self currentController] refreshData];
	
	// tab changed? Updates our frequency
	self.updateFrequency = [[NSUserDefaults standardUserDefaults] floatForKey:[[self currentController] updateFrequencyKey]];
	
	// save the tab!
	[[NSUserDefaults standardUserDefaults] setInteger:_currentTab forKey:@"DefaultObjectTab"];
}

#pragma mark Timers

- (void)updateCount{
	
	// update menus if we need to
	if ( _currentTab == Tab_Mobs )
		[self setMobMenu];
	else if ( _currentTab == Tab_Nodes )
		[self setNodeMenu];
	
	// invert them (so it can detect a change during the timer tick)
	[self didChangeValueForKey: @"objectCount"];
	
	[self willChangeValueForKey: @"objectCount"];
}

#pragma mark UI Actions

- (IBAction)filter: (id)sender {
	
	if ( _currentTab == Tab_Nodes ){
		if ( [[sender stringValue] length] ){
			_nodeFilterString = [[sender stringValue] retain];
		}
		else{
			_nodeFilterString = nil;
		}
		
		[nodeController refreshData];
	}
	
	else if ( _currentTab == Tab_Mobs ){
		if ( [[sender stringValue] length] ){
			_mobFilterString = [[sender stringValue] retain];
		}
		else{
			_mobFilterString = nil;
		}
		
		[mobController refreshData];
	}
}

- (IBAction)refreshData: (id)sender{
	// refresh data
	[(ObjectController*)[self currentController] refreshData];
}

- (IBAction)updateTracking: (id)sender{
	if ( _currentTab == Tab_Mobs ){
		[mobController updateTracking:sender];
	}
	if ( _currentTab == Tab_Players ){
		[playersController updateTracking:sender];
	}
}

- (IBAction)moveToStart: (id)sender{
	
	if ( _currentTab == Tab_Mobs ){
		
		// currently selected object
		if ( [moveToMobPopUpButton selectedTag] == -1 ){
			WoWObject *obj = [self selectedObject];
			
			if ( obj ){
				[movementController moveToObject:obj];	//andNotify:NO
			}
		}
		
		// listed object
		else{
			WoWObject *obj = [mobController closestMobWithName:[[moveToMobPopUpButton selectedItem] representedObject]];
			if ( obj ){
				[movementController moveToObject:obj];	// andNotify:NO
			}
		}		
	}
	else if ( _currentTab == Tab_Nodes ){
		
		// currently selected object
		if ( [moveToNodePopUpButton selectedTag] == -1 ){
			WoWObject *obj = [self selectedObject];
			
			if ( obj ){
				[movementController moveToObject:obj];	// andNotify:NO
			}
		}
		
		// listed object
		else{
			WoWObject *obj = [nodeController closestNodeWithName:[[moveToNodePopUpButton selectedItem] representedObject]];
			if ( obj ){
				[movementController moveToObject:obj];	// andNotify:NO
			}
		}	
	}	
}

- (IBAction)moveToStop: (id)sender{
	[movementController resetMovementState];
}

- (IBAction)resetObjects: (id)sender{
	[(ObjectController*)[self currentController] resetAllObjects];
}

- (IBAction)targetObject: (id)sender{
	
	WoWObject *obj = [self selectedObject];
	
	log(LOG_GENERAL, @"[Objects] Selecting %@", obj);
	
	if ( obj ){
		[playerController setPrimaryTarget: obj];
	}
}

- (IBAction)faceObject: (id)sender{
	
	WoWObject *obj = [self selectedObject];
	
	if ( obj ){
		[movementController turnTowardObject:obj];
	}
}

- (IBAction)reloadNames: (id)sender{
	[controller traverseNameList];
}

- (void)tableDoubleClick: (id)sender {
	if ( [sender clickedRow] == -1 ) return;
	
	[(ObjectController*)[self currentController] tableDoubleClick:sender];
}

@end
