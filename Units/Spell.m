//
//  Spell.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 12/22/07.
//  Copyright 2007 Savory Software, LLC. All rights reserved.
//

#import "Spell.h"


@interface Spell (internal)
- (void)loadSpellData;
@end

@implementation Spell

- (id) init
{
    self = [super init];
    if (self != nil) {
        _spellID = nil;
        _range = nil;
        _cooldown = nil;
        _name = nil;
        _dispelType = nil;
        _school = nil;
		_mount = nil;
		_mechanic = nil;
		_speed = nil;
        self.castTime = nil;

    }
    return self;
}

- (id)initWithSpellID: (NSNumber*)spellID {
    self = [self init];
    if(self) {
        if( ([spellID intValue] <= 0) || ([spellID intValue] > MaxSpellID)) {
            [self release];
            return nil;
        }
        _spellID = [spellID retain];
    }
    return self;
}

+ (id)spellWithID: (NSNumber*)spellID {
    return [[[Spell alloc] initWithSpellID: spellID] autorelease];
}

- (id)initWithCoder:(NSCoder *)decoder
{
	self = [super init];
	if(self) {
        self.ID = [decoder decodeObjectForKey: @"SpellID"];
        self.range = [decoder decodeObjectForKey: @"Range"];
        self.name = [decoder decodeObjectForKey: @"Name"];
        self.cooldown = [decoder decodeObjectForKey: @"Cooldown"];
        self.school = [decoder decodeObjectForKey: @"School"];
        self.dispelType = [decoder decodeObjectForKey: @"DispelType"];
        self.castTime = [decoder decodeObjectForKey: @"CastTime"];
		self.mount = [decoder decodeObjectForKey: @"Mount"];
        self.mechanic = [decoder decodeObjectForKey: @"Mechanic"];
		self.speed = [decoder decodeObjectForKey: @"Speed"];
		
        if(self.name) {
            NSRange range = [self.name rangeOfString: @"html>"];
            if( ([self.name length] == 0) || (range.location != NSNotFound)) {
                // log(LOG_GENERAL, @"Name for spell %@ is invalid.", self.ID);
                self.name = nil;
            }
        }
	}
	return self;
}

-(void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject: self.ID forKey: @"SpellID"];
    [coder encodeObject: self.name forKey: @"Name"];
    [coder encodeObject: self.range forKey: @"Range"];
    [coder encodeObject: self.school forKey: @"School"];
    [coder encodeObject: self.cooldown forKey: @"Cooldown"];
    [coder encodeObject: self.dispelType forKey: @"DispelType"];
    [coder encodeObject: self.castTime forKey: @"CastTime"];
	[coder encodeObject: self.mount forKey: @"Mount"];
	[coder encodeObject: self.mechanic forKey: @"Mechanic"];
	[coder encodeObject: self.speed forKey: @"Speed"];
}

- (void)dealloc {
    self.ID = nil;
    self.range = nil;
    self.name = nil;
    self.cooldown = nil;
    self.dispelType = nil;
    self.school = nil;
    self.castTime = nil;
	self.mount = nil;
	self.mechanic = nil;
	self.speed = nil;

    [_connection release];
    [_downloadData release];
    
    [super dealloc];
}

@synthesize castTime = _castTime;

#pragma mark -

- (BOOL)isEqualToSpell: (Spell*)spell {
    return ([[self ID] unsignedIntValue] == [[spell ID] unsignedIntValue]);
}

- (NSString*)description {
    return [NSString stringWithFormat: @"<Spell \"%@\" (%@)>", self.fullName, self.ID];
}

- (NSNumber*)ID {
    NSNumber *temp = nil;
    @synchronized (@"ID") {
        temp = [_spellID retain];
    }
    return [temp autorelease];
}

- (void)setID: (NSNumber*)ID {
    id temp = nil;
    [ID retain];
    @synchronized (@"ID") {
        temp = _spellID;
        _spellID = ID;
    }
    [temp release];
}

- (NSString*)name {
    NSString *temp = nil;
    @synchronized (@"Name") {
        temp = [_name retain];
    }
    return [temp autorelease];
}

- (void)setName: (NSString*)name {
    id temp = [name retain];
    [self willChangeValueForKey: @"fullName"];
    @synchronized (@"Name") {
        temp = _name;
        _name = name;
    }
    [self didChangeValueForKey: @"fullName"];
    [temp release];
}

- (NSNumber*)range {
    NSNumber *temp = nil;
    @synchronized (@"Range") {
        temp = [_range retain];
    }
    return [temp autorelease];
}
- (void)setRange: (NSNumber*)range {
    id temp = nil;
    [range retain];
    @synchronized (@"Range") {
        temp = _range;
        _range = range;
    }
    [temp release];
}

- (NSNumber*)cooldown {
    NSNumber *temp = nil;
    @synchronized (@"Cooldown") {
        temp = [_cooldown retain];
    }
    return [temp autorelease];
}

- (void)setCooldown: (NSNumber*)cooldown {
    id temp = nil;
    [cooldown retain];
    @synchronized (@"Cooldown") {
        temp = _cooldown;
        _cooldown = cooldown;
    }
    [temp release];
}

- (NSString*)school {
    NSString *temp = nil;
    @synchronized (@"School") {
        temp = [_school retain];
    }
    return [temp autorelease];
}

- (void)setSchool: (NSString*)school {
    id temp = nil;
    [school retain];
    @synchronized (@"School") {
        temp = _school;
        _school = school;
    }
    [temp release];
}

- (NSString*)mechanic {
    NSString *temp = nil;
    @synchronized (@"Mechanic") {
        temp = [_mechanic retain];
    }
    return [temp autorelease];
}

- (void)setMechanic: (NSString*)mechanic {
    id temp = nil;
    [mechanic retain];
    @synchronized (@"Mechanic") {
        temp = _mechanic;
        _mechanic = mechanic;
    }
    [temp release];
}

- (NSString*)dispelType {
    NSString *temp = nil;
    @synchronized (@"DispelType") {
        temp = [_dispelType retain];
    }
    return [temp autorelease];
}

- (void)setDispelType: (NSString*)dispelType {
    id temp = nil;
    [dispelType retain];
    @synchronized (@"DispelType") {
        temp = _dispelType;
        _dispelType = dispelType;
    }
    [temp release];
}

- (NSString*)fullName {
    NSString *name = nil;
    @synchronized(@"Name") {
        name = self.name;
    }
    return name;
}

- (NSNumber*)mount {
    NSNumber *temp = nil;
    @synchronized (@"Mount") {
        temp = [_mount retain];
    }
    return [temp autorelease];
}

- (void)setMount: (NSNumber*)mount {
    id temp = nil;
    [mount retain];
    @synchronized (@"Mount") {
        temp = _mount;
        _mount = mount;
    }
    [temp release];
}

- (NSNumber*)speed {
    NSNumber *temp = nil;
    @synchronized (@"Speed") {
        temp = [_speed retain];
    }
    return [temp autorelease];
}

- (void)setSpeed: (NSNumber*)speed {
    id temp = nil;
    [speed retain];
    @synchronized (@"Speed") {
        temp = _speed;
        _speed = speed;
    }
    [temp release];
}

- (BOOL)isInstant {
    if(!self.castTime) return NO;
    
    if( [self.castTime isEqualToNumber: [NSNumber numberWithFloat: 0]] )
        return YES;
    return NO;
}

- (BOOL)isMount {
	if ( [self.mechanic isEqualToString:@"Mounted"] ){
		return YES;
	}
	
	if ( [self.mount intValue] == MOUNT_AIR || [self.mount intValue] == MOUNT_GROUND) {
		return YES;
	}
	
	return NO;
}

#pragma mark -

//#define NAME_SEPARATOR      @"<table class=ttb width=300><tr><td colspan=2>"
//#define RANGE_SEPARATOR     @"<th>Range</th>		<td>"
//#define COOLDOWN_SEPARATOR  @"<tr><th>Cooldown</th><td>"

#define NAME_SEPARATOR      @"<title>"
#define SCHOOL_SEPARATOR    @"School</th><td>"
#define MECHANIC_SEPARATOR	@"Mechanic</th><td>"
#define DISPEL_SEPARATOR    @"Dispel type</th><td style=\"border-bottom: 0\">"
#define COST_SEPARATOR      @"Cost</th><td style=\"border-top: 0\">"
#define RANGE_SEPARATOR     @"<th>Range</th><td>"
#define CASTTIME_SEPARATOR  @"<th>Cast time</th><td>"
#define COOLDOWN_SEPARATOR  @"<th>Cooldown</th><td>"
#define GLOBAL_COOLDOWN_SEPARATOR   @"<div style=\"width: 65%; float: right\">Global cooldown: "
#define MOUNT				@"Apply Aura: Mounted"
#define MOUNT_FAST			@"Apply Aura: Mod Speed Mounted"
#define MOUNT_AIR			@"Apply Aura: Mod Speed Mounted Flight"
#define MOUNT_GROUND_SPEED	@"<td>Increases speed by "
#define MOUNT_AIR_SPEED		@"<td>Increases flight speed by "

- (void)reloadSpellData {
    
    if([[self ID] intValue] < 0 || [[self ID] intValue] > MaxSpellID)
        return;
    
    [_connection cancel];
    [_connection release];
    _connection = [[NSURLConnection alloc] initWithRequest: [NSURLRequest requestWithURL: [NSURL URLWithString: [NSString stringWithFormat: @"http://wowhead.com/?spell=%@", [self ID]]]] delegate: self];
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
	
	// The encoding failed?  O noes!  Lets try another! Fix from GO
	if ( !wowhead || [wowhead length] == 0 ){
		wowhead = [[[NSString alloc] initWithData: _downloadData encoding: NSASCIIStringEncoding] autorelease];
	}
	
    // release the connection, and the data object
    [_connection release];  _connection = nil;
    [_downloadData release]; _downloadData = nil;
    
    // parse out the name
    if(wowhead && [wowhead length]) {
        NSScanner *scanner = [NSScanner scannerWithString: wowhead];
        
        // check to see if this is a valid spell
        if( ([scanner scanUpToString: @"Error - Wowhead" intoString: nil]) && ![scanner isAtEnd]) {
            int spellID = [[self ID] intValue];
            switch(spellID) {
                case 5302:
                    self.name = @"Defensive State";
                    break;
                case 30794:
                    self.name = @"Summoned Imp";
                    break;
                case 24868:
                    self.name = @"Predatory Strikes";
                    break;
                default:
                    self.name = @"[Unknown]";
                    break;
            }
            
            log(LOG_GENERAL, @"Spell %d does not exist on wowhead.", spellID);
            return;
        } else {
            if( [scanner scanUpToString: @"Bad Request" intoString: nil] && ![scanner isAtEnd]) {
                int spellID = [[self ID] intValue];
                log(LOG_GENERAL, @"Error loading spell %d.", spellID);
                return;
            } else {
                [scanner setScanLocation: 0];
            }
        }
        
        // get the spell name
        int scanSave = [scanner scanLocation];
        if([scanner scanUpToString: NAME_SEPARATOR intoString: nil] && [scanner scanString: NAME_SEPARATOR intoString: nil]) {
            NSString *newName = nil;
            if([scanner scanUpToString: @" - Spell" intoString: &newName]) {
                if(newName && [newName length]) {
                    self.name = newName;
                } else {
                    self.name = @"";
                }
            }
        } else {
            [scanner setScanLocation: scanSave]; // some spells dont have ranks
        }
		
		// if it's a mount, see if we have a ground speed?
        scanSave = [scanner scanLocation];
        if([scanner scanUpToString: MOUNT_GROUND_SPEED intoString: nil] && [scanner scanString: MOUNT_GROUND_SPEED intoString: nil]) {
            NSString *string  = nil;
            if([scanner scanUpToString: @"%.</td>" intoString: &string] && string) {
                self.speed = [NSNumber numberWithInt:[string intValue]];
            } else{
                self.speed = nil;
			}
        }
		[scanner setScanLocation: scanSave];
		
		// check to see if we have an air speed?
		// if it's a mount, see if we have a ground speed?
        scanSave = [scanner scanLocation];
        if([scanner scanUpToString: MOUNT_AIR_SPEED intoString: nil] && [scanner scanString: MOUNT_AIR_SPEED intoString: nil]) {
            NSString *string  = nil;
            if([scanner scanUpToString: @"%.</td>" intoString: &string] && string) {
                self.speed = [NSNumber numberWithInt:[string intValue]];
            }
        }
		[scanner setScanLocation: scanSave];
		
        // get spell school
        scanSave = [scanner scanLocation];
        if([scanner scanUpToString: SCHOOL_SEPARATOR intoString: nil] && [scanner scanString: SCHOOL_SEPARATOR intoString: nil]) {
            NSString *string  = nil;
            if([scanner scanUpToString: @"</td>" intoString: &string] && string) {
                self.school = string;
            } else
                self.school = @"None";
        } else {
            [scanner setScanLocation: scanSave]; // some spells dont have ranks
        }
		
		// get spell mechanic
        scanSave = [scanner scanLocation];
        if([scanner scanUpToString: MECHANIC_SEPARATOR intoString: nil] && [scanner scanString: MECHANIC_SEPARATOR intoString: nil]) {
            NSString *string  = nil;
            if([scanner scanUpToString: @"</td>" intoString: &string] && string) {
                self.mechanic = string;
            } else
                self.mechanic = @"None";
        } else {
            [scanner setScanLocation: scanSave];
        }
        
        // get dispel type
        scanSave = [scanner scanLocation];
        if([scanner scanUpToString: DISPEL_SEPARATOR intoString: nil] && [scanner scanString: DISPEL_SEPARATOR intoString: nil]) {
            if(![scanner scanString: @"<span" intoString: nil]) {
                NSString *dispelType  = nil;
                if([scanner scanUpToString: @"</td>" intoString: &dispelType] && dispelType) {
                    self.dispelType = dispelType;
                } else 
                    self.dispelType = @"None";
            }
        } else {
            [scanner setScanLocation: scanSave]; // some spells dont have ranks
        }
        
        // get the range
        scanSave = [scanner scanLocation];
        if([scanner scanUpToString: RANGE_SEPARATOR intoString: nil] && [scanner scanString: RANGE_SEPARATOR intoString: NULL]) {
            int range = 0;
            if([scanner scanInt: &range]) {
                self.range = [NSNumber numberWithUnsignedInt: range];
            } else
                self.range = [NSNumber numberWithInt: 0];
        } else {
            [scanner setScanLocation: scanSave]; // some spells dont have ranks
        }
        
        
        // get the cast time
        scanSave = [scanner scanLocation];
        if([scanner scanUpToString: CASTTIME_SEPARATOR intoString: nil] && [scanner scanString: CASTTIME_SEPARATOR intoString: NULL]) {
            float castTime = 0;
            if([scanner scanFloat: &castTime]) {
                self.castTime = [NSNumber numberWithFloat: castTime];
                // log(LOG_GENERAL, @"Loaded cast time %@ for spell %@", self.castTime, self);
            } else {
                if([scanner scanString: @"Instant" intoString: nil]) {
                    self.castTime = [NSNumber numberWithFloat: 0];
                    // log(LOG_GENERAL, @"Loaded cast time instant! for spell %@", self);
                } else {
                    // log(LOG_GENERAL, @"Got nothing for %@", self);
                    self.castTime = nil;
                }
            }
        } else {
            // log(LOG_GENERAL, @"No cast time entry for %@", self);
            [scanner setScanLocation: scanSave];
            self.castTime = nil;
        }
        
        // get cooldown
        scanSave = [scanner scanLocation];
        if([scanner scanUpToString: COOLDOWN_SEPARATOR intoString: nil] && [scanner scanString: COOLDOWN_SEPARATOR intoString: NULL]) {
        
            if([scanner scanUpToString: GLOBAL_COOLDOWN_SEPARATOR intoString: nil] && [scanner scanString: GLOBAL_COOLDOWN_SEPARATOR intoString: NULL]) {
                
                float cooldown = 0;
                if([scanner scanFloat: &cooldown]) {
                    if([scanner scanString: @"minute" intoString: nil]) {
                        cooldown = cooldown*60;
                    } else if([scanner scanString: @"hour" intoString: nil]) {
                        cooldown = cooldown*60*60;
                    }
                } else {
                    BOOL foundCooldown = NO;
                    // looks like wowhead keeps changing it's cooldown format
                    // <th>Cooldown</th><td><!--<div style="width: 65%; float: right">Global cooldown: <span class="q0">n/a</span></div>-->25 seconds</td>
                    if([scanner scanUpToString: @"</div>-->" intoString: nil] && [scanner scanString: @"</div>-->" intoString: NULL]) {
                        foundCooldown = YES;
                    } else {
                        // <th>Cooldown</th><td><div style="width: 65%; float: right">Global cooldown: <span class="q0">n/a</span></div>8 seconds</td>
                        if([scanner scanUpToString: @"</div>" intoString: nil] && [scanner scanString: @"</div>" intoString: NULL]) {
                            foundCooldown = YES;
                        }
                    }
                    
                    if(foundCooldown && [scanner scanFloat: &cooldown]) {
                        if([scanner scanString: @"minute" intoString: nil]) {
                            cooldown = cooldown*60;
                        } else if([scanner scanString: @"hour" intoString: nil]) {
                            cooldown = cooldown*60*60;
                        }
                    }
                }
                
                self.cooldown = [NSNumber numberWithFloat: cooldown];
            }
        } else {
            [scanner setScanLocation: scanSave]; // some spells dont have cooldowns
			
			// log(LOG_GENERAL, @"Loaded: %@; %@ yards; %@ seconds; school: %@; dispel: %@", self.name, self.range, self.cooldown, self.school, self.dispelType);
        }
		
		
		// get if this is a mount spell
        scanSave = [scanner scanLocation];
        if([scanner scanUpToString: MOUNT intoString: nil] && [scanner scanString: MOUNT intoString: NULL]) {
			// Find out if this is an air mount
			if([scanner scanUpToString: MOUNT_AIR intoString: nil] && [scanner scanString: MOUNT_AIR intoString: NULL]) {
				self.mount = [NSNumber numberWithInt:2];	 
			}
			else{
				self.mount = [NSNumber numberWithInt:1];
			}
        } else {
			self.mount = [NSNumber numberWithInt:0];
        }
		[scanner setScanLocation: scanSave];
		
		if ( [self.mount intValue] > 0 ){
			//log(LOG_GENERAL, @"mount: %@  %@ %@", [self ID], self.mount, self.mechanic);
		}
		
		// get if this is a fast mount
        scanSave = [scanner scanLocation];
        if([scanner scanUpToString: MOUNT_FAST intoString: nil] && [scanner scanString: MOUNT_FAST intoString: NULL]) {
        } else {
            // log(LOG_GENERAL, @"No cast time entry for %@", self);
            [scanner setScanLocation: scanSave];
        }
		
		// For druids (Swift or regular)
		int spellID = [[self ID] intValue];
		if ( spellID == 40120 || spellID == 33943 ){
			self.mount = [NSNumber numberWithInt:2];
			
			// Swift Flight Form
			if ( spellID == 40120 ){
				self.speed = [NSNumber numberWithInt:280];
			}
			// Flight Form
			else if ( spellID == 33943 ){
				self.speed = [NSNumber numberWithInt:150];
			}
		}
    }
	else{
		log(LOG_GENERAL, @"[Spell] Error grabbing data for Spell ID: %@", [self ID]);
	}
}


@end
