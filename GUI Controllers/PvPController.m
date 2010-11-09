//
//  PvPController.h
//  Pocket Gnome
//
//  Created by Josh on 2/24/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "PvPController.h"
#import "FileController.h"
#import "PvPBehavior.h"
#import "Battleground.h"

#import "FileObject.h"

#import "RouteCollection.h"

#import "WaypointController.h"

@interface PvPController ()
//@property (readwrite, retain) PvPBehavior *currentBehavior;
@end

@interface PvPController (internal)
- (void)validateBindings;
- (void)loadCorrectRouteCollection: (Battleground*)bg;
@end

@implementation PvPController

- (id) init{
    self = [super init];
    if ( self != nil ){
		
		_behaviors = [[NSMutableArray array] retain];
		
		_currentBehavior = nil;
		
		_nameBeforeRename = nil;
		
		if ( fileController == nil ){
			fileController = [[FileController sharedFileController] retain];
		}
		
		// get behaviors
		NSArray *pvpBehaviors = [fileController getObjectsWithClass:[PvPBehavior class]];
		[_behaviors addObjectsFromArray:pvpBehaviors];
		
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(applicationWillTerminate:) name: NSApplicationWillTerminateNotification object: nil];
		
        [NSBundle loadNibNamed: @"PvP" owner: self];
    }
    return self;
}

- (void) dealloc{
    [super dealloc];
}

- (void)awakeFromNib {
    self.minSectionSize = [self.view frame].size;
    self.maxSectionSize = [self.view frame].size;
	
	// delay setting our current behavior (as the route objects might not have loaded yet)
	[self performSelector:@selector(initCurrentRoute) withObject:nil afterDelay:0.5f];
}

- (void)initCurrentRoute{
	if ( [self.behaviors count] > 0 ){
		self.currentBehavior = [self.behaviors objectAtIndex:0];
	}
}

@synthesize view;
@synthesize minSectionSize;
@synthesize maxSectionSize;
@synthesize currentBehavior = _currentBehavior;
@synthesize behaviors = _behaviors;

- (NSString*)sectionTitle {
    return @"PvP";
}

- (void)applicationWillTerminate: (NSNotification*)notification {
	
	NSMutableArray *objectsToSave = [NSMutableArray array];
	for ( FileObject *obj in _behaviors ){
		if ( [obj changed] ){
			[objectsToSave addObject:obj];
		}
	}
	
    [fileController saveObjects:objectsToSave];
}

#pragma mark -

- (void)setCurrentBehavior: (PvPBehavior*)behavior {
    
    [_currentBehavior autorelease];
    _currentBehavior = [behavior retain];
    
    //[procedureEventSegment selectSegmentWithTag: 1];
    [self validateBindings];
}

// this will choose the correct route collection
- (void)validateBindings{
	
	//[self willChangeValueForKey: @"currentBehavior"];
    //[self didChangeValueForKey: @"currentBehavior"];
	
	// assign default routes so it's not "No Value"
	if ( self.currentBehavior.AlteracValley.routeCollection == nil )
		self.currentBehavior.AlteracValley.routeCollection = [[waypointController routeCollections] objectAtIndex:0];
	if ( self.currentBehavior.ArathiBasin.routeCollection == nil )
		self.currentBehavior.ArathiBasin.routeCollection = [[waypointController routeCollections] objectAtIndex:0];
	if ( self.currentBehavior.EyeOfTheStorm.routeCollection == nil )
		self.currentBehavior.EyeOfTheStorm.routeCollection = [[waypointController routeCollections] objectAtIndex:0];
	if ( self.currentBehavior.IsleOfConquest.routeCollection == nil )
		self.currentBehavior.IsleOfConquest.routeCollection = [[waypointController routeCollections] objectAtIndex:0];
	if ( self.currentBehavior.StrandOfTheAncients.routeCollection == nil )
		self.currentBehavior.StrandOfTheAncients.routeCollection = [[waypointController routeCollections] objectAtIndex:0];
	if ( self.currentBehavior.WarsongGulch.routeCollection == nil )
		self.currentBehavior.WarsongGulch.routeCollection = [[waypointController routeCollections] objectAtIndex:0];
	
	// select the correct route
	[self loadCorrectRouteCollection:self.currentBehavior.AlteracValley];
	[self loadCorrectRouteCollection:self.currentBehavior.ArathiBasin];
	[self loadCorrectRouteCollection:self.currentBehavior.EyeOfTheStorm];
	[self loadCorrectRouteCollection:self.currentBehavior.IsleOfConquest];
	[self loadCorrectRouteCollection:self.currentBehavior.StrandOfTheAncients];
	[self loadCorrectRouteCollection:self.currentBehavior.WarsongGulch];
}

- (BOOL)validBehavior{
	if ( _currentBehavior )
		return YES;
	return NO;
}

- (void)loadCorrectRouteCollection: (Battleground*)bg{
	
	RouteCollection *newRC = [waypointController routeCollectionForUUID:[bg.routeCollection UUID]];
	
	// found a new one
	if ( newRC ){
		//log(LOG_GENERAL, @"[PvP] Found route collection for %@, 0x%X vs. 0x%X", bg, bg.routeCollection, newRC);
		bg.routeCollection = newRC;
	}
	else{
		log(LOG_GENERAL, @"[PvP] Didn't find for %@? %@", bg, bg.routeCollection);
		bg.routeCollection = nil;
	}
}

#pragma mark Protocol Actions

- (void)addBehavior: (PvPBehavior*)behavior {
	
    int num = 2;
    BOOL done = NO;
    if(![behavior isKindOfClass: [PvPBehavior class]]) return;
    if(![[behavior name] length]) return;
    
    // check to see if a route exists with this name
    NSString *originalName = [behavior name];
    while(!done) {
        BOOL conflict = NO;
        for ( PvPBehavior *oldBehavior in self.behaviors ) {
            if( [[oldBehavior name] isEqualToString: [behavior name]]) {
                [behavior setName: [NSString stringWithFormat: @"%@ %d", originalName, num++]];
                conflict = YES;
                break;
            }
        }
        if ( !conflict ) done = YES;
    } 
    
    // save this route into our array
    [self willChangeValueForKey: @"behaviors"];
	[self willChangeValueForKey: @"validBehavior"];
    [_behaviors addObject: behavior];
    [self didChangeValueForKey: @"behaviors"];
	[self didChangeValueForKey: @"validBehavior"];
	
	// save this behavior
	[fileController saveObject:behavior];
	
    // update the current procedure
    [self setCurrentBehavior: behavior];
	
	[self validateBindings];
	
    //[ruleTable reloadData];
    
    log(LOG_GENERAL, @"Added behavior: %@", [behavior name]);
}

#pragma mark UI

- (IBAction)createBehavior: (id)sender{
	
	// make sure we have a valid name
    NSString *behaviorName = [sender stringValue];
    if ( [behaviorName length] == 0 ) {
        NSBeep();
        return;
    }
    
    // create a new route
    [self addBehavior: [PvPBehavior pvpBehaviorWithName: behaviorName]];
    [sender setStringValue: @""];
}

- (IBAction)renameBehavior: (id)sender{
	
	_nameBeforeRename = [[[self currentBehavior] name] copy];
	
	[NSApp beginSheet: renamePanel
	   modalForWindow: [self.view window]
		modalDelegate: nil
	   didEndSelector: nil
		  contextInfo: nil];
}

- (IBAction)closeRename: (id)sender {
    [[sender window] makeFirstResponder: [[sender window] contentView]];
    [NSApp endSheet: renamePanel returnCode: 1];
    [renamePanel orderOut: nil];
	
	// did the name change?
	if ( ![_nameBeforeRename isEqualToString:[[self currentBehavior] name]] ){
		// delete the old object
		[fileController deleteObjectWithFilename:[NSString stringWithFormat:@"%@.pvpbehavior", _nameBeforeRename]];
		
		// save the new one
		[fileController saveObject:[self currentBehavior]];
	}
}

- (IBAction)duplicateBehavior: (id)sender{
	[self addBehavior: [self.currentBehavior copy]];
}

- (IBAction)deleteBehavior: (id)sender{
	
	// we have a behavior
	if ( [self currentBehavior] ){
        
        int ret = NSRunAlertPanel(@"Delete Behavior?", [NSString stringWithFormat: @"Are you sure you want to delete the PvP behavior \"%@\"?", [[self currentBehavior] name]], @"Delete", @"Cancel", NULL);
        if ( ret == NSAlertDefaultReturn ){
            [self willChangeValueForKey: @"behaviors"];
			
			// delete the object
			[fileController deleteObject:[self currentBehavior]];
			
			// remove from list
			[_behaviors removeObject: [self currentBehavior]];
            
			// select a new one
            if ( [self.behaviors count] )
                [self setCurrentBehavior: [self.behaviors objectAtIndex: 0]];
            else
                [self setCurrentBehavior: nil];
            
            [self didChangeValueForKey: @"behaviors"];
        }
    }
}

- (IBAction)showInFinder: (id)sender{
	[fileController showInFinder:[self currentBehavior]];
}

- (IBAction)saveAllObjects: (id)sender{
	[fileController saveObjects:_behaviors];
}

- (void)importBehaviorAtPath: (NSString*)path{
    id importedBehavior;
    NS_DURING {
        importedBehavior = [NSKeyedUnarchiver unarchiveObjectWithFile: path];
    } NS_HANDLER {
        importedBehavior = nil;
    } NS_ENDHANDLER
    
	// we have a valid behavior!
    if ( importedBehavior ){
		if ( [importedBehavior isKindOfClass: [PvPBehavior class]] ){
			[self addBehavior: importedBehavior];
		}
		else{
			log(LOG_GENERAL, @"[PvP] Error on importing behavior, object %@", importedBehavior);
		}
    }
    
    if(!importedBehavior) {
        NSRunAlertPanel(@"Behavior not Valid", [NSString stringWithFormat: @"The file at %@ cannot be imported because it does not contain a valid behavior or behavior set.", path], @"Okay", NULL, NULL);
    }
}

- (IBAction)importBehavior: (id)sender{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	
	[openPanel setCanChooseDirectories: NO];
	[openPanel setCanCreateDirectories: NO];
	[openPanel setPrompt: @"Import PvP Behavior"];
	[openPanel setCanChooseFiles: YES];
    [openPanel setAllowsMultipleSelection: YES];
	
	int ret = [openPanel runModalForTypes: [NSArray arrayWithObjects: @"pvpbehavior", nil]];
    
	if ( ret == NSFileHandlingPanelOKButton ){
        for ( NSString *behaviorPath in [openPanel filenames] ){
            [self importBehaviorAtPath: behaviorPath];
        }
	}
}

- (IBAction)exportBehavior: (id)sender {
    if ( ![self currentBehavior] ) return;
    
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setCanCreateDirectories: YES];
    [savePanel setTitle: @"Export Behavior"];
    [savePanel setMessage: @"Please choose a destination for this PvP behavior."];
    int ret = [savePanel runModalForDirectory: @"~/Desktop" file: [[[self currentBehavior] name] stringByAppendingPathExtension: @"pvpbehavior"]];
    
	if ( ret == NSFileHandlingPanelOKButton ) {
        NSString *saveLocation = [savePanel filename];
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject: [self currentBehavior]];
        [data writeToFile: saveLocation atomically: YES];
    }
}

- (IBAction)test: (id)sender{
	
	for ( PvPBehavior *behavior in self.behaviors ){
		
		log(LOG_GENERAL, @"%@ %d 0x%X", behavior, [behavior changed], behavior);
		
		if ( behavior.changed ){
			log(LOG_GENERAL, @"[PvP] Saving %@ 0x%X", behavior, behavior);
			
			[behavior setChanged:NO];
			
			//saveObject
		}
	}
}

@end
