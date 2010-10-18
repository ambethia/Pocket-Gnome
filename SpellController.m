//
//  SpellController.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 12/20/07.
//  Copyright 2007 Savory Software, LLC. All rights reserved.
//

#import <ScreenSaver/ScreenSaver.h>

#import "SpellController.h"
#import "Controller.h"
#import "Offsets.h"
#import "Spell.h"
#import "PlayerDataController.h"
#import "OffsetController.h"
#import "MacroController.h"
#import "InventoryController.h"
#import "BotController.h"

#import "Behavior.h"

#pragma mark Note: LastSpellCast/Timer Disabled
#pragma mark -

/*
 #define CD_NEXT_ADDRESS	0x4
 #define CD_SPELLID		0x8
 #define CD_COOLDOWN		0x14
 #define CD_COOLDOWN2	0x20
 #define CD_ENABLED		0x24
 #define CD_STARTTIME	0x1C	// Also 0x10
 #define CD_GCD			0x2C	// Also 0x2C
 */
typedef struct WoWCooldown {
	UInt32 unk;					// 0x0
	UInt32 nextObjectAddress;	// 0x4
	UInt32 spellID;				// 0x8
	UInt32 unk3;				// 0xC (always 0 when the spell is a player spell)
	UInt32 startTime;			// 0x10 (start time of the spell, stored in milliseconds)
	long cooldown;				// 0x14
	UInt32 unk4;				// 0x18
	UInt32 startNotUsed;		// 0x1C	(the same as 0x10 always I believe?)
	long cooldown2;				// 0x20
	UInt32 enabled;				// 0x24 (0 if spell is enabled, 1 if it's not)
	UInt32 unk5;				// 0x28
	UInt32 gcd;					// 0x2C
} WoWCooldown;

@interface SpellController (Internal)
- (void)buildSpellMenu;
- (void)synchronizeSpells;
- (NSArray*)mountsBySpeed: (int)speed;

@end

@implementation SpellController

static SpellController *sharedSpells = nil;

+ (SpellController *)sharedSpells {
	if (sharedSpells == nil)
		sharedSpells = [[[self class] alloc] init];
	return sharedSpells;
}

- (id) init {
    self = [super init];
	if(sharedSpells) {
		[self release];
		self = sharedSpells;
	} else if(self != nil) {
        
		sharedSpells = self;
        
        //_knownSpells = [[NSMutableArray array] retain];
        _playerSpells = [[NSMutableArray array] retain];
		_playerCooldowns = [[NSMutableArray array] retain];
        _cooldowns = [[NSMutableDictionary dictionary] retain];
		
		// remove the old spell book
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"SpellBook"];
		[[NSUserDefaults standardUserDefaults] synchronize];
    
        // new spell book for cata!
        NSData *spellBook = [[NSUserDefaults standardUserDefaults] objectForKey: @"SpellBookCata"];
        if(spellBook) {
            _spellBook = [[NSKeyedUnarchiver unarchiveObjectWithData: spellBook] mutableCopy];
        } else
            _spellBook = [[NSMutableDictionary dictionary] retain];

        // register notifications
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(applicationWillTerminate:) 
                                                     name: NSApplicationWillTerminateNotification 
                                                   object: nil];
                                                   
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(playerIsValid:) 
                                                     name: PlayerIsValidNotification 
                                                   object: nil];
        
        [NSBundle loadNibNamed: @"Spells" owner: self];
    }
    return self;
}

- (void)awakeFromNib {
    self.minSectionSize = [self.view frame].size;
    self.maxSectionSize = [self.view frame].size;
    
}

@synthesize view;
@synthesize selectedSpell;
@synthesize minSectionSize;
@synthesize maxSectionSize;

- (NSString*)sectionTitle {
    return @"Spells";
}

- (void)playerIsValid: (NSNotification*)notification {

    [self reloadPlayerSpells];
	
    
    int numLoaded = 0;
    for(Spell *spell in [self playerSpells]) {
        if( ![spell name] || ![[spell name] length] || [[spell name] isEqualToString: @"[Unknown]"]) {
            numLoaded++;
            [spell reloadSpellData];
        }
    }
    
    if(numLoaded > 0) {
        // log(LOG_GENERAL, @"[Spells] Loading %d unknown spells from wowhead.", numLoaded);
    }
}


- (void)applicationWillTerminate: (NSNotification*)notification {
    [self synchronizeSpells];
}


#pragma mark -
#pragma mark Internal

- (void)synchronizeSpells {
    [[NSUserDefaults standardUserDefaults] setObject: [NSKeyedArchiver archivedDataWithRootObject: _spellBook] forKey: @"SpellBookCata"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)reloadPlayerSpells {
    [_playerSpells removeAllObjects];
    MemoryAccess *memory = [controller wowMemoryAccess];
    if( !memory ) return;
    
    int i;
    	
	// find known spells
	UInt32 offset = [offsetController offset:@"lua_GetSpellBookItemInfo"];
	NSMutableArray *playerSpells = [NSMutableArray array];
	if ( [playerController playerIsValid:self] && offset ){
	
		UInt32 totalSpells = 0, spellBookInfoPtr = 0;
		[memory loadDataForObject: self atAddress: offset Buffer: (Byte *)&totalSpells BufLength: sizeof(totalSpells)];
		[memory loadDataForObject: self atAddress: offset + 0x4 Buffer: (Byte *)&spellBookInfoPtr BufLength: sizeof(spellBookInfoPtr)];
	
		if ( totalSpells > 0 && spellBookInfoPtr > 0x0 ){
			
			UInt32 spellStruct = 0, spellID = 0, isKnown = 0;
			
			for ( i = 0; i < totalSpells; i++ ){
				[memory loadDataForObject: self atAddress: spellBookInfoPtr + i * 4 Buffer: (Byte *)&spellStruct BufLength: sizeof(spellStruct)];
				[memory loadDataForObject: self atAddress: spellStruct + 0x4 Buffer: (Byte *)&spellID BufLength: sizeof(spellID)];
				[memory loadDataForObject: self atAddress: spellStruct Buffer: (Byte *)&isKnown BufLength: sizeof(isKnown)];	// not needed
				
				// we already have the spell - yay!
				Spell *spell = [self spellForID:[NSNumber numberWithInt:spellID]];
				
				// never seen it before, lets create it
				if ( !spell ){
					spell = [Spell spellWithID: [NSNumber numberWithUnsignedInt: spellID]];
                    [self addSpellAsRecognized: spell];
				}
				
				// then we know the spell!
				if ( isKnown != 2 ){
					[playerSpells addObject: spell];
				}
			}
		}
	}
	
	// scan the list of mounts!
	NSMutableArray *playerMounts = [NSMutableArray array];
	uint32_t value = 0;
	if( [playerController playerIsValid:self] ){
		UInt32 mountAddress = 0;
		
		UInt32 companionOffset = [offsetController offset:@"Lua_GetNumCompanions"];
		
		// grab the total number of mounts
		int32_t totalMounts = 0;
		[memory loadDataForObject: self atAddress: companionOffset + 0x10 Buffer: (Byte *)&totalMounts BufLength: sizeof(totalMounts)];
		
		log(LOG_DEV, @"[Mount] You have %d mounts, loading!", totalMounts);
		
		// grab the pointer to the list
		if([memory loadDataForObject: self atAddress: companionOffset + 0x14 Buffer: (Byte *)&mountAddress BufLength: sizeof(mountAddress)] && mountAddress) {
			
			int i = 0;
			for ( ; i < totalMounts ; i++ ) {
				// load all known spells into a temp array
				if ( [memory loadDataForObject: self atAddress: mountAddress + (i*0x4) Buffer: (Byte *)&value BufLength: sizeof(value)] ) {
					Spell *spell = [self spellForID: [NSNumber numberWithUnsignedInt: value]];
					if ( !spell ) {
						
						// create a new spell if necessary
						spell = [Spell spellWithID: [NSNumber numberWithUnsignedInt: value]];
						if ( !spell ){
							log(LOG_GENERAL, @"[Spell] Mount %d not found!", value );
							continue;
						}
						
						// spell isn't a mount? snap we probably need to reload it's data!
						if ( ![spell isMount] ){
							log(LOG_GENERAL, @"[Spell] Mount %d isn't registered as a mount! Reloading data", value);
							[spell reloadSpellData];
						}
						
						[self addSpellAsRecognized: spell];
					}
					[playerMounts addObject: spell];
				}
				else {
					break;
				}
			}
		}
		
		//log(LOG_GENERAL, @"[Mount] Broke after search of %d mounts", i);
	}
    
    // update list of known spells
    [_playerSpells addObjectsFromArray: playerSpells];
	if ( [playerMounts count] > 0 )
		[_playerSpells addObjectsFromArray: playerMounts];
    [self buildSpellMenu];
}

- (void)buildSpellMenu {
    
    NSMenu *spellMenu = [[[NSMenu alloc] initWithTitle: @"Spells"] autorelease];
    
    // load the player spells into arrays by spell school
    NSMutableDictionary *organizedSpells = [NSMutableDictionary dictionary];
    for(Spell *spell in _playerSpells) {
		
		if ( [spell isMount] ){
			if( ![organizedSpells objectForKey: @"Mount"] )
                [organizedSpells setObject: [NSMutableArray array] forKey: @"Mount"];
            [[organizedSpells objectForKey: @"Mount"] addObject: spell];
		}
        else if([spell school]) {
            if( ![organizedSpells objectForKey: [spell school]] )
                [organizedSpells setObject: [NSMutableArray array] forKey: [spell school]];
            [[organizedSpells objectForKey: [spell school]] addObject: spell];
        } 
		else {
            if( ![organizedSpells objectForKey: @"Unknown"] )
                [organizedSpells setObject: [NSMutableArray array] forKey: @"Unknown"];
            [[organizedSpells objectForKey: @"Unknown"] addObject: spell];
        }
    }
    
    NSMenuItem *spellItem;
    NSSortDescriptor *nameDesc = [[[NSSortDescriptor alloc] initWithKey: @"name" ascending: YES] autorelease];
    for(NSString *key in [organizedSpells allKeys]) {
        // create menu header for spell school name
        spellItem = [[[NSMenuItem alloc] initWithTitle: key action: nil keyEquivalent: @""] autorelease];
        [spellItem setAttributedTitle: [[[NSAttributedString alloc] initWithString: key 
                                                                        attributes: [NSDictionary dictionaryWithObjectsAndKeys: [NSFont boldSystemFontOfSize: 0], NSFontAttributeName, nil]] autorelease]];
        [spellItem setTag: 0];
        [spellMenu addItem: spellItem];
        
        // then, sort the array so its in alphabetical order
        NSMutableArray *schoolArray = [organizedSpells objectForKey: key];
        [schoolArray sortUsingDescriptors: [NSArray arrayWithObject: nameDesc]];
        
        // loop over the array and add in all the spells
        for(Spell *spell in schoolArray) {
            if( [spell name]) {
                spellItem = [[NSMenuItem alloc] initWithTitle: [NSString stringWithFormat: @"%@ - %@", [spell fullName], [spell ID] ] action: nil keyEquivalent: @""];
            } else {
                spellItem = [[NSMenuItem alloc] initWithTitle: [NSString stringWithFormat: @"%@", [spell ID]] action: nil keyEquivalent: @""];
            }
            [spellItem setTag: [[spell ID] unsignedIntValue]];
            [spellItem setRepresentedObject: spell];
            [spellItem setIndentationLevel: 1];
            [spellMenu addItem: [spellItem autorelease]];
        }
        [spellMenu addItem: [NSMenuItem separatorItem]];
    }
    
    int tagToSelect = 0;
    if( [_playerSpells count] == 0) {
        //for(NSMenuItem *item in [spellMenu itemArray]) {
       //     [spellMenu removeItem: item];
        //}
        spellItem = [[NSMenuItem alloc] initWithTitle: @"There are no available spells." action: nil keyEquivalent: @""];
        [spellItem setTag: 0];
        [spellMenu addItem: [spellItem autorelease]];
    } else {
        tagToSelect = [[spellDropDown selectedItem] tag];
    }
    
    [spellDropDown setMenu: spellMenu];
    [spellDropDown selectItemWithTag: tagToSelect];
}

#pragma mark -

- (Spell*)spellForName: (NSString*)name {
    if(!name || ![name length]) return nil;
    //log(LOG_GENERAL, @"[Spell] Searching for spell \"%@\"", name);
	
	// always return the highest one!
	UInt32 spellID = 0;
	Spell *tehSpell = nil;
    for(Spell *spell in [_spellBook allValues]) {
        if([spell name]) {
            NSRange range = [[spell name] rangeOfString: name 
                                                options: NSCaseInsensitiveSearch | NSAnchoredSearch | NSDiacriticInsensitiveSearch];
            if(range.location != NSNotFound){
				
				if ( [[spell ID] unsignedIntValue] > spellID ){
					tehSpell = spell;
					spellID = [[spell ID] unsignedIntValue];
				}
			}
        }
    }
	
    return tehSpell;
}

- (Spell*)spellForID: (NSNumber*)spellID {
    return [_spellBook objectForKey: spellID];
}

- (Spell*)playerSpellForName: (NSString*)spellName{
	if(!spellName) return nil;

    for(Spell *spell in [self playerSpells]) {
        // if the spell names match
        if([spell name] && [[spell name] isEqualToString: spellName]) {
			return spell;
        }
    }
	
	return nil;	
}

- (int)mountsLoaded{
	int total = 0;
	for ( Spell *spell in _playerSpells ) {
		if ( [spell isMount] ){
			total++;
		}
	}
	return total;
}

// I really don't like how ugly this function is, if only it was elegant :(
- (Spell*)mountSpell: (int)type andFast:(BOOL)isFast{
	
	NSMutableArray *mounts = [NSMutableArray array];
	if ( type == MOUNT_GROUND ){
		
		// Add fast mounts!
		if ( isFast ){
			[mounts addObjectsFromArray:[self mountsBySpeed:100]];
		}
		
		// We either have no fast mounts, or we didn't even want them!
		if ( [mounts count] == 0 ){
			[mounts addObjectsFromArray:[self mountsBySpeed:60]];	
		}
	}
	else if ( type == MOUNT_AIR ){
		if ( isFast ){
			[mounts addObjectsFromArray:[self mountsBySpeed:310]];
			
			// For most we will be here
			if ( [mounts count] == 0 ){
				[mounts addObjectsFromArray:[self mountsBySpeed:280]];
			}
		}
		
		// We either have no fast mounts, or we didn't even want them!
		if ( [mounts count] == 0 ){
			[mounts addObjectsFromArray:[self mountsBySpeed:150]];	
		}
	}
	
	// Randomly select one from the array!
	while ( [mounts count] > 0 ){
		
		// choose a random mount
		int randomMount = SSRandomIntBetween(0, [mounts count]-1);
		
		// get the random spell from the list!
		Spell *spell = [mounts objectAtIndex:randomMount];
		
		// make sure we can cast the spell!
		if ( [self isUsableAction:[[spell ID] intValue]] ){
			log(LOG_MOUNT, @"Found usable mount! %@", spell);
			return spell;
		}
		
		log(LOG_GENERAL, @"[Mount] Unable to verify spell %@, trying to find another (if no mount is on an action bar this will fail forever).", spell);
		
		// this spell failed, remove it so we don't select it again
		[mounts removeObjectAtIndex:randomMount];
	}
	
	return nil;
}

- (NSArray*)mountsBySpeed: (int)speed{
	NSMutableArray *mounts = [NSMutableArray array];
	for(Spell *spell in _playerSpells) {
		int s = [[spell speed] intValue];
		if ( s == speed ){
			[mounts addObject:spell];
		}
	}
	
	return mounts;	
}

- (BOOL)addSpellAsRecognized: (Spell*)spell {
    if(![spell ID]) return NO;
    if([[spell ID] unsignedIntValue] > 1000000) return NO;
    if( ![self spellForID: [spell ID]] ) {
        // log(LOG_GENERAL, @"Adding spell %@ as recognized.", spell);
        [_spellBook setObject: spell forKey: [spell ID]];
        [self synchronizeSpells];
        return YES;
    }
    return NO;
}

#pragma mark -

- (BOOL)isPlayerSpell: (Spell*)aSpell {
    for(Spell *spell in [self playerSpells]) {
        if([spell isEqualToSpell: aSpell])
            return YES;
    }
    return NO;
}

- (NSArray*)playerSpells {
    return [[_playerSpells retain] autorelease];
}

- (NSMenu*)playerSpellsMenu {
    [self reloadPlayerSpells];
    return [[[spellDropDown menu] copy] autorelease];
}

- (UInt32)lastAttemptedActionID {
    UInt32 value = 0;
    [[controller wowMemoryAccess] loadDataForObject: self atAddress: [offsetController offset:@"LAST_SPELL_THAT_DIDNT_CAST_STATIC"] Buffer: (Byte*)&value BufLength: sizeof(value)];
    return value;
}

#pragma mark -
#pragma mark IBActions

- (IBAction)reloadMenu: (id)sender {
    [self reloadPlayerSpells];
}

- (IBAction)spellLoadAllData:(id)sender {
    
    // make sure our state is valid
    MemoryAccess *memory = [controller wowMemoryAccess];
    if( !memory )  {
        NSBeep();
        return;
    }

    [self reloadPlayerSpells];

    if([_playerSpells count]) {
        [spellLoadingProgress setHidden: NO];
        [spellLoadingProgress setMaxValue: [_playerSpells count]];
        [spellLoadingProgress setDoubleValue: 0];
        [spellLoadingProgress setUsesThreadedAnimation: YES];
    } else {
        return;
    }
    
    for(Spell *spell in _playerSpells) {
        [spell reloadSpellData];
        [spellLoadingProgress incrementBy: 1.0];
        [spellLoadingProgress displayIfNeeded];
    }
    
    // finish up
    [spellLoadingProgress setHidden: YES];
    [self synchronizeSpells];
    [self reloadPlayerSpells];
}

- (void)showCooldownPanel{
	[cooldownPanel makeKeyAndOrderFront: self];
}

// Pull in latest CD info
- (void)reloadCooldownInfo{
	
	// Why are we updating the table if we can't see it??
	if ( ![[cooldownPanelTable window] isVisible] ){
		return;
	}
	
	[_playerCooldowns removeAllObjects];
	
	MemoryAccess *memory = [controller wowMemoryAccess];
	
	UInt32 objectListPtr = 0, lastObjectPtr=0, row=0;
	UInt32 offset = [offsetController offset:@"CD_LIST_STATIC"];
	[memory loadDataForObject:self atAddress:offset + 0x4 Buffer:(Byte *)&lastObjectPtr BufLength:sizeof(lastObjectPtr)];
	[memory loadDataForObject:self atAddress:offset + 0x8 Buffer:(Byte *)&objectListPtr BufLength:sizeof(objectListPtr)];
	BOOL reachedEnd = NO;
	
	WoWCooldown cd;
	while ((objectListPtr != 0)  && ((objectListPtr & 1) == 0) ) {
		row++;
		[memory loadDataForObject: self atAddress: (objectListPtr) Buffer:(Byte*)&cd BufLength: sizeof(cd)];
		
		long realCD = cd.cooldown;
		if (  cd.cooldown2 > cd.cooldown )
			realCD =  cd.cooldown2;
		
		long realStartTime = cd.startTime;
		if ( cd.startNotUsed > cd.startTime )
			realStartTime = cd.startNotUsed;
		
		
		/*
		 typedef struct WoWCooldown {
		 UInt32 unk;					// 0x0
		 UInt32 nextObjectAddress;	// 0x4
		 UInt32 spellID;				// 0x8
		 UInt32 unk3;				// 0xC (always 0 when the spell is a player spell)
		 UInt32 startTime;			// 0x10 (start time of the spell, stored in milliseconds)
		 long cooldown;				// 0x14
		 UInt32 unk4;				// 0x18
		 UInt32 startNotUsed;		// 0x1C	(the same as 0x10 always I believe?)
		 long cooldown2;				// 0x20
		 UInt32 enabled;				// 0x24 (0 if spell is enabled, 1 if it's not)
		 UInt32 unk5;				// 0x28
		 UInt32 gcd;					// 0x2C
		 } WoWCooldown;
		 */
		
		// Save it!
		[_playerCooldowns addObject: [NSDictionary dictionaryWithObjectsAndKeys:
									  [NSNumber numberWithUnsignedLong: row],							@"ID",
									  [NSNumber numberWithUnsignedLong: cd.spellID],					@"SpellID",
									  [NSNumber numberWithUnsignedLong: realStartTime],					@"StartTime",
									  [NSNumber numberWithUnsignedLong: realCD],                        @"Cooldown",
									  [NSNumber numberWithUnsignedLong: cd.gcd],						@"GCD",
									  [NSNumber numberWithUnsignedLong: cd.unk],						@"Unk",
									  [NSNumber numberWithUnsignedLong: cd.unk3],						@"Unk3",
									  [NSNumber numberWithUnsignedLong: cd.unk4],						@"Unk4",
									  [NSNumber numberWithUnsignedLong: cd.unk5],						@"Unk5",
									  [NSNumber numberWithUnsignedLong: cd.startTime],					@"OriginalStartTime",
									  [NSNumber numberWithUnsignedLong: cd.startNotUsed],				@"StartNotUsed",
									  [NSNumber numberWithUnsignedLong: cd.cooldown],					@"CD1",
									  [NSNumber numberWithUnsignedLong: cd.cooldown2],					@"CD2",
									  [NSNumber numberWithUnsignedLong: cd.enabled],					@"Enabled",
									  
									  nil]];

		if ( reachedEnd )
			break;
		
		objectListPtr = cd.nextObjectAddress;

		if ( objectListPtr == lastObjectPtr )
			reachedEnd = YES;
	}
	
	[cooldownPanelTable reloadData];
}



#pragma mark -
#pragma mark Auras Delesource


- (int)numberOfRowsInTableView:(NSTableView *)aTableView {
   return [_playerCooldowns count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
   if(rowIndex == -1 || rowIndex >= [_playerCooldowns count]) return nil;
    	
	if([[aTableColumn identifier] isEqualToString: @"Cooldown"]) {
        float secRemaining = [[[_playerCooldowns objectAtIndex: rowIndex] objectForKey: [aTableColumn identifier]] floatValue]/1000.0f;
        if(secRemaining < 60.0f) {
            return [NSString stringWithFormat: @"%.0f sec", secRemaining];
        } else if(secRemaining < 3600.0f) {
            return [NSString stringWithFormat: @"%.0f min", secRemaining/60.0f];
        } else if(secRemaining < 86400.0f) {
            return [NSString stringWithFormat: @"%.0f hour", secRemaining/3600.0f];
		} else if(secRemaining < 604800.0f ) {
            return [NSString stringWithFormat: @"%.0f days", secRemaining/86400.0f];
		}
	}
	
	if([[aTableColumn identifier] isEqualToString: @"TimeRemaining"]) {
        double cd = [[[_playerCooldowns objectAtIndex: rowIndex] objectForKey: @"Cooldown"] floatValue];
		double currentTime = (float) [playerController currentTime];
		double startTime = [[[_playerCooldowns objectAtIndex: rowIndex] objectForKey: @"StartTime"] floatValue];
		double secRemaining = ((startTime + cd)-currentTime)/1000.0f;
		
		//if ( secRemaining < 0.0f ) secRemaining = 0.0f;
		
		if(secRemaining < 60.0f) {
            return [NSString stringWithFormat: @"%.0f sec", secRemaining];
        } else if(secRemaining < 3600.0f) {
            return [NSString stringWithFormat: @"%.0f min", secRemaining/60.0f];
        } else if(secRemaining < 86400.0f) {
            return [NSString stringWithFormat: @"%.0f hour", secRemaining/3600.0f];
		} else if(secRemaining < 604800.0f ) {
            return [NSString stringWithFormat: @"%.0f days", secRemaining/86400.0f];
		}
	}
		
	if ([[aTableColumn identifier] isEqualToString:@"Address"]){
		return [NSString stringWithFormat:@"0x%X", [[[_playerCooldowns objectAtIndex: rowIndex] objectForKey: [aTableColumn identifier]] intValue]]; 
	}
	
	if ([[aTableColumn identifier] isEqualToString:@"SpellName"]){
		int spellID = [[[_playerCooldowns objectAtIndex: rowIndex] objectForKey: @"SpellID"] intValue];
		Spell *spell = [self spellForID:[NSNumber numberWithInt:spellID]];
		// need to add it!
		if ( !spell ){
			spell = [Spell spellWithID: [NSNumber numberWithUnsignedInt: spellID]];
			[spell reloadSpellData];
			[self addSpellAsRecognized: spell];
		}
		return [spell name];
	}
    
    return [[_playerCooldowns objectAtIndex: rowIndex] objectForKey: [aTableColumn identifier]];
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    return NO;
}

- (void)tableView:(NSTableView *)aTableView  sortDescriptorsDidChange:(NSArray *)oldDescriptors {
    //[_playerAuras sortUsingDescriptors: [aurasPanelTable sortDescriptors]];
    [cooldownPanelTable reloadData];
}

#pragma mark Cooldowns
// Contribution by Monder - thank you!

-(BOOL)isGCDActive {
	MemoryAccess *memory = [controller wowMemoryAccess];
	UInt32 currentTime = [playerController currentTime];
	UInt32 objectListPtr = 0, lastObjectPtr=0;
	UInt32 offset = [offsetController offset:@"CD_LIST_STATIC"];
	BOOL reachedEnd = NO;
	WoWCooldown cd;
	
	// load start/end object ptrs
	[memory loadDataForObject:self atAddress:offset + 0x4 Buffer:(Byte *)&lastObjectPtr BufLength:sizeof(lastObjectPtr)];
	[memory loadDataForObject:self atAddress:offset + 0x8 Buffer:(Byte *)&objectListPtr BufLength:sizeof(objectListPtr)];

	while ((objectListPtr != 0)  && ((objectListPtr & 1) == 0) ) {
		[memory loadDataForObject: self atAddress: (objectListPtr) Buffer:(Byte*)&cd BufLength: sizeof(cd)];
		
		long realStartTime = cd.startTime;
		if ( cd.startNotUsed > cd.startTime )
			realStartTime = cd.startNotUsed;
			
		// is gcd active?
		if ( cd.gcd != 0 && realStartTime + cd.gcd > currentTime ){
			return YES;
		}
		
		if ( reachedEnd )
			break;
		
		objectListPtr = cd.nextObjectAddress;
		
		if ( objectListPtr == lastObjectPtr )
			reachedEnd = YES;
	}
	
	return NO;     
}
-(BOOL)isSpellOnCooldown:(UInt32)spell {
	if( [self cooldownLeftForSpellID:spell] == 0)
		return NO;
	return YES;
}

// this could be more elegant (i.e. storing cooldown info and only updating it every 0.25 seconds or when a performAction on a spell is done)
-(UInt32)cooldownLeftForSpellID:(UInt32)spell {
	
	MemoryAccess *memory = [controller wowMemoryAccess];
	
	UInt32 currentTime = [playerController currentTime];
	UInt32 objectListPtr = 0, lastObjectPtr=0;
	UInt32 offset = [offsetController offset:@"CD_LIST_STATIC"];
	[memory loadDataForObject:self atAddress:offset + 0x4 Buffer:(Byte *)&lastObjectPtr BufLength:sizeof(lastObjectPtr)];
	[memory loadDataForObject:self atAddress:offset + 0x8 Buffer:(Byte *)&objectListPtr BufLength:sizeof(objectListPtr)];
	BOOL reachedEnd = NO;
	
	WoWCooldown cd;
	while ((objectListPtr != 0)  && ((objectListPtr & 1) == 0) ) {
		[memory loadDataForObject: self atAddress: (objectListPtr) Buffer:(Byte*)&cd BufLength: sizeof(cd)];
		
		if ( cd.spellID == spell ){
			
			long realCD = cd.cooldown;
			if (  cd.cooldown2 > cd.cooldown )
				realCD =  cd.cooldown2;
			
			long realStartTime = cd.startTime;
			if ( cd.startNotUsed > cd.startTime )
				realStartTime = cd.startNotUsed;
			
			// are we on cooldown?
			if ( realStartTime + realCD > currentTime )
				return realStartTime + realCD - currentTime;
		}
		
		if ( reachedEnd )
			break;
		
		objectListPtr = cd.nextObjectAddress;
		
		if ( objectListPtr == lastObjectPtr )
			reachedEnd = YES;
	}
	
	// if we get here we made it through the list, the spell isn't on cooldown!
	return 0;
}

#pragma mark Spell Usable?

- (BOOL)isUsableActionWithSlot: (int)slot{
	
	// grab memory
	MemoryAccess *memory = [controller wowMemoryAccess];
	if ( !memory )
		return NO;
	
	UInt32 isUsable = 0, dueToMana = 0;
	[memory loadDataForObject: self atAddress: [offsetController offset:@"Lua_IsUsableAction"] + (slot*4) Buffer: (Byte *)&isUsable BufLength: sizeof(isUsable)];
	[memory loadDataForObject: self atAddress: [offsetController offset:@"Lua_IsUsableActionNotEnough"] + (slot*4) Buffer: (Byte *)&dueToMana BufLength: sizeof(dueToMana)];
	
	//log(LOG_GENERAL, @" [Spell] For slot 0x%X, usable? %d due to mana? %d", slot, isUsable, dueToMana);
	
	// yay! we can use this ability!
	if ( isUsable && !dueToMana ){
		return YES;
	}
	
	return NO;
}

// are we able to use this spell (it must be on an action bar!)
- (BOOL)isUsableAction: (UInt32)actionID{
	
	// grab memory
	MemoryAccess *memory = [controller wowMemoryAccess];
	if ( !memory )
		return NO;
	
	// find out where the action is stored
	UInt32 hotbarBaseOffset = [offsetController offset:@"HOTBAR_BASE_STATIC"];
	
	// find where the spell is on our bar
	UInt32 hotbarActionIDs[MAXIMUM_SPELLS_IN_BARS] = {0};
	int spellOffset = -1;
	if ( [memory loadDataForObject: self atAddress: hotbarBaseOffset Buffer: (Byte *)&hotbarActionIDs BufLength: sizeof(hotbarActionIDs)] ){
		
		int i;
		for ( i = 0; i < MAXIMUM_SPELLS_IN_BARS; i++ ){
			
			if ( actionID == hotbarActionIDs[i] ){
				spellOffset = i;
			}
		}
	}
	
	/*
	 this method doesn't work unfortunately, the spells must be on the player's bars
	
	UInt32 readActionID = 0;
	int i, spellOffset = -1;
	// loop through all 10 bars to find it
	for ( i = 0; i <= 0x1E0; i++ ){
		if ( [memory loadDataForObject: self atAddress: hotbarBaseOffset + (i*4) Buffer: (Byte *)&readActionID BufLength: sizeof(readActionID)] && readActionID ){
			if ( readActionID == actionID ){
				spellOffset = i;
				break;
			}
		}
	}*/
	
	if ( spellOffset != -1 ){
		return [self isUsableActionWithSlot:spellOffset];
	}
	
	return NO;
	
	//log(LOG_GENERAL, @"Spell offset: 0x%X", spellOffset);


	
	
	/*UInt32 hotbarBaseOffset = [offsetController offset:@"HOTBAR_BASE_STATIC"];
	 
	 log(LOG_GENERAL, @"writing to 0x%X", hotbarBaseOffset + BAR6_OFFSET);
	 
	 // get the old spell
	 UInt32 oldActionID = 0;
	 [memory loadDataForObject: self atAddress: (hotbarBaseOffset + BAR6_OFFSET) Buffer: (Byte *)&oldActionID BufLength: sizeof(oldActionID)];
	 
	 // write the new action to memory
	 [memory saveDataForAddress: (hotbarBaseOffset + BAR6_OFFSET) Buffer: (Byte *)&actionID BufLength: sizeof(actionID)];
	 
	 // wow needs time to process the spell change
	 usleep([controller refreshDelay]*2);
	 
	 BOOL usable = [self isUsableActionWithSlot:(BAR6_OFFSET / 4)];
	 
	 // then save our old action back
	 [memory saveDataForAddress: (hotbarBaseOffset + BAR6_OFFSET) Buffer: (Byte *)&oldActionID BufLength: sizeof(oldActionID)];
	 
	 // wow needs time to process the spell change
	 usleep([controller refreshDelay]*2);
	 
	 return usable;*/
	
	
	

	// save the old spell + write the new one
		/*
	 isUsable Flag		- Returns 1 if the action is valid for use at present (Does NOT include cooldown or range tests), nil otherwise. 
	 notEnoughMana Flag - Returns 1 if the reason for the action not being usable is because there is not enough mana/rage/energy, nil otherwise. 
	 
	 
	signed int __cdecl lua_IsUsableAction(int a1)
	{
		int v1; // eax@2
		double v2; // ST18_8@2
		signed int result; // eax@3
		
		if ( !FrameScript_IsNumber(a1, 1) )
			FrameScript_DisplayError(a1, "Usage: IsUsableAction(slot)");
		v2 = sub_814950(a1, 1);
		__asm { cvttsd2si eax, [ebp+var_10]; Convert with Truncation Scalar Double-Precision Floating-Point Value to Doubleword Integer }
		v1 = _EAX - 1;
		if ( (unsigned int)v1 <= 0x8F && dword_isUsable[v1] )	//dword_D7DFC0
		{
			// action not useable, due to mana/rage/energy
			if ( dword_D7DD80[v1] )
			{
				FrameScript_pushnil(a1);
				FrameScript_PushNumber(a1, 4607182418800017408LL);
				result = 2;
			}
			// action usable, mana irrelevant
			else
			{
				FrameScript_PushNumber(a1, 4607182418800017408LL);
				FrameScript_pushnil(a1);
				result = 2;
			}
		}
		// action not usable, and no mana :(
		else
		{
			FrameScript_pushnil(a1);
			FrameScript_pushnil(a1);
			result = 2;
		}
		return result;
	}*/
}

#pragma mark All Spells ready for the bot to start?

- (NSArray*)allActionIDsOnActionBars{
	
	// grab memory
	MemoryAccess *memory = [controller wowMemoryAccess];
	if ( !memory )
		return NO;
	
	NSMutableArray *allActionIDs = [NSMutableArray array];
	
	// find out where the action is stored
	UInt32 hotbarBaseOffset = [offsetController offset:@"HOTBAR_BASE_STATIC"];
	
	// find where the spell is on our bar
	UInt32 hotbarActionIDs[MAXIMUM_SPELLS_IN_BARS] = {0};
	if ( [memory loadDataForObject: self atAddress: hotbarBaseOffset Buffer: (Byte *)&hotbarActionIDs BufLength: sizeof(hotbarActionIDs)] ){
		
		int i;
		for ( i = 0; i < MAXIMUM_SPELLS_IN_BARS; i++ ){
			[allActionIDs addObject:[NSNumber numberWithInt:hotbarActionIDs[i]]];
		}
	}
	
	return [[allActionIDs retain] autorelease];
}

// return all actions (items, spells, macros) that are used in a procedure
- (NSArray*)spellsInProcedure:(Behavior*)behavior{
	
	NSArray *allProcedures = [behavior allProcedures];
	NSMutableArray *allActions = [NSMutableArray array];
	if ( allProcedures && [allProcedures count] ){
		
		// look at each procedure
		for ( Procedure *procedure in allProcedures ){
			
			// look at each rule
			int i;
			for ( i = 0; i < [procedure ruleCount]; i++ ) {
				Rule *rule = [procedure ruleAtIndex: i];
				
				// an action exists!
				if ( [[rule action] actionID] ){
					
					// action id changes based on type
					switch([rule resultType]) {
						case ActionType_Item: 
							[allActions addObject:[NSNumber numberWithInt:USE_ITEM_MASK + [[rule action] actionID]]];
							break;
						case ActionType_Macro:
							[allActions addObject:[NSNumber numberWithInt:USE_MACRO_MASK + [[rule action] actionID]]];
							break;
						case ActionType_Spell:
							[allActions addObject:[NSNumber numberWithInt:[[rule action] actionID]]];
							break;
						default:
							break;
					}
				}
			}
		}
	}
	
	return allActions;
}

- (NSString*)spellsReadyForBotting{
	
	NSMutableArray *allActions = [NSMutableArray arrayWithArray:[self spellsInProcedure:[botController theBehavior]]];
	
	// remove the actions that are on our bars
	NSArray *actionBarActions = [self allActionIDsOnActionBars];
	for ( NSNumber *actionID in actionBarActions ){
		
		// then all are found!
		if ( [allActions count] == 0 )
			break;
		
		if ( [allActions containsObject:actionID] ){
			[allActions removeObject:actionID];
		}
	}
	
	// remove duplicates
	NSMutableArray *finalActions = [NSMutableArray array];
	for ( NSNumber *action in allActions ){
		if ( ![finalActions containsObject:action] ){
			[finalActions addObject:action];
		}
	}
	
	// any left here aren't on any bar, throw an error!
	if ( [finalActions count] > 0 ){
		NSMutableString *error = [NSMutableString string];
		[error appendString:@"The following spells/macros/items are not on any action bar, please add them to a bar:\n\n"];
		
		for ( NSNumber *actionID in finalActions ){
			UInt32 iActionID = [actionID unsignedLongValue];

			// item
			if ( iActionID & USE_ITEM_MASK ){
				Item *item = [itemController itemForID:[NSNumber numberWithUnsignedLong:iActionID - USE_ITEM_MASK]];
				
				if ( item ){
					[error appendString:[NSString stringWithFormat:@"Item: %@ <%u>\n", [item name], iActionID - USE_ITEM_MASK]];
				}
				else{
					[error appendString:[NSString stringWithFormat:@"Item ID: <%u>\n", iActionID - USE_ITEM_MASK]];
				}
			}
			// macro
			else if ( iActionID & USE_MACRO_MASK ){
				NSString *macroName = [macroController nameForID:iActionID - USE_MACRO_MASK];
				
				if ( macroName && [macroName length] ){
					[error appendString:[NSString stringWithFormat:@"Macro: %@ <%u>\n", macroName, iActionID - USE_MACRO_MASK]];
				}
				else{
					[error appendString:[NSString stringWithFormat:@"Macro: <%u>\n", iActionID - USE_MACRO_MASK]];
				}
			}
			// spell
			else{
				Spell *spell = [self spellForID:actionID];
				
				if ( spell ){
					[error appendString:[NSString stringWithFormat:@"Spell: %@ <%@>\n", [spell name], actionID]];
				}
				else{
					[error appendString:[NSString stringWithFormat:@"Spell: <%@>\n", actionID]];
				}
			}
		}
		
		[error appendString:@"\nI would recommend using Bartender4 to better organize your spells (the bars can be hidden)\n\nSpell/Item name not listed?  Try adding it to the end of these URLS:\nhttp://wowhead.com/?spell=\nhttp://wowhead.com/?item="];
		
		return [[error retain] autorelease];
	}
	
	return nil;	
}

@end
