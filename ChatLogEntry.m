//
//  ChatLogController.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 4/3/09.
//  Copyright 2009 Savory Software, LLC. All rights reserved.
//

#import "ChatLogEntry.h"

#define ChatEntryTypeKey @"Type"
#define ChatEntryChannelKey @"Channel"
#define ChatEntryPlayerNameKey @"Player Name"
#define ChatEntryTextKey @"Text"

@implementation ChatLogEntry

- (id) init
{
    self = [super init];
    if (self != nil) {
        self.sequence = nil;
        self.attributes = nil;
        self.dateStamp = nil;
        self.timeStamp = nil;
    }
    return self;
}

- (void) dealloc
{
    self.sequence = nil;
    self.attributes = nil;
    self.dateStamp = nil;
    self.timeStamp = nil;
    [super dealloc];
}

+ (ChatLogEntry*)entryWithSequence: (NSInteger)sequence timeStamp: (NSInteger)timeStamp attributes: (NSDictionary*)attribs {
    ChatLogEntry *newEntry = [[ChatLogEntry alloc] init];
    newEntry.dateStamp = [NSDate date];
    newEntry.timeStamp = [NSNumber numberWithInteger: timeStamp];
    newEntry.sequence = [NSNumber numberWithInteger: sequence];
    newEntry.attributes = attribs;
    
    NSString *newText = @"";
    if([newEntry.text length] && ([newEntry.text rangeOfString: @"|c"].location != NSNotFound)) {
        // there is likely an link in this text.  try and parse it/them out...
        // " |cff1eff00|Hitem:38072:0:0:0:0:0:0:1897089536:75|h[Thunder Capacitor]|h|r"
        // " |cff4e96f7|Htalent:1405:-1|h[Improved Retribution Aura]|h|r
        
        NSScanner *scanner = [NSScanner scannerWithString: newEntry.text];
        [scanner setCaseSensitive: YES];
        [scanner setCharactersToBeSkipped: nil]; 
        while(1) {
            NSString *temp = nil;
            if([scanner scanUpToString: @"|c" intoString: &temp]) {
                newText = [newText stringByAppendingString: temp];
                if([scanner scanUpToString: @"|h" intoString: nil] && [scanner scanString: @"|h" intoString: nil]) {
                    if([scanner scanUpToString: @"|h|r" intoString: &temp] && [scanner scanString: @"|h|r" intoString: nil]) {
                        newText = [newText stringByAppendingString: temp];
                    } else {
                        break;
                    }
                } else {
                    break;
                }
            } else {
                break;
            }
        }
    }
    
    if([newText length]) {
        NSMutableDictionary *newAttribs = [NSMutableDictionary dictionaryWithDictionary: newEntry.attributes];
        [newAttribs setObject: newText forKey: ChatEntryTextKey];
        newEntry.attributes = newAttribs;
    }
    
    return [newEntry autorelease];
}

- (BOOL)isEqual: (id)object {
    if( [object isKindOfClass: [self class]] ) {
        ChatLogEntry *other = (ChatLogEntry*)object;
        return ([self.sequence isEqualToNumber: other.sequence] &&
                [self.type isEqualToString: other.type] &&
                [self.channel isEqualToString: other.channel] &&
                [self.playerName isEqualToString: other.playerName] &&
                [self.text isEqualToString: other.text]);
    }
    return NO;
}

+ (NSString*)nameForChatType: (NSString*)type {
    NSInteger chan = [type integerValue];
    switch(chan) {
        case 0:
            return @"Addon"; break;
        case 1:
            return @"Say"; break;
        case 2:
            return @"Party"; break;
        case 3:
            return @"Raid"; break;
        case 4:
            return @"Guild"; break;
        case 5:
            return @"Officer"; break;
        case 6:
            return @"Yell"; break;
        case 7:
            return @"Whisper (Received)"; break;
        case 8:
            return @"Whisper (Mob)"; break;
        case 9:
            return @"Whisper (Sent)"; break;
        case 10:
            return @"Emote"; break;
        case 11:
            return @"Emote (Text)"; break;
        case 12:
            return @"Monster (Say)"; break;
        case 13:
            return @"Monster (Party)"; break;
        case 14:
            return @"Monster (Yell)"; break;
        case 15:
            return @"Monster (Whisper)"; break;
        case 16:
            return @"Monster (Emote)"; break;
        case 17:
            return @"Channel"; break;
        case 18:
            return @"Channel (Join)"; break;
        case 19:
            return @"Channel (Leave)"; break;
        case 20:
            return @"Channel (List)"; break;
        case 21:
            return @"Channel (Notice)"; break;
        case 22:
            return @"Channel (Notice User)"; break;
        case 23:
            return @"AFK"; break;
        case 24:
            return @"DND"; break;
        case 25:
            return @"Ignored"; break;
        case 26:
            return @"Skill"; break;
        case 27:
            return @"Loot"; break;
        case 28:
            return @"System"; break;
            // lots of unknown in here [29-34]
        case 35:
            return @"BG (Neutral)"; break;
        case 36:
            return @"BG (Alliance)"; break;
        case 37:
            return @"BG (Horde)"; break;
        case 38:
            return @"Combat Faction Change (wtf?)"; break;
        case 39:
            return @"Raid Leader"; break;
        case 40:
            return @"Raid Warning"; break;
        case 41:
            return @"Raid Warning (Boss Whisper)"; break;
        case 42:
            return @"Raid Warning (Boss Emote)"; break;
        case 43:
            return @"Filtered"; break;
        case 44:
            return @"Battleground"; break;
        case 45:
            return @"Battleground (Leader)"; break;
        case 46:
            return @"Restricted"; break;
		case 53:
            return @"RealChat (sent)"; break;
		case 54:
            return @"RealChat (received)"; break;
        // case 47 - 56, channels 1 through 10?
    }
    return [NSString stringWithFormat: @"Unknown (%@)", type];
}

@synthesize passNumber = _passNumber;
@synthesize relativeOrder = _relativeOrder;

@synthesize sequence = _sequence;
@synthesize timeStamp = _timeStamp;
@synthesize dateStamp = _dateStamp;
@synthesize attributes = _attributes;

- (NSString*)type {
    return [self.attributes objectForKey: ChatEntryTypeKey];
}

- (NSString*)typeName {
    return [isa nameForChatType: self.type];
}

- (NSString*)typeVerb {
    switch([self.type integerValue]) {
        case 1:
		case 53:
            return @"says"; break;
        case 6:
            return @"yells"; break;
		case 54:
        case 7:
        case 8:
            return @"whispers"; break;
    }
    return nil;
}

- (NSString*)channel {
    return [self.attributes objectForKey: ChatEntryChannelKey];
}

- (NSString*)playerName {
    return [self.attributes objectForKey: ChatEntryPlayerNameKey];
}

- (NSString*)text {
    return [self.attributes objectForKey: ChatEntryTextKey];
}

- (NSString*)description {
    return [NSString stringWithFormat: @"<%@ -%u:%u- [%@] %@: \"%@\"%@>", isa, self.passNumber, self.relativeOrder, [ChatLogEntry nameForChatType: self.type], self.playerName, self.text, ([self.channel length] ? [NSString stringWithFormat: @" (%@)", self.channel] : @"")];
}

- (BOOL)isEmote {
    NSInteger type = [self.type integerValue];
    return ((type == 10) || (type == 11));
}

- (BOOL)isSpoken {
    NSInteger type = [self.type integerValue];
    return ((type == 1) || (type == 6) || [self isWhisperReceived]);
}

- (BOOL)isWhisper {
    NSInteger type = [self.type integerValue];
    return ((type == 7) || (type == 8) || (type == 9));
}

- (NSArray*)spokenTypes { 
    return [NSArray arrayWithObjects: @"1", @"6", nil];
}

- (NSArray*)whisperTypes {
    return [NSArray arrayWithObjects: @"7", @"8", @"9", @"53", @"54", nil];
}

- (BOOL)isWhisperSent {
    NSInteger type = [self.type integerValue];
    return (type == 9);
}

- (BOOL)isWhisperReceived {
    NSInteger type = [self.type integerValue];
    return ((type == 7) || (type == 8));
}

- (BOOL)isChannel {
    NSInteger type = [self.type integerValue];
    return ((type >= 17) && (type <= 22) && [[self channel] length]);
}

- (NSString*)wellFormattedText {
    
    if([self isEmote]) {
        return [NSString stringWithFormat: @"%@ %@", [self playerName], [self text]];
    } else if([self isChannel]) {
        return [NSString stringWithFormat: @"[%@] [%@] %@", [self channel], [self playerName], [self text]];
    } else if([self isSpoken]) {
        return [NSString stringWithFormat: @"[%@] %@: %@", [self playerName], [self typeVerb], [self text]];
    } else if([self isWhisperSent]) {
        return [NSString stringWithFormat: @"To [%@]: %@", [self playerName], [self text]];
    }
    return [NSString stringWithFormat: @"[%@] [%@] %@", [self playerName], [self typeName], [self text]];
}

@end
