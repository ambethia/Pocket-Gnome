//
//  StatisticsController.m
//  Pocket Gnome
//
//  Created by Josh on 10/12/09.
//  Copyright 2009 Savory Software, LLC. All rights reserved.
//

#import "StatisticsController.h"
#import "Controller.h"
#import "PlayerDataController.h"
#import "LootController.h"
#import "CombatController.h"
#import "BotController.h"
#import "Mob.h"

@interface StatisticsController (Internal)

@end

@implementation StatisticsController
- (id) init{
    self = [super init];
    if (self != nil) {
		_startCopper = -1;
		_lootedItems = -1;
		_mobsKilled = -1;
		_startHonor = -1;
		_mobsKilledDictionary = [[NSMutableDictionary dictionary] retain];
		
		// notifications
		[[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(applicationWillTerminate:) 
                                                     name: NSApplicationWillTerminateNotification 
                                                   object: nil];
        /*[[NSNotificationCenter defaultCenter] addObserver: self
		 selector: @selector(playerIsValid:) 
		 name: PlayerIsValidNotification 
		 object: nil];*/
		[[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(itemLooted:) 
                                                     name: ItemLootedNotification 
                                                   object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(unitDied:) 
                                                     name: UnitDiedNotification 
                                                   object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(botStarted:) 
                                                     name: BotStarted 
                                                   object: nil];
		
		
		
        [NSBundle loadNibNamed: @"Statistics" owner: self];
    }
    return self;
}

- (void) dealloc{
    [super dealloc];
}

- (void)awakeFromNib {
    self.minSectionSize = [self.view frame].size;
    self.maxSectionSize = [self.view frame].size;
	
	float freq = [[NSUserDefaults standardUserDefaults] floatForKey: @"StatisticsUpdateFrequency"];
    if(freq <= 0.0f) freq = 0.35;
    self.updateFrequency = freq;
	
	[self performSelector: @selector(updateStatistics) withObject: nil afterDelay: _updateFrequency];
}

- (void)applicationWillTerminate: (NSNotification*)notification {
    [[NSUserDefaults standardUserDefaults] setFloat: self.updateFrequency forKey: @"StatisticsUpdateFrequency"];
}

@synthesize view;
@synthesize minSectionSize;
@synthesize maxSectionSize;
@synthesize updateFrequency = _updateFrequency;

- (NSString*)sectionTitle {
    return @"Statistics";
}

- (void)updateStatistics{
	
	// only updating if this window is visible!
	if ( ![[memoryOperationsTable window] isVisible] ){
		[self performSelector: @selector(updateStatistics) withObject: nil afterDelay: _updateFrequency];       
		return;
	}
	
	MemoryAccess *memory = [controller wowMemoryAccess];
	
	// update statistics
	if ( memory ){
		
		// memory operations
		[memoryReadsText setStringValue: [NSString stringWithFormat:@"%0.2f", [memory readsPerSecond]]];
		[memoryWritesText setStringValue: [NSString stringWithFormat:@"%0.2f", [memory writesPerSecond]]];
		
		// only if our player is valid
		if ( [playerController playerIsValid:self] ){
			
			// money
			UInt32 currentCopper = [playerController copper];
			if ( _startCopper != currentCopper && _startCopper > -1 ){
				int32_t difference = (currentCopper - _startCopper);
				
				// lets make it pretty!
				int silver = difference % 100;
				difference /= 100;
				int copper = difference % 100;
				difference /= 100;
				int gold = difference;
				
				[moneyText setStringValue: [NSString stringWithFormat:@"%dg %ds %dc", gold, copper, silver]];
			}
			
			// honor
			UInt32 currentHonor = [playerController honor];
			if ( currentHonor != _startHonor && _startHonor > -1 ){
				int32_t difference = (currentHonor - _startHonor);
				[honorGainedText setStringValue: [NSString stringWithFormat:@"%d", difference]];
			}
			
			if ( _lootedItems > -1 ) [itemsLootedText setStringValue: [NSString stringWithFormat:@"%d", _lootedItems]];
			if ( _mobsKilled > -1 ) [mobsKilledText setStringValue: [NSString stringWithFormat:@"%d", _mobsKilled]];
		}
		
		// refresh our memory operations table
		[memoryOperationsTable reloadData];
	}
	
	[self performSelector: @selector(updateStatistics) withObject: nil afterDelay: _updateFrequency];       
}

#pragma mark Interface Actions

- (IBAction)resetStatistics:(id)sender{
	
	_startCopper = [playerController copper];
	_startHonor = [playerController honor];
	_lootedItems = 0;
	_mobsKilled = 0;
	
	// reset memory data
	MemoryAccess *memory = [controller wowMemoryAccess];
	if ( memory ){
		[memory resetCounters];
	}
}

- (void)resetQuestMobCount{
	[_mobsKilledDictionary removeAllObjects];
}

- (int)killCountForEntryID:(int)entryID{
	NSNumber *mobID = [NSNumber numberWithUnsignedLong:entryID];
	NSNumber *count = [_mobsKilledDictionary objectForKey:mobID];
	
	if ( count )
		return [count intValue];
	return 0;
}

#pragma mark Notifications

- (void)botStarted: (NSNotification*)notification {
	[self resetStatistics:nil];
}

/*- (void)playerIsValid: (NSNotification*)notification {
 }*/

- (void)itemLooted: (NSNotification*)notification {
	_lootedItems++;
}

- (void)unitDied: (NSNotification*)notification {
	
	id obj = [notification object];
	
	_mobsKilled++;
	
	// incremement
	int count = 1;
	if ( [obj isKindOfClass:[Mob class]] ){
		
		NSNumber *entryID = [NSNumber numberWithInt:[(Mob*)obj entryID]];
		if ( [_mobsKilledDictionary objectForKey:entryID] ){
			count = [[_mobsKilledDictionary objectForKey:entryID] intValue] + 1;
		}
		
		[_mobsKilledDictionary setObject:[NSNumber numberWithInt:count] forKey:entryID];
	}
	
	//PGLog(@"[**********] Unit killed: %@ %d times", obj, count);
}

#pragma mark -
#pragma mark TableView Delegate & Datasource

- (void)tableView:(NSTableView *)aTableView sortDescriptorsDidChange:(NSArray *)oldDescriptors {
	[aTableView reloadData];
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView {
	
	if ( aTableView == memoryOperationsTable ){
		MemoryAccess *memory = [controller wowMemoryAccess];
		
		if ( memory && [memory isValid] ){
			return [[memory operationsByClassPerSecond] count];
		}
	}
	
	return 0;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
	
	if ( aTableView == memoryOperationsTable ){
		MemoryAccess *memory = [controller wowMemoryAccess];
		
		if ( memory && [memory isValid] ){
			NSDictionary *classOperations = [memory operationsByClassPerSecond];
			
			if(rowIndex == -1 || rowIndex >= [classOperations count]) return nil;
			
			NSArray *keys = [classOperations allKeys];
			
			// class
			if ( [[aTableColumn identifier] isEqualToString:@"Class"] ){
				return [keys objectAtIndex:rowIndex];
			}
			// value
			else if ( [[aTableColumn identifier] isEqualToString:@"Operations"] ){
				return [classOperations objectForKey:[keys objectAtIndex:rowIndex]];
			}
		}
	}
	return nil;
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    return NO;
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectTableColumn:(NSTableColumn *)aTableColumn {
    return YES;
}

@end
