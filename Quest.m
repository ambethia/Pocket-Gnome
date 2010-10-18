//
//  Quest.m
//  Pocket Gnome
//
//  Created by Josh on 4/23/09.
//	Copyright 2007 Savory Software, LLC. All rights reserved.
//

#import "Quest.h"
#import "QuestItem.h"

@interface Quest (internal)
- (void)loadQuestData;
@end

@implementation Quest

- (id) init
{
    self = [super init];
    if (self != nil) {
        self.questID = nil;
        self.name = nil;
        self.level = nil;
        self.requiredLevel = nil;
        self.startNPC = nil;
        self.endNPC = nil;
        self.itemRequirements = nil;
    }
    return self;
}

- (id)initWithQuestID: (NSNumber*)questID {
    self = [self init];
    if(self) {
        if( ([questID intValue] <= 0) || ([questID intValue] > MaxQuestID)) {
            [self release];
            return nil;
        }
        self.questID = questID;
		
		// Lets grab quest data...
		//[self reloadQuestData];
    }
    return self;
}

+ (Quest*)questWithID: (NSNumber*)questID {
    return [[[Quest alloc] initWithQuestID: questID] autorelease];
}

- (id)initWithCoder:(NSCoder *)decoder
{
	self = [super init];
	if(self) {
        self.questID = [decoder decodeObjectForKey: @"QuestID"];
        self.name = [decoder decodeObjectForKey: @"Name"];
		self.level = [decoder decodeObjectForKey: @"Level"];
		self.requiredLevel = [decoder decodeObjectForKey: @"RequiredLevel"];
		self.startNPC = [decoder decodeObjectForKey: @"StartNPC"];
		self.endNPC = [decoder decodeObjectForKey: @"EndNPC"];
		self.itemRequirements = [decoder decodeObjectForKey: @"ItemRequirements"];
        
        if(self.name) {
            NSRange range = [self.name rangeOfString: @"html>"];
            if( ([self.name length] == 0) || (range.location != NSNotFound)) {
                log(LOG_GENERAL, @"Name for quest %@ is invalid.", self.questID);
                self.name = nil;
            }
        }
	}
	return self;
}

-(void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject: self.questID forKey: @"QuestID"];
    [coder encodeObject: self.name forKey: @"Name"];
	[coder encodeObject: self.level forKey: @"Level"];
	[coder encodeObject: self.requiredLevel forKey: @"RequiredLevel"];
	[coder encodeObject: self.startNPC forKey: @"StartNPC"];
	[coder encodeObject: self.endNPC forKey: @"EndNPC"];
	[coder encodeObject: self.itemRequirements forKey: @"ItemRequirements"];
}

- (void)dealloc {
    self.questID = nil;
    self.name = nil;
	self.level = nil;
	self.requiredLevel = nil;
	self.startNPC = nil;
    self.endNPC;
	self.itemRequirements = nil;
	
    [_connection release];
    [_downloadData release];
    
    [super dealloc];
}

@synthesize questID = _questID;
@synthesize name = _name;
@synthesize level = _level;
@synthesize requiredLevel = _requiredLevel;
@synthesize startNPC = _startNPC;
@synthesize endNPC = _endNPC;
@synthesize itemRequirements = _itemRequirements;

#pragma mark -

- (int)requiredItemTotal{
	return [self.itemRequirements count];
}

#pragma mark -

//#define NAME_SEPARATOR      @"<table class=ttb width=300><tr><td colspan=2>"
//#define RANGE_SEPARATOR     @"<th>Range</th>		<td>"
//#define COOLDOWN_SEPARATOR  @"<tr><th>Cooldown</th><td>"

#define NAME_SEPARATOR			@"<title>"
#define LEVEL_SEPERATOR			@"<div>Level: "
#define REQD_LEVEL_SEPRATOR		@"<div>Requires level "
#define START_SEPERATOR			@"Start: <a href=\"/?npc="
#define END_SEPERATOR			@"End: <a href=\"/?npc="
#define ITEM_SEPERATOR			@"?item="
#define ITEM_NUM_SEPERATOR		@"</a></span>&nbsp;("
#define REWARDS_SEPERATOR		@"<h3>Rewards</h3>"

#define SCHOOL_SEPARATOR    @"School</th><td>"
#define DISPEL_SEPARATOR    @"Dispel type</th><td style=\"border-bottom: 0\">"
#define COST_SEPARATOR      @"Cost</th><td style=\"border-top: 0\">"
#define RANGE_SEPARATOR     @"<th>Range</th><td>"
#define CASTTIME_SEPARATOR  @"<th>Cast time</th><td>"
#define COOLDOWN_SEPARATOR  @"<th>Cooldown</th><td>"
#define GLOBAL_COOLDOWN_SEPARATOR   @"<div style=\"width: 65%; float: right\">Global cooldown: "


- (void)reloadQuestData {
    
    if([[self questID] intValue] < 0 || [[self questID] intValue] > MaxQuestID)
        return;
    
    [_connection cancel];
    [_connection release];
    _connection = [[NSURLConnection alloc] initWithRequest: [NSURLRequest requestWithURL: [NSURL URLWithString: [NSString stringWithFormat: @"http://wowhead.com/?quest=%@", [self questID]]]] delegate: self];
    if(_connection) {
        [_downloadData release];
        _downloadData = [[NSMutableData data] retain];
        //[_connection start];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [_downloadData setLength: 0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [_downloadData appendData: data];
}

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error
{
    // release the connection, and the data object
    [_connection release];  _connection = nil;
    [_downloadData release]; _downloadData = nil;
	
    // inform the user
    log(LOG_GENERAL, @"Connection failed! Error - %@ %@",
          [error localizedDescription],
          [[error userInfo] objectForKey:NSErrorFailingURLStringKey]);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    // get the download as a string
    NSString *wowhead = [[[NSString alloc] initWithData: _downloadData encoding: NSUTF8StringEncoding] autorelease];
    
    // release the connection, and the data object
    [_connection release];  _connection = nil;
    [_downloadData release]; _downloadData = nil;
	
	// parse out the name
    if(wowhead && [wowhead length]) {
        NSScanner *scanner = [NSScanner scannerWithString: wowhead];
        
        // check to see if this is a valid quest
        if( ([scanner scanUpToString: @"Error - Wowhead" intoString: nil]) && ![scanner isAtEnd]) {
            int questID = [[self questID] intValue];
            switch(questID) {
                default:
                    self.name = @"[Unknown]";
                    break;
            }
            
            log(LOG_GENERAL, @"Quest %d does not exist on wowhead.", questID);
            return;
        } else {
            if( [scanner scanUpToString: @"Bad Request" intoString: nil] && ![scanner isAtEnd]) {
                int questID = [[self questID] intValue];
                log(LOG_GENERAL, @"Error loading quest %d.", questID);
                return;
            } else {
                [scanner setScanLocation: 0];
            }
        }
        
        // get the quest name
        int scanSave = [scanner scanLocation];
        if([scanner scanUpToString: NAME_SEPARATOR intoString: nil] && [scanner scanString: NAME_SEPARATOR intoString: nil]) {
            NSString *newName = nil;
            if([scanner scanUpToString: @" - Quest" intoString: &newName]) {
                if(newName && [newName length]) {
                    self.name = newName;
					
                } else {
                    self.name = @"";
                }
            }
        }
		else {
            [scanner setScanLocation: scanSave];
        }
		
		// Get the Level reco
        scanSave = [scanner scanLocation];
        if([scanner scanUpToString: LEVEL_SEPERATOR intoString: nil] && [scanner scanString: LEVEL_SEPERATOR intoString: nil]) {
            int level = 0;
            if([scanner scanInt: &level] && level) {
                self.level = [NSNumber numberWithInt: level];
            } else {
                self.level = [NSNumber numberWithInt: 0];
            }
        } else {
            [scanner setScanLocation: scanSave];
        }
		
		// Get the required level
        scanSave = [scanner scanLocation];
        if([scanner scanUpToString: REQD_LEVEL_SEPRATOR intoString: nil] && [scanner scanString: REQD_LEVEL_SEPRATOR intoString: nil]) {
            int requiredLevel = 0;
            if([scanner scanInt: &requiredLevel] && requiredLevel) {
                self.requiredLevel = [NSNumber numberWithInt: requiredLevel];
            } else {
                self.requiredLevel = [NSNumber numberWithInt: 0];
            }
        } else {
            [scanner setScanLocation: scanSave];
        }
		
		// Where does the quest start!
        scanSave = [scanner scanLocation];
        if([scanner scanUpToString: START_SEPERATOR intoString: nil] && [scanner scanString: START_SEPERATOR intoString: nil]) {
            int start = 0;
            if([scanner scanInt: &start] && start) {
                self.startNPC = [NSNumber numberWithInt: start];
            } else {
                self.startNPC = [NSNumber numberWithInt: 0];
            }
        } else {
            [scanner setScanLocation: scanSave];
        }
		
		// Where does the quest end!
        scanSave = [scanner scanLocation];
        if([scanner scanUpToString: END_SEPERATOR intoString: nil] && [scanner scanString: END_SEPERATOR intoString: nil]) {
            int endnpc = 0;
            if([scanner scanInt: &endnpc] && endnpc) {
                self.endNPC = [NSNumber numberWithInt: endnpc];
            } else {
                self.endNPC = [NSNumber numberWithInt: 0];
            }
        } else {
            [scanner setScanLocation: scanSave];
        }
		
		// Are there any quest items required?
        scanSave = [scanner scanLocation];
		
		// Lets scan up to the Rewards section.. so any item before that we can assume is required for completion...
		NSString *upToRewards = nil;
		[scanner scanUpToString: REWARDS_SEPERATOR intoString: &upToRewards];
		[scanner setScanLocation: scanSave];
		
		if ( upToRewards ){
			//NSLog(@"//// %@ ^n////", upToRewards );
			// Set up a new scanner for just the above string
			NSScanner *scannerUpToRewards = [NSScanner scannerWithString: upToRewards];
			
			BOOL searching = true;
			NSMutableArray *items = [[NSMutableArray array] retain];
			while(searching){
				if([scannerUpToRewards scanUpToString: ITEM_SEPERATOR intoString: nil] && [scannerUpToRewards scanString: ITEM_SEPERATOR intoString: nil]) {
					int itemID = 0;
					QuestItem *questItem = [[[QuestItem alloc] init] autorelease];
					if([scannerUpToRewards scanInt: &itemID] && itemID) {
						
						// At this point we have the item ID #... now lets check to see if there is a quantity associated w/it
						int quantity = 1;//_itemRequirements
						if([scannerUpToRewards scanUpToString: ITEM_NUM_SEPERATOR intoString: nil] && [scannerUpToRewards scanString: ITEM_NUM_SEPERATOR intoString: nil]) {
							[scannerUpToRewards scanInt: &quantity];
						}
						questItem.quantity = [NSNumber numberWithInt: quantity];
						
						// Set the item ID
						questItem.item = [NSNumber numberWithInt: itemID];
						
						// Add it to our required items list
						[items addObject:questItem];
						//log(LOG_GENERAL, @"%@ %@ %@", self.name, questItem.item, questItem.quantity );
					}
				} else {
					searching = false;
				}
			}
			
			// Make sure we save the items - duh!
			self.itemRequirements = items;
		}
	}
	
	// Could do some other things 
	
	
	
	
	//log(LOG_GENERAL, @"%@ %@ %@ %@ %@", self.name, self.level, self.requiredlevel, self.startnpc, self.endnpc);
}

@end
