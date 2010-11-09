/*
 * Copyright (c) 2007-2010 Savory Software, LLC, http://pg.savorydeviate.com/
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * $Id: ProfileController.m 315 2010-04-17 04:12:45Z Tanaris4 $
 *
 */

#import "ProfileController.h"
#import "Profile.h"
#import "MailActionProfile.h"
#import "CombatProfile.h"
#import "Player.h"
#import "Mob.h"

#import "FileController.h"
#import "Controller.h"
#import "PlayersController.h"
#import "MobController.h"

@interface ProfileController (Internal)
- (void)setProfile:(Profile *)profile;
- (void)updateTitle;
@end

#define CombatProfileName		@"Combat"
#define MailActionName			@"Mail Action"

@implementation ProfileController

- (id) init
{
    self = [super init];
    if (self != nil) {
		_profiles = [[NSMutableArray array] retain];
		
		_currentCombatProfile = nil;
		_currentMailActionProfile = nil;
		
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(applicationWillTerminate:) name: NSApplicationWillTerminateNotification object: nil];
		
		if ( fileController == nil ){
			fileController = [[FileController sharedFileController] retain];
		}
		
		// get mail action profiles
		NSArray *mailActionProfiles = [fileController getObjectsWithClass:[MailActionProfile class]];
		[_profiles addObjectsFromArray:mailActionProfiles];
		
		// get combat profiles
		NSArray *combatProfiles = [fileController getObjectsWithClass:[CombatProfile class]];
		[_profiles addObjectsFromArray:combatProfiles];
		
		[[NSNotificationCenter defaultCenter] postNotificationName: ProfilesLoaded object: self];
		
		[NSBundle loadNibNamed: @"Profiles" owner: self];
    }
    return self;
}

- (void)awakeFromNib {
	
	self.minSectionSize = [self.view frame].size;
    self.maxSectionSize = NSZeroSize;
	
	// select the first tab
	[profileTabView selectFirstTabViewItem:nil];
	
	[self updateTitle];
}

@synthesize view;
@synthesize minSectionSize;
@synthesize maxSectionSize;

@synthesize currentCombatProfile = _currentCombatProfile;
@synthesize currentMailActionProfile = _currentMailActionProfile;

- (NSString*)sectionTitle {
    return @"Profiles";
}

- (void)dealloc{
	[_profiles release]; _profiles = nil;
	[super dealloc];
}

// pass a class, and receive ALL the objects of that type! ezmode!
- (NSArray*)profilesOfClass:(Class)objectClass{
	
	NSMutableArray *objects = [NSMutableArray array];
	
	for ( id profile in _profiles ){
		if ( [profile isKindOfClass:objectClass] ){
			[objects addObject:profile];
		}
	}
	
	return [[objects retain] autorelease];
}

- (Profile*)profileForUUID:(NSString*)uuid{
	for ( Profile *profile in _profiles ){
		if ( [[profile UUID] isEqualToString:uuid] ){
			return [[profile retain] autorelease];
		}
	}
	return nil;
}

// add a profile
- (void)addProfile:(Profile*)profile{
	
	int num = 2;
    BOOL done = NO;
    if( ![[profile name] length] ) return;
	
    // check to see if a route exists with this name
    NSString *originalName = [profile name];
    while( !done ) {
        BOOL conflict = NO;
        for ( id existingProfile in _profiles ) {
			
			// UUID's match?
			if ( [[existingProfile UUID] isEqualToString:[profile UUID]] ){
				[profile updateUUUID];
			}
			
			// same profile type + same name! o noes!
			if ( [existingProfile isKindOfClass:[profile class]] && [[existingProfile name] isEqualToString: [profile name]] ){
                [profile setName: [NSString stringWithFormat: @"%@ %d", originalName, num++]];
                conflict = YES;
                break;
            }
        }
        if( !conflict ) done = YES;
    }
	
	// add it to our list of profiles!
	[_profiles addObject:profile];
	
	// save it (in case we crash?)
	[fileController saveObject:profile];
	
	profile.changed = YES;
	
	// error here on observers :(
	[self setProfile:profile];
}

- (BOOL)removeProfile:(Profile*)prof{
	
	Profile *profToDelete = nil;
	for ( Profile *profile in _profiles ){
		
		if ( [profile isKindOfClass:[prof class]] && [[profile name] isEqualToString:[prof name]] ){
			profToDelete = profile;
			break;
		}
	}
	
	[fileController deleteObject:profToDelete];
	[_profiles removeObject:profToDelete];
	[profileOutlineView reloadData];
	
	if ( profToDelete )
		return YES;
	
	return NO;      
}

// just return a list of profiles by class
- (NSArray*)profilesByClass{
	
	NSMutableArray *list = [NSMutableArray array];
	
	// form a list of the unique classes
	NSMutableArray *classList = [NSMutableArray array];
	for ( id profile in _profiles ){
		if ( ![classList containsObject:[profile class]] ){
			[classList addObject:[profile class]];
		}
	}
	
	// woohoo lets set up arrays by class!
	for ( id class in classList ){
		NSMutableArray *profiles = [NSMutableArray array];
		for ( Profile *profile in _profiles ){
			if ( [profile class] == class ){
				[profiles addObject:profile];
			}			
		}
		[list addObject:profiles];
	}

	return list;	
}

- (Profile*)selectedProfile{
	
	// make sure only 1 item is selected!
	if ( [profileOutlineView numberOfSelectedRows] == 1 ){
		id selectedObject = [profileOutlineView itemAtRow:[profileOutlineView selectedRow]];
		
		if ( [[selectedObject className] isEqualToString:@"NSCFString"] || [selectedObject isKindOfClass:[NSString class]] ){
			return nil;
		}
		
		return selectedObject;
	}
	
	return nil;
}

- (void)importProfileAtPath: (NSString*)path {
    id importedProfile;
    NS_DURING {
        importedProfile = [NSKeyedUnarchiver unarchiveObjectWithFile: path];
    } NS_HANDLER {
        importedProfile = nil;
    } NS_ENDHANDLER
	
	id oldImportedProfile = importedProfile;
    
    if ( importedProfile ) {
		
		// combat profile
        if ( [importedProfile isKindOfClass: [CombatProfile class]] ) {
			[self addProfile: importedProfile];
		}
		// mail action profile
		else if ( [importedProfile isKindOfClass:[MailActionProfile class]] ){
			[self addProfile: importedProfile];
		}
		else {
            importedProfile = nil;
        }
    }
    
    if ( !importedProfile ) {
        NSRunAlertPanel(@"Profile not Valid", [NSString stringWithFormat: @"The file at %@ <%@> cannot be imported because it does not contain a valid profile", path, oldImportedProfile], @"Okay", NULL, NULL);
    }
}

- (BOOL)isValidProfile:(id)obj{
	
	if ( [obj isKindOfClass:[CombatProfile class]] ){
		return YES;
	}
	else if ( [obj isKindOfClass:[MailActionProfile class]] ){
		return YES;
	}
	
	return NO;	
}

- (void)openEditor:(SelectedTab)tab{
	
	if ( tab == TabCombat ){
		[profileOutlineView expandItem:CombatProfileName];
	}
	else if ( tab == TabMail ){
		[profileOutlineView expandItem:MailActionName];
	}
	
	[profileTabView selectTabViewItemWithIdentifier:[NSString stringWithFormat:@"%d", tab]];
}

- (void)updateTitle{
	
	if ( self.currentCombatProfile ){
		[profileTitle setStringValue:[NSString stringWithFormat:@"Combat Profile - %@", [self.currentCombatProfile name]]];
	}
	else if ( self.currentMailActionProfile ){
		[profileTitle setStringValue:[NSString stringWithFormat:@"Mail Action Profile - %@", [self.currentMailActionProfile name]]];
	}
	else{
		[profileTitle setStringValue:@"Select or create a new profile to start!"];
	}
}

#pragma mark Getters/Setters

- (void)setProfile:(Profile *)profile{
	
	if ( profile == nil ){
		_currentCombatProfile = nil;
		_currentMailActionProfile = nil;
		[profileTabView selectFirstTabViewItem:nil];
		[self updateTitle];
		return;
	}

	// expand our parent if we need to
	if ( [profile isKindOfClass:[CombatProfile class]] ){
		self.currentCombatProfile = (CombatProfile*)profile;
		self.currentMailActionProfile = nil;
		[profileOutlineView expandItem:CombatProfileName];
		[profileTypePopUp selectItemWithTag:TabCombat];
	}
	else if ( [profile isKindOfClass:[MailActionProfile class]] ){
		self.currentMailActionProfile = (MailActionProfile*)profile;
		self.currentCombatProfile = nil;
		[profileOutlineView expandItem:MailActionName];
		[profileTypePopUp selectItemWithTag:TabMail];
	}
	
	// update our table
	[profileOutlineView reloadData];
	
	// select the item
	NSIndexSet *index = [NSIndexSet indexSetWithIndex:[profileOutlineView rowForItem:profile]];
	[profileOutlineView selectRowIndexes:index byExtendingSelection:NO];
	[profileOutlineView scrollRowToVisible:[index firstIndex]];
	
	// select the correct tab
	if ( [profile isKindOfClass:[CombatProfile class]] ){
		[profileTabView selectTabViewItemWithIdentifier:[NSString stringWithFormat:@"%d", TabCombat]];
	}
	else if ( [profile isKindOfClass:[MailActionProfile class]] ){
		[profileTabView selectTabViewItemWithIdentifier:[NSString stringWithFormat:@"%d", TabMail]];
	}
	[self populatePlayerLists];
	[self updateTitle];
}

#pragma mark Notifications

- (void)applicationWillTerminate: (NSNotification*)notification {
	
	NSMutableArray *objectsToSave = [NSMutableArray array];
	for ( FileObject *obj in _profiles ){
		if ( [obj changed] ){
			[objectsToSave addObject:obj];
		}
	}
	
    [fileController saveObjects:objectsToSave];
	
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"CombatProfiles"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark Bindings

- (NSArray*)combatProfiles{
	return [self profilesOfClass:[CombatProfile class]];	
}

#pragma mark UI

- (IBAction)createProfile: (id)sender{
	
	// make sure we have a valid name
    NSString *profileName = [sender stringValue];
    if ( [profileName length] == 0 ) {
        NSBeep();
        return;
    }
	
	// create the profile
	id profile = nil;
	if ( [profileTypePopUp selectedTag] == TabCombat ){
		profile = [CombatProfile combatProfileWithName:profileName];
	}
	else if ( [profileTypePopUp selectedTag] == TabMail ){
		profile = [MailActionProfile mailActionProfileWithName:profileName];
	}
	
	// create a new profile
	[sender setStringValue: @""];
    [self addProfile: profile];
}

- (IBAction)renameProfile: (id)sender{
	id object = [profileOutlineView itemAtRow:[profileOutlineView clickedRow]];
	if ( [self isValidProfile:object] ){
	
		// select the item
		NSIndexSet *index = [NSIndexSet indexSetWithIndex:[profileOutlineView rowForItem:object]];
		[profileOutlineView selectRowIndexes:index byExtendingSelection:NO];
		[profileOutlineView scrollRowToVisible:[index firstIndex]];

		// edit the new item!
		[profileOutlineView editColumn:0 row:[index firstIndex] withEvent:nil select:YES];
	}
}

- (IBAction)duplicateProfile: (id)sender{
	id object = [profileOutlineView itemAtRow:[profileOutlineView clickedRow]];
	if ( [self isValidProfile:object] ){
		[self addProfile:[object copy]];
	}
}

- (IBAction)importProfile: (id)sender{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	
	[openPanel setCanChooseDirectories: NO];
	[openPanel setCanCreateDirectories: NO];
	[openPanel setPrompt: @"Import Profile"];
	[openPanel setCanChooseFiles: YES];
    [openPanel setAllowsMultipleSelection: YES];
	[openPanel setDirectory:@"~/Desktop"];
	
	int ret = [openPanel runModalForTypes: [NSArray arrayWithObjects: @"combatprofile", @"mailprofile", nil]];
    
	if ( ret == NSFileHandlingPanelOKButton ) {
        for ( NSString *profilePath in [openPanel filenames] ) {
            [self importProfileAtPath: profilePath];
        }
	}
}

- (IBAction)exportProfile: (id)sender{
	// valid object
	id object = [profileOutlineView itemAtRow:[profileOutlineView clickedRow]];
	if ( ![self isValidProfile:object] ){
		return;
	}
	
	NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setCanCreateDirectories: YES];
    [savePanel setTitle: @"Export Profile"];
    [savePanel setMessage: @"Please choose a destination for this profile."];
	
	NSString *extension = nil;
	if ( [object isKindOfClass:[CombatProfile class]] ){
		extension = @"combatprofile";
	}
	else if ( [object isKindOfClass:[MailActionProfile class]] ){
		extension = @"mailprofile";
	}
    int ret = [savePanel runModalForDirectory: @"~/Desktop" file: [[object name] stringByAppendingPathExtension: extension]];
    
	if ( ret == NSFileHandlingPanelOKButton ) {
        NSString *saveLocation = [savePanel filename];
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject: object];
        [data writeToFile: saveLocation atomically: YES];
    }
}

- (IBAction)deleteProfile: (id)sender{
	
	Profile *profile = [self selectedProfile];
	int ret = NSRunAlertPanel(@"Delete?", [NSString stringWithFormat:@"Are you sure you want to delete profile '%@'?", [profile name]], @"No", @"Yes", NULL);
	if ( ret == 0 ){
		[self removeProfile:profile];
	}
}

- (IBAction)showInFinder: (id)sender{
	id object = [profileOutlineView itemAtRow:[profileOutlineView clickedRow]];
	if ( [self isValidProfile:object] ){
		[fileController showInFinder:object];
	}
}

#pragma mark Outline View

// let us know how many children this item has
- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item{
	
	// root
	if ( item == nil ){
		return TabTotal - 1;	// total tabs
	}
	// child
	else{
		// combat profiles
		if ( [item isEqualToString:CombatProfileName] ){
			NSArray *profiles = [self profilesOfClass:[CombatProfile class]];
			return [profiles count];				
		}
		// mail action profiles
		else if ( [item isEqualToString:MailActionName] ){
			NSArray *profiles = [self profilesOfClass:[MailActionProfile class]];
			return [profiles count];	
		}
	}
	
	return 0;
}

// return the child of an item at an index
- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item{
	
	// root
	if ( item == nil ){
		if ( index == TabCombat - 1 ) {
			return CombatProfileName;
		}
		else if ( index == TabMail - 1 ) {
			return MailActionName;
		}
	}
	// child
	else{
		
		// combat profiles
		if ( [item isEqualToString:CombatProfileName] ){
			NSArray *profiles = [self profilesOfClass:[CombatProfile class]];
			if ( index > [profiles count] )	return nil;
			return [profiles objectAtIndex:index];				
		}
		// mail action profiles
		else if ( [item isEqualToString:MailActionName] ){
			NSArray *profiles = [self profilesOfClass:[MailActionProfile class]];
			if ( index > [profiles count] )	return nil;
			return [profiles objectAtIndex:index];	
		}
	}
	
	return nil;	
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item{
	
	if ( [[item className] isEqualToString:@"NSCFString"] || [item isKindOfClass:[NSString class]] ){
		return YES;
	}
	
	return NO;
}

// return the item name
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item{
	
	// root
	if ( [[item className] isEqualToString:@"NSCFString"] || [item isKindOfClass:[NSString class]] ){
		return item;
	}
	// combat profiles
	else if ( [item isKindOfClass:[CombatProfile class]] ){
		return [(Profile*)item name];
	}
	// mail action profiles
	else if ( [item isKindOfClass:[MailActionProfile class]] ){
		return [(Profile*)item name];
	}
	
	return nil;
}

// this allows us to rename
- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item{
	
	// in theory should always be
	if ( [object isKindOfClass:[NSString class]] ){
		
		if ( [self isValidProfile:item] ){
			
			// only rename if they are different!
			if ( ![object isEqualToString:[(Profile*)item name]] ){
				// delete the old profile
				[fileController deleteObject:item];
				
				// set the name of our profile
				[(Profile*)item setName:object];
				
				// save our profile
				[fileController saveObject:item];
				
				[self updateTitle];
			}
		}
	}
}

// called whenever the selection changes!
- (void)outlineViewSelectionDidChange:(NSNotification *)notification{
	id selectedObject = [self selectedProfile];
	[self setProfile:selectedObject];
}

// do we allow pasting?
- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard{
	return NO;
}

// is this a valid drop target?
- (NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id < NSDraggingInfo >)info proposedItem:(id)item proposedChildIndex:(NSInteger)index{
	
	// no moving (for now)
	return NSDragOperationNone;	  
}

- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id < NSDraggingInfo >)info item:(id)item childIndex:(NSInteger)index{
	return NO;
}

#pragma mark TabView Delgate

- (BOOL)tabView:(NSTabView *)tabView shouldSelectTabViewItem:(NSTabViewItem *)tabViewItem{
	int identifier = [[tabViewItem identifier] intValue];
	
	// trying to click the combat tab with a non-combat profile - NO!!!!
	if ( identifier == TabCombat && !self.currentCombatProfile ){
		return NO;
	}
	// trying to click the mail action tab and no mail action profile
	else if ( identifier == TabMail && !self.currentMailActionProfile ){
		return NO;
	}
	
	return YES;
}

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem{
	_selectedTab = [[tabViewItem identifier] intValue];
}

#pragma mark Combat Profile Editor


//[self populatePlayerLists]; call this when we display the profile!

- (void)populatePlayerList: (id)popUpButton withGUID:(UInt64)guid{
	log(LOG_DEV, @"Populating player list.");

	NSMenu *playerMenu = [[[NSMenu alloc] initWithTitle: @"Player List"] autorelease];
	NSMenuItem *item;

	NSArray *friendlyPlayers = [playersController friendlyPlayers];
	
	if ( [friendlyPlayers count] > 0 ){
		
		[controller traverseNameList];
		
		for(Player *player in friendlyPlayers) {

			NSString *name = [playersController playerNameWithGUID:[player GUID]];
			
			item = [[[NSMenuItem alloc] initWithTitle: [NSString stringWithFormat: @"%@ %@", name, player] action: nil keyEquivalent: @""] autorelease];
			[item setIndentationLevel: 1];
			[item setRepresentedObject: [NSNumber numberWithUnsignedLongLong:[player GUID]]];
			[item setTag:[player GUID]];
			[playerMenu addItem: item];
		}
	}
	else{

		if ( popUpButton == tankPopUpButton && self.currentCombatProfile.tankUnit && self.currentCombatProfile.tankUnitGUID > 0x0 ) {

			NSString *name;
			name = [playersController playerNameWithGUID: self.currentCombatProfile.tankUnitGUID];

			if ( !name || name == @"" ) name = [NSString stringWithFormat: @"Current Tank (0x%qX)", self.currentCombatProfile.tankUnitGUID];
			
			item = [[[NSMenuItem alloc] initWithTitle: name action: nil keyEquivalent: @""] autorelease];
			[item setIndentationLevel: 1];
			[item setRepresentedObject: [NSNumber numberWithUnsignedLongLong:self.currentCombatProfile.tankUnitGUID]];
			[item setTag: self.currentCombatProfile.tankUnitGUID];
			[playerMenu addItem: item];
		}

		if ( popUpButton == assistPopUpButton && self.currentCombatProfile.assistUnit && self.currentCombatProfile.assistUnitGUID > 0x0 ) {
			
			NSString *name;
			name = [playersController playerNameWithGUID: self.currentCombatProfile.assistUnitGUID];

			if ( !name || name == @"" ) name = [NSString stringWithFormat: @"Current Assist (0x%qX)", self.currentCombatProfile.assistUnitGUID];
			
			item = [[[NSMenuItem alloc] initWithTitle: name action: nil keyEquivalent: @""] autorelease];
			[item setIndentationLevel: 1];
			[item setRepresentedObject: [NSNumber numberWithUnsignedLongLong:self.currentCombatProfile.assistUnitGUID]];
			[item setTag: self.currentCombatProfile.assistUnitGUID];
			[playerMenu addItem: item];
		}

		if ( popUpButton == followPopUpButton && self.currentCombatProfile.followUnit && self.currentCombatProfile.followUnitGUID > 0x0 ) {
			
			NSString *name;
			name = [playersController playerNameWithGUID: self.currentCombatProfile.followUnitGUID];

			if ( !name || name == @"" ) name = [NSString stringWithFormat: @"Current Leader (0x%qX)", self.currentCombatProfile.followUnitGUID];

			item = [[[NSMenuItem alloc] initWithTitle: name action: nil keyEquivalent: @""] autorelease];
			[item setIndentationLevel: 1];
			[item setRepresentedObject: [NSNumber numberWithUnsignedLongLong:self.currentCombatProfile.followUnitGUID]];
			[item setTag: self.currentCombatProfile.followUnitGUID];
			[playerMenu addItem: item];
		}
		
		item = [[[NSMenuItem alloc] initWithTitle: [NSString stringWithFormat: @"No Friendly Players Nearby"] action: nil keyEquivalent: @""] autorelease];
		[item setTag: 0];
		[item setIndentationLevel: 1];
		[item setRepresentedObject: nil];
		[playerMenu addItem: item];
	}

	
	[(NSPopUpButton*)popUpButton setMenu:playerMenu];	
	[(NSPopUpButton*)popUpButton selectItemWithTag:guid];
}

// update all 3!
- (void)populatePlayerLists{
	// update the list of names!
	[controller traverseNameList];
	
	// update all 3 lists!
	[self populatePlayerList:tankPopUpButton withGUID:self.currentCombatProfile.tankUnitGUID];
	[self populatePlayerList:assistPopUpButton withGUID:self.currentCombatProfile.assistUnitGUID];
	[self populatePlayerList:followPopUpButton withGUID:self.currentCombatProfile.followUnitGUID];
}

#pragma mark -
#pragma mark Ignore Entries

- (IBAction)addIgnoreEntry: (id)sender {
    if(!self.currentCombatProfile) return;
    
    [self.currentCombatProfile addEntry: [IgnoreEntry entry]];
	[self currentCombatProfile].changed = YES;
    [ignoreTable reloadData];
}

- (IBAction)addIgnoreFromTarget: (id)sender {
    if(!self.currentCombatProfile) return;
    
    Mob *mob = [mobController playerTarget];
    
    if(!mob) {
        NSBeep();
        return;
    }
    
    IgnoreEntry *entry = [IgnoreEntry entry];
    entry.ignoreType = [NSNumber numberWithInt: 0];
    entry.ignoreValue = [NSNumber numberWithInt: [mob entryID]];
    [self.currentCombatProfile addEntry: entry];
	[self currentCombatProfile].changed = YES;
    [ignoreTable reloadData];
}

- (IBAction)deleteIgnoreEntry: (id)sender {
    NSIndexSet *rowIndexes = [ignoreTable selectedRowIndexes];
    if([rowIndexes count] == 0 || ![self currentCombatProfile]) return;
    
    int row = [rowIndexes lastIndex];
    while(row != NSNotFound) {
        [[self currentCombatProfile] removeEntryAtIndex: row];
        row = [rowIndexes indexLessThanIndex: row];
    }
	
    [ignoreTable selectRow: [rowIndexes firstIndex] byExtendingSelection: NO]; 
    
    [ignoreTable reloadData];
	[self currentCombatProfile].changed = YES;
}

#pragma mark TableView Delegate & Datasource

- (int)numberOfRowsInTableView:(NSTableView *)aTableView {
    if ( aTableView == ignoreTable ) {
        return [self.currentCombatProfile entryCount];
    }
    return 0;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
    if(rowIndex == -1) return nil;
    if(aTableView == ignoreTable) {
        if(rowIndex >= [self.currentCombatProfile entryCount]) return nil;
        
        if([[aTableColumn identifier] isEqualToString: @"Type"])
            return [[self.currentCombatProfile entryAtIndex: rowIndex] ignoreType];
        
        if([[aTableColumn identifier] isEqualToString: @"Value"]) {
            return [[self.currentCombatProfile entryAtIndex: rowIndex] ignoreValue];
        }
    }
    
    return nil;
}


- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    if([[aTableColumn identifier] isEqualToString: @"Type"])
        [[self.currentCombatProfile entryAtIndex: rowIndex] setIgnoreType: anObject];
    
    if([[aTableColumn identifier] isEqualToString: @"Value"]) {
        [[self.currentCombatProfile entryAtIndex: rowIndex] setIgnoreValue: anObject];
    }
}



@end