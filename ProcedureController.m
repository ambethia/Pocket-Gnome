//
//  ProcedureController.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 1/4/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import "ProcedureController.h"
#import "SpellController.h"
#import "InventoryController.h"
#import "RuleEditor.h"
#import "Rule.h"
#import "FileController.h"

#import "FileObject.h"

#import "BetterSegmentedControl.h"

@implementation ProcedureController

- (id) init
{
    self = [super init];
    if (self != nil) {
		
		_behaviors = [[NSMutableArray array] retain];
		
		if ( fileController == nil ){
			fileController = [[FileController sharedFileController] retain];
		}
		
		// get behaviors
		NSArray *behaviors = [fileController getObjectsWithClass:[Behavior class]];
		[_behaviors addObjectsFromArray:behaviors];
		
        _behavior = nil;
		_nameBeforeRename = nil;

        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(applicationWillTerminate:) name: NSApplicationWillTerminateNotification object: nil];
        
        [NSBundle loadNibNamed: @"Behaviors" owner: self];
    }
    return self;
}

- (void)awakeFromNib {
    
    self.minSectionSize = [self.view frame].size;
    self.maxSectionSize = NSZeroSize;

    [ruleTable registerForDraggedTypes: [NSArray arrayWithObjects: @"RuleIndexesType", @"RuleArrayType", nil]];
    
    [ruleTable setDoubleAction: @selector(tableRowDoubleClicked:)];
    [ruleTable setTarget: self];
    
    if( !_behavior && [_behaviors count]) {
        [self setCurrentBehavior: [_behaviors objectAtIndex: 0]];
        [ruleTable reloadData];
    }
}

@synthesize view;
@synthesize minSectionSize;
@synthesize maxSectionSize;

- (NSString*)sectionTitle {
    return @"Behaviors & Procedures";
}

- (void)applicationWillTerminate: (NSNotification*)notification {
	NSMutableArray *objectsToSave = [NSMutableArray array];
	for ( FileObject *obj in _behaviors ){
		if ( [obj changed] ){
			[objectsToSave addObject:obj];
		}
	}
	
    [fileController saveObjects:objectsToSave];
	
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"Behaviors"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark -

@synthesize validSelection;

- (void)validateBindings {
    [self willChangeValueForKey: @"currentProcedure"];
    [self didChangeValueForKey: @"currentProcedure"];
    
    self.validSelection = [ruleTable numberOfSelectedRows] ? YES : NO;
}

- (NSString*)currentProcedureKey {
    if( [procedureEventSegment selectedTag] == 1 )
        return PreCombatProcedure;
    if( [procedureEventSegment selectedTag] == 2 )
        return CombatProcedure;
    if( [procedureEventSegment selectedTag] == 3 )
        return PostCombatProcedure;
    if( [procedureEventSegment selectedTag] == 4 )
        return RegenProcedure;
    if( [procedureEventSegment selectedTag] == 5 )
        return PatrollingProcedure;
    return @"";
}

- (NSArray*)behaviors {
    return [[_behaviors retain] autorelease];
}

- (Behavior*)currentBehavior {
    return [[_behavior retain] autorelease];
}

- (Procedure*)currentProcedure {
    return [[self currentBehavior] procedureForKey: [self currentProcedureKey]];
}

- (void)setCurrentBehavior: (Behavior*)behavior {
    
    [_behavior autorelease];
    _behavior = [behavior retain];
  // Let's just leave this at what ever was previously selected  
//    [procedureEventSegment selectSegmentWithTag: 1];
    [self validateBindings];
}

#pragma mark Protocol Actions

- (void)addBehavior: (Behavior*)behavior {
	
    int num = 2;
    BOOL done = NO;
    if(![behavior isKindOfClass: [Behavior class]]) return;
    if(![[behavior name] length]) return;
    
    // check to see if a route exists with this name
    NSString *originalName = [behavior name];
    while(!done) {
        BOOL conflict = NO;
        for(Behavior *oldBehavior in self.behaviors) {
            if( [[oldBehavior name] isEqualToString: [behavior name]]) {
                [behavior setName: [NSString stringWithFormat: @"%@ %d", originalName, num++]];
                conflict = YES;
                break;
            }
        }
        if(!conflict) done = YES;
    }
	
    // save this route into our array
    [self willChangeValueForKey: @"behaviors"];
    [_behaviors addObject: behavior];
    [self didChangeValueForKey: @"behaviors"];
	
	// save our new behavior
	[fileController saveObject: behavior];

    // update the current procedure
    [self setCurrentBehavior: behavior];

    [ruleTable reloadData];
    
    //log(LOG_GENERAL, @"Added behavior: %@", [behavior name]);
}

- (IBAction)createBehavior: (id)sender {
    // make sure we have a valid name
    NSString *behaviorName = [sender stringValue];
    if( [behaviorName length] == 0) {
        NSBeep();
        return;
    }

    // create a new behavior
    [self addBehavior: [Behavior behaviorWithName: behaviorName]];
    [sender setStringValue: @""];
}

- (IBAction)loadBehavior: (id)sender {
    [self validateBindings];
    [ruleTable reloadData];
}

- (IBAction)setBehaviorEvent: (id)sender {
    [self validateBindings];
    [ruleTable reloadData];
	
	// combat tab selected
	if ( [procedureEventSegment selectedTag] == 2 ){
		[combatPriorityTextField setHidden:NO];
	}
	else{
		[combatPriorityTextField setHidden:YES];
	}
}

- (IBAction)removeBehavior: (id)sender {
    if([self currentBehavior]) {
        int ret = NSRunAlertPanel(@"Delete Behavior?", [NSString stringWithFormat: @"Are you sure you want to delete the behavior \"%@\"?", [[self currentBehavior] name]], @"Delete", @"Cancel", NULL);
        if(ret == NSAlertDefaultReturn) {
            [self willChangeValueForKey: @"behaviors"];
			
			// delete the object
			[fileController deleteObject:[self currentBehavior]];
			
			// remove frm the list
			[_behaviors removeObject: [self currentBehavior]];
			
            if([self.behaviors count])
                [self setCurrentBehavior: [self.behaviors objectAtIndex: 0]];
            else
                [self setCurrentBehavior: nil];
            
            [self didChangeValueForKey: @"behaviors"];
            [ruleTable reloadData];
        }
    }
}

- (IBAction)duplicateBehavior: (id)sender {
    [self addBehavior: [self.currentBehavior copy]];
}

- (IBAction)renameBehavior: (id)sender {
	
	_nameBeforeRename = [[[self currentBehavior] name] copy];
	
	[NSApp beginSheet: renamePanel
	   modalForWindow: [self.view window]
		modalDelegate: nil
	   didEndSelector: nil //@selector(sheetDidEnd: returnCode: contextInfo:)
		  contextInfo: nil];
}

- (IBAction)closeRename: (id)sender {
    [[sender window] makeFirstResponder: [[sender window] contentView]];
    [NSApp endSheet: renamePanel returnCode: 1];
    [renamePanel orderOut: nil];
    
	// did the name change?
	if ( ![_nameBeforeRename isEqualToString:[[self currentBehavior] name]] ){
		
		// delete the old behavior
		[fileController deleteObjectWithFilename:[NSString stringWithFormat:@"%@.behavior", _nameBeforeRename]];
		
		// save the new one
		[fileController saveObject:[self currentBehavior]];
	}
}

#pragma mark Rule Actions

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	
    if ( returnCode == RuleEditorSaveRule ) {
        Rule *rule = [ruleEditor rule];
        
        if( (Rule*)contextInfo ) {
            // we are editing (replacing) a rule
            //log(LOG_GENERAL, @"Replacing with rule: %@", rule);
            [[self currentProcedure] replaceRuleAtIndex: [ruleTable selectedRow] withRule: rule];
        } else {
            // we are adding a rule
            //log(LOG_GENERAL, @"Adding new rule: %@", rule);
            [[self currentProcedure] addRule: rule];
        }
        
        [ruleTable reloadData];
		
		// mark this behavior as changed!
		[[self currentBehavior] setChanged:YES];
    }
}

- (IBAction)addRule: (id)sender {
    if( ![self currentProcedure]) return;
    
    [ruleEditor initiateEditorForRule: nil];
    
	[NSApp beginSheet: [ruleEditor window]
	   modalForWindow: [ruleTable window]
		modalDelegate: self
	   didEndSelector: @selector(sheetDidEnd: returnCode: contextInfo:)
		  contextInfo: nil];
}

- (IBAction)deleteRule: (id)sender {
    int row = [ruleTable selectedRow];
    if( row == -1 || ![self currentProcedure]) return;
    
    [[self currentProcedure] removeRuleAtIndex: row];
    [ruleTable reloadData];
	[[self currentBehavior] setChanged:YES];
}

- (IBAction)showInFinder: (id)sender{
	[fileController showInFinder:[self currentBehavior]];
}

#pragma mark -
#pragma mark Import & Export

- (BOOL)behaviorsContainMacros: (NSArray*)behaviors {
    // search for macros
    for(Behavior *behavior in behaviors) {
        for(Rule *rule in [[behavior procedureForKey: PreCombatProcedure] rules]) {
            if( [rule resultType] == ActionType_Macro ) {
                return YES;
            }
        }
        for(Rule *rule in [[behavior procedureForKey: CombatProcedure] rules]) {
            if( [rule resultType] == ActionType_Macro ) {
                return YES;
            }
        }
        for(Rule *rule in [[behavior procedureForKey: PostCombatProcedure] rules]) {
            if( [rule resultType] == ActionType_Macro ) {
                return YES;
            }
        }
        for(Rule *rule in [[behavior procedureForKey: RegenProcedure] rules]) {
            if( [rule resultType] == ActionType_Macro ) {
                return YES;
            }
        }
        for(Rule *rule in [[behavior procedureForKey: PatrollingProcedure] rules]) {
            if( [rule resultType] == ActionType_Macro ) {
                return YES;
            }
        }
    }
    return NO;
}

- (void)importBehaviorAtPath: (NSString*)path {
    id importedBehavior;
    NS_DURING {
        importedBehavior = [NSKeyedUnarchiver unarchiveObjectWithFile: path];
    } NS_HANDLER {
        importedBehavior = nil;
    } NS_ENDHANDLER
    
    if(importedBehavior) {
        BOOL containsMacros = NO;
        if([importedBehavior isKindOfClass: [Behavior class]]) {
            containsMacros = [self behaviorsContainMacros: [NSArray arrayWithObject: importedBehavior]];
        } else if([importedBehavior isKindOfClass: [NSArray class]]) {
            containsMacros = [self behaviorsContainMacros: importedBehavior];
        } else {
            importedBehavior = nil;
        }
        
        if(importedBehavior) {
            // let the user know if there are macros
            int ret = NSAlertDefaultReturn;
            if(containsMacros) {
                NSBeep();
                ret = NSRunCriticalAlertPanel(@"Warning: Macros Detected",  [NSString stringWithFormat: @"The behavior file \"%@\" contains one or more rules that utilize WoW macros.  Since these macros are specific to each copy of WoW, this behavior will most likely not function unless you manually fix each of the affected rules.  Do you still want to import this file?", [path lastPathComponent]], @"Import", @"Cancel", NULL);
            }
            
            if(ret == NSAlertDefaultReturn) {
                if([importedBehavior isKindOfClass: [Behavior class]]) {
                    [self addBehavior: importedBehavior];
                } else if([importedBehavior isKindOfClass: [NSArray class]]) {
                    for(Behavior *behavior in importedBehavior) {
                        [self addBehavior: behavior];
                    }
                }
            }
        }
    }
    
    if(!importedBehavior) {
        NSRunAlertPanel(@"Behavior not Valid", [NSString stringWithFormat: @"The file at %@ cannot be imported because it does not contain a valid behavior or behavior set.", path], @"Okay", NULL, NULL);
    }
}

- (IBAction)importBehavior: (id)sender {
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];

	[openPanel setCanChooseDirectories: NO];
	[openPanel setCanCreateDirectories: NO];
	[openPanel setPrompt: @"Import Behavior"];
	[openPanel setCanChooseFiles: YES];
    [openPanel setAllowsMultipleSelection: YES];
	
	int ret = [openPanel runModalForTypes: [NSArray arrayWithObjects: @"behavior", @"behaviorset", nil]];
    
	if(ret == NSFileHandlingPanelOKButton) {
        for(NSString *behaviorPath in [openPanel filenames]) {
            [self importBehaviorAtPath: behaviorPath];
        }
	}
}

- (IBAction)exportBehavior: (id)sender {
    if(![self currentBehavior]) return;
    
    // let the user know if this behavior contains macros
    if([self behaviorsContainMacros: [NSArray arrayWithObject: [self currentBehavior]]]) {
        NSBeep();
        NSRunCriticalAlertPanel(@"Warning: Behavior Contains Macros", @"The behavior you are exporting contains one or more rules that utilize macros.  Macros are contained within your local copy of Warcraft, and will not be exported with this behavior -- these rules will not work on anybody else's computer!", @"Okay", NULL, NULL);
    }
       
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setCanCreateDirectories: YES];
    [savePanel setTitle: @"Export Behavior"];
    [savePanel setMessage: @"Please choose a destination for this behavior."];
    int ret = [savePanel runModalForDirectory: @"~/Desktop" file: [[[self currentBehavior] name] stringByAppendingPathExtension: @"behavior"]];
    
	if(ret == NSFileHandlingPanelOKButton) {
        NSString *saveLocation = [savePanel filename];
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject: [self currentBehavior]];
        [data writeToFile: saveLocation atomically: YES];
    }
}

#pragma mark -
#pragma mark NSTableView Delesource

- (IBAction)tableRowDoubleClicked: (id)sender {
    
    int row = [ruleTable selectedRow];
    if( row == -1 || ![self currentProcedure]) return;
    
    Rule *ruleToEdit = [[self currentProcedure] ruleAtIndex: row];
    [ruleEditor initiateEditorForRule: ruleToEdit];
    
	[NSApp beginSheet: [ruleEditor window]
	   modalForWindow: [ruleTable window]
		modalDelegate: self
	   didEndSelector: @selector(sheetDidEnd: returnCode: contextInfo:)
		  contextInfo: ruleToEdit];
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [[self currentProcedure] ruleCount];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
    if(rowIndex == -1) return nil;
    
    if( [[aTableColumn identifier] isEqualToString: @"Order"] ) {
        return [NSNumber numberWithInt: rowIndex+1];
    }
    if( [[aTableColumn identifier] isEqualToString: @"Name"] ) {
        Rule *rule = [[self currentProcedure] ruleAtIndex: rowIndex];
        return [rule name];
    }
    if( [[aTableColumn identifier] isEqualToString: @"Action"] ) {
        Rule *rule = [[self currentProcedure] ruleAtIndex: rowIndex];
        if([rule actionID]) {
            NSNumber *actionID = [NSNumber numberWithInt: [rule actionID]];
            if([rule resultType] == ActionType_Spell) {
                if([[spellController spellForID: actionID] fullName])
                    return [NSString stringWithFormat: @"Ability: %@", [[spellController spellForID: actionID] fullName]];
                else
                    return [NSString stringWithFormat: @"Ability: %@", actionID];
            }
            if([rule resultType] == ActionType_Item)
                return [NSString stringWithFormat: @"Item: %@", [itemController nameForID: actionID]];
            if([rule resultType] == ActionType_Macro)
                return [NSString stringWithFormat: @"Macro: %d", [rule actionID]];
        }
        return @"No action";
    }
    
    return nil;
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    return NO;
}

- (void)tableView: (NSTableView*)tableView deleteKeyPressedOnRowIndexes: (NSIndexSet*)rowIndexes {
    [self deleteRule: nil];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
    [self validateBindings];
}


- (BOOL)tableViewCopy: (NSTableView*)tableView {
    NSIndexSet *selectedRows = [tableView selectedRowIndexes];
    
    if([selectedRows count] == 0) {
        return NO;
    }
    
    NSMutableArray *rulesToCopy = [NSMutableArray array];
    NSMutableString *rulesDescription = [NSMutableString string];
    int row = [selectedRows firstIndex];
    while(row != NSNotFound) {
        if([[self currentProcedure] ruleAtIndex: row]) {
            Rule *rule = [[self currentProcedure] ruleAtIndex: row];
            // log(LOG_GENERAL, @"Copy rule: %@, (0x%X)", rule, &rule);
            [rulesToCopy addObject: rule];
            if(row == [selectedRows lastIndex]) [rulesDescription appendString: [rule description]];
            else                                [rulesDescription appendFormat: @"%@\n", [rule description]];
        }
        row = [selectedRows indexGreaterThanIndex: row];
    }
    
    if( [rulesToCopy count]) {
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject: rulesToCopy];
        if(data) {
            NSPasteboard *ruleBoard = [NSPasteboard generalPasteboard];
            [ruleBoard declareTypes: [NSArray arrayWithObjects: NSStringPboardType, @"RuleArrayType", nil] owner: self];
            [ruleBoard setData: data forType: @"RuleArrayType"];
            [ruleBoard setString: rulesDescription forType: NSStringPboardType];
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)tableViewPaste: (NSTableView*)tableView {
    
    NSPasteboard *ruleBoard = [NSPasteboard generalPasteboard];
    NSData *data = [ruleBoard dataForType: @"RuleArrayType"];
    if(data) {
        NSArray *copiedRules = [NSKeyedUnarchiver unarchiveObjectWithData: data];
        if( [copiedRules count] && [self currentProcedure] ) {
            // determine which row to paste
            int pasteRow = [tableView selectedRow];
            if(pasteRow < 0)    pasteRow = [[self currentProcedure] ruleCount];
            else                pasteRow++;
            
            for(Rule *rule in copiedRules) {
                // log(LOG_GENERAL, @"Pasting rule: %@ (0x%X)", rule, &rule);
                [[self currentProcedure] insertRule: rule atIndex: pasteRow];
            }
            
            [tableView reloadData];
            [tableView selectRowIndexes: [NSIndexSet indexSetWithIndexesInRange: NSMakeRange(pasteRow, [copiedRules count])] byExtendingSelection: NO];

            [[self currentBehavior] setChanged:YES];
            return YES;
        }
    }
    return NO;
}

- (BOOL)tableViewCut: (NSTableView*)tableView {
    if( [self tableViewCopy: tableView] ) {
        [self deleteRule: nil];
		[[self currentBehavior] setChanged:YES];
        return YES;
    }
    return NO;
}

#pragma mark Table Drag & Drop

// begin drag operation, save row index
- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard {
    // Copy the row numbers to the pasteboard.
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
    [pboard declareTypes: [NSArray arrayWithObjects: @"RuleIndexesType", nil] owner: self];
    [pboard setData: data forType: @"RuleIndexesType"];
    return YES;
}

// validate drag operation
- (NSDragOperation) tableView: (NSTableView*) tableView
                 validateDrop: (id ) info
                  proposedRow: (int) row
        proposedDropOperation: (NSTableViewDropOperation) op
{
    int result = NSDragOperationNone;
    
    if (op == NSTableViewDropAbove) {
        result = NSDragOperationMove;
        
        NSPasteboard* pboard = [info draggingPasteboard];
        NSData* rowData = [pboard dataForType: @"RuleIndexesType"];
        NSIndexSet* rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];
        int dragRow = [rowIndexes firstIndex];
        
        if(dragRow == row || dragRow == row-1) {
            result = NSDragOperationNone;
        }
    }
    
    return (result);
    
}

// accept the drop
- (BOOL)tableView: (NSTableView *)aTableView 
       acceptDrop: (id <NSDraggingInfo>)info
              row: (int)row 
    dropOperation: (NSTableViewDropOperation)operation {
    
    NSPasteboard* pboard = [info draggingPasteboard];
    NSData* rowData = [pboard dataForType: @"RuleIndexesType"];
    NSIndexSet* rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];
    int dragRow = [rowIndexes firstIndex];
    
    if(dragRow < row) row--;
    //log(LOG_GENERAL, @"Got drag for row %d to row %d", dragRow, row);
    
    // Move the specified row to its new location...
    Rule *dragRule = [[self currentProcedure] ruleAtIndex: dragRow];
    [[self currentProcedure] removeRuleAtIndex: dragRow];
    [[self currentProcedure] insertRule: dragRule atIndex: row];
    
    [aTableView reloadData];
	
	[[self currentBehavior] setChanged:YES];
    
    return YES;
}

@end
