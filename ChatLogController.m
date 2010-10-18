//
//  ChatLogController.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 4/3/09.
//  Copyright 2009 Savory Software, LLC. All rights reserved.
//

#import "ChatLogController.h"

#import "Controller.h"
#import "MemoryAccess.h"
#import "PlayerDataController.h"
#import "OffsetController.h"

#import "Offsets.h"

#import "ChatLogEntry.h"
#import "ChatAction.h"

#import <Message/NSMailDelivery.h>
#import <ScriptingBridge/ScriptingBridge.h>
#import <Foundation/NSAppleEventDescriptor.h>
#import "Mail.h"    // http://developer.apple.com/mac/library/samplecode/SBSendEmail
#import "iChat.h"   // http://developer.apple.com/mac/library/samplecode/iChatStatusFromApplication

#define ChatLog_CounterOffset       0x8
#define ChatLog_TimestampOffset     0xC
#define ChatLog_UnitGUIDOffset      0x10
#define ChatLog_UnitNameOffset      0x1C
#define ChatLog_UnitNameLength      0x30
#define ChatLog_DescriptionOffset   0x4C
#define ChatLog_NextEntryOffset     0x17BC

#define ChatLog_TextOffset 0xBB8

@interface ChatLogController (Internal)

- (void)kickOffScan;
- (BOOL)chatLogContainsEntry: (ChatLogEntry*)entry;
- (void)addWhisper: (ChatLogEntry *)entry;

@end

@implementation ChatLogController

+ (void)initialize {
    
    NSDictionary *defaultValues = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSNumber numberWithBool: NO],       @"ChatLogRelayMessages",
                                   [NSNumber numberWithBool: NO],       @"ChatLogRelayViaiChat",
                                   [NSNumber numberWithBool: NO],       @"ChatLogRelayViaMail",
                                   [NSNumber numberWithBool: YES],      @"ChatLogRelaySendAll", nil];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults: defaultValues];
    [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues: defaultValues];
}

- (id) init
{
    self = [super init];
    if (self != nil) {
        passNumber = 0;
        self.shouldScan = NO;
        self.lastPassFoundChat = NO;
		_lastPassFoundWhisper = NO;
        _chatLog = [[NSMutableArray array] retain];
		_whisperLog = [[NSMutableArray array] retain];
        _chatActions = [[NSMutableArray array] retain];
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(memoryIsValid:) name: MemoryAccessValidNotification object: nil];
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(memoryIsInvalid:) name: MemoryAccessInvalidNotification object: nil];
		
		_whisperHistory = [[NSMutableDictionary dictionary] retain];
        
        _timestampFormat = [[NSDateFormatter alloc] init];
        [_timestampFormat setDateStyle: NSDateFormatterNoStyle];
        [_timestampFormat setTimeStyle: NSDateFormatterShortStyle];
        
        _passNumberSortDescriptor = [[NSSortDescriptor alloc] initWithKey: @"passNumber" ascending: YES];
        _relativeOrderSortDescriptor = [[NSSortDescriptor alloc] initWithKey: @"relativeOrder" ascending: YES];
        
        [NSBundle loadNibNamed: @"ChatLog" owner: self];
        
        [self kickOffScan];
    }
    return self;
}

- (void)awakeFromNib {
    self.minSectionSize = [self.view frame].size;
    self.maxSectionSize = NSZeroSize;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    [_timestampFormat release];
    [_chatLog release];
	[_whisperLog release];
	[_whisperHistory release];
    [super dealloc];
}

@synthesize view;
@synthesize minSectionSize;
@synthesize maxSectionSize;

- (NSString*)sectionTitle {
    return @"Other Players";
}

@synthesize chatActions = _chatActions;
@synthesize shouldScan = _shouldScan;
@synthesize lastPassFoundChat = _lastPassFoundChat;

- (void)memoryIsValid: (NSNotification*)notification {
    self.shouldScan = YES;
}

- (void)memoryIsInvalid: (NSNotification*)notification {
    self.shouldScan = NO;
}

// this is run in a separate thread
- (void)scanChatLog {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	UInt32 offset = [offsetController offset:@"CHATLOG_START"];

    NSMutableArray *chatEntries = [NSMutableArray array];
    MemoryAccess *memory = [controller wowMemoryAccess];
	//NSDate *date = [NSDate date];
    //[memory resetLoadCount];
    if(self.shouldScan && memory) {
        if(self.lastPassFoundChat) {
            passNumber++;
        }
        self.lastPassFoundChat = NO;
        
        int i;
        UInt32 highestSequence = 0, foundAt = 0, finishedAt = 0;
        for(i = 0; i< 60; i++) {
            finishedAt = i;
            char buffer[400];
            UInt32 logStart = offset + ChatLog_NextEntryOffset*i;
            if([memory loadDataForObject: self atAddress: logStart Buffer: (Byte *)&buffer BufLength: sizeof(buffer)-1])
            {
                //GUID unitGUID = *(GUID*)(buffer + ChatLog_UnitGUIDOffset);
                UInt32 sequence = *(UInt32*)(buffer + ChatLog_CounterOffset);
                //UInt32 timestamp = *(UInt32*)(buffer + ChatLog_TimestampOffset);
                
                // track highest sequence number
                if(sequence > highestSequence) {
                    highestSequence = sequence;
                    foundAt = i;
                }
                NSString *chatEntry = [NSString stringWithUTF8String: buffer];
				//log(LOG_GENERAL, @"Chat found: %@", chatEntry );
				
                if([chatEntry length]) {
                    // "Type: [17], Channel: [General - Whatev], Player Name: [PlayerName], Text: [Text]"
                    NSMutableDictionary *chatComponents = [NSMutableDictionary dictionary];
                    for(NSString *component in [chatEntry componentsSeparatedByString: @"], "]) {
                        NSArray *keyValue = [component componentsSeparatedByString: @": ["];
                        // "Text: [blah blah blah]"
                        if([keyValue count] == 2) {
                            // now we have "key" and "[value]"
                            NSString *key = [keyValue objectAtIndex: 0];
                            NSString *value = [[keyValue objectAtIndex: 1] stringByTrimmingCharactersInSet: [NSCharacterSet characterSetWithCharactersInString: @"[]"]];
                            [chatComponents setObject: value forKey: key];
                        } else {
                            // bad data
                            //log(LOG_GENERAL, @"Throwing out bad data: \"%@\"", component);
                        }
                    }
                    if([chatComponents count]) {
                        ChatLogEntry *newEntry = [ChatLogEntry entryWithSequence: i timeStamp: sequence attributes: chatComponents];
                        if(newEntry) {
                            [chatEntries addObject: newEntry];
                        }
                    }
                } else {
                    break;
                }
            }
        }
        
        for(ChatLogEntry *entry in chatEntries) {
            [entry setPassNumber: passNumber];
            NSUInteger sequence = [[entry sequence] unsignedIntegerValue];
            if(sequence >= foundAt) {
                [entry setRelativeOrder: sequence - foundAt];
            } else {
                [entry setRelativeOrder: 60 - foundAt + sequence];
            }
        }
        [chatEntries sortUsingDescriptors: [NSArray arrayWithObject: _relativeOrderSortDescriptor]];
    }
	

	//log(LOG_GENERAL, @"[Chat] New chat scan took %.2f seconds and %d memory operations.", [date timeIntervalSinceNow]*-1.0, [memory loadCount]);
	
    
    [self performSelectorOnMainThread: @selector(scanCompleteWithNewEntries:) withObject: chatEntries waitUntilDone: YES];
    [pool drain];
}

- (BOOL)chatLogContainsEntry: (ChatLogEntry*)entry {
    BOOL contains = NO;
    @synchronized(_chatLog) {
        contains = [_chatLog containsObject: entry];
    }
    return contains;
}

- (void)scanCompleteWithNewEntries: (NSArray*)newEntries {
    if([newEntries count]) {
        // NSMutableArray *actualNewEntries = [NSMutableArray array];
        int lastRow = [_chatLog count] - 1;
        for(ChatLogEntry *entry in newEntries) {
            if(![_chatLog containsObject: entry]) {
                // NSLog(@"%@", entry);
                [_chatLog addObject: entry];
                self.lastPassFoundChat = YES;
                
                if(passNumber > 0 && ![entry isWhisperSent]) {
                    if(![controller isWoWFront]) {
                        if( [enableGrowlNotifications state] && [controller sendGrowlNotifications] && [GrowlApplicationBridge isGrowlInstalled] && [GrowlApplicationBridge isGrowlRunning]) {
                            [GrowlApplicationBridge notifyWithTitle: [entry isSpoken] ? [NSString stringWithFormat: @"%@ %@...", [entry playerName], [entry typeVerb]] : [NSString stringWithFormat: @"%@ (%@)", [entry playerName], [entry isChannel] ? [entry channel] : [entry typeName]]
                                                        description: [entry text]
                                                   notificationName: @"PlayerReceivedMessage"
                                                           iconData: [[NSImage imageNamed: @"Trade_Engraving"] TIFFRepresentation]
                                                           priority: [entry isWhisperReceived] ? 100 : 0
                                                           isSticky: [entry isWhisperReceived] ? YES : NO
                                                       clickContext: nil];             
                        }
                    }
					
					// Fire off a notification - Whisper received!
					if ( [entry isWhisperReceived] ){
						[[NSNotificationCenter defaultCenter] postNotificationName: WhisperReceived object: entry];
						[self addWhisper:entry];
					}
                    
                    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                    if([defaults boolForKey: @"ChatLogRelayMessages"]) {
                        // user wants to relay messages...
                        BOOL sendAll = [defaults boolForKey: @"ChatLogRelaySendAll"];
                        if([defaults boolForKey: @"ChatLogRelayViaiChat"]) {
                            // send via iChat
                            NSString *screenName = [defaults stringForKey: @"ChatLogRelayScreenName"];
                            if(sendAll) {
                                [self sendLogEntry: entry toiChatBuddy: screenName];
                            } else {
                                NSPredicate *predicate = [NSKeyedUnarchiver unarchiveObjectWithData: [defaults objectForKey: @"ChatLogRelayPredicate"]];
                                if([predicate evaluateWithObject: entry]) {
                                    [self sendLogEntry: entry toiChatBuddy: screenName];
                                }
                            }
                        }
                        if([defaults boolForKey: @"ChatLogRelayViaMail"]) {
                            // send via Mail/email
                            NSString *emailAddress = [defaults stringForKey: @"ChatLogRelayEmailAddress"];
                            if(sendAll) {
                                [self sendLogEntry: entry toEmailAddress: emailAddress];
                            } else {
                                NSPredicate *predicate = [NSKeyedUnarchiver unarchiveObjectWithData: [defaults objectForKey: @"ChatLogRelayPredicate"]];
                                if([predicate evaluateWithObject: entry]) {
                                    [self sendLogEntry: entry toEmailAddress: emailAddress];
                                }
                            }
                        }
                    }
                }
            }
			
			// add a whisper?
			if ( ![_whisperLog containsObject: entry] && [entry isWhisperReceived] ){
				[_whisperLog addObject: entry];
				_lastPassFoundWhisper = YES;
			}
        }
		
		if ( _lastPassFoundWhisper ){
			[_whisperLog sortUsingDescriptors: [NSArray arrayWithObjects: _passNumberSortDescriptor, _relativeOrderSortDescriptor, nil]];
            [whisperLogTable reloadData];
			_lastPassFoundWhisper = NO;
		}
        
        if(self.lastPassFoundChat) {
            [_chatLog sortUsingDescriptors: [NSArray arrayWithObjects: _passNumberSortDescriptor, _relativeOrderSortDescriptor, nil]];
            [chatLogTable reloadData];
            
            // if the previous last row of chat was visible, then we want to scroll the table down
            // if it was not visible, then we will not scroll.
            NSRange rowsInRect = [chatLogTable rowsInRect: [chatLogTable visibleRect]];
            int firstVisibleRow = rowsInRect.location, lastVisibleRow = rowsInRect.location + rowsInRect.length;
            if((passNumber == 0) || (lastRow >= 0 && (lastRow >= firstVisibleRow) && (lastRow <= lastVisibleRow))) {
                [chatLogTable scrollRowToVisible: [_chatLog count] - 1];
            }
        }
    }
    [self performSelector: @selector(kickOffScan) withObject: nil afterDelay: 1.0];
}

- (void)kickOffScan {
    [self performSelectorInBackground: @selector(scanChatLog) withObject: nil];
}

#pragma mark -

- (BOOL)sendMessage: (NSString*)message toiChatBuddy: (NSString*)buddyName {
    if(![message length] || ![buddyName length])
        return NO;
    
    iChatApplication *iChat = [SBApplication applicationWithBundleIdentifier:@"com.apple.iChat"];
    
    // Ultimately we need to find a buddy to open a new chat, or an existing chat, to send the message
    
    // We're looking for any AIM service
    BOOL foundService = NO;
    for (iChatService *service in [iChat services]) {
        // Use the first connected AIM service we find
        if (service.connectionStatus == iChatConnectionStatusConnected || service.status == iChatConnectionStatusConnected) { // (service.serviceType == iChatServiceTypeAIM) && (
            foundService = YES;
            
            // we have a service, find a buddy
            iChatBuddy *sendToBuddy = nil;
            for(iChatBuddy *buddy in [service buddies]) {
                
                NSString *buddyID = [buddy id];
                if([buddyID length] && ([buddy status] != iChatAccountStatusOffline)) {
                    // buddy id: "A123456B-1234-5678-9090-B80C2D1D4092:buddyname"
                    BOOL buddyMatch = ([buddyID rangeOfString: buddyName options: NSCaseInsensitiveSearch | NSBackwardsSearch | NSAnchoredSearch].location != NSNotFound);
                    
                    if(buddyMatch) {
                        sendToBuddy = buddy;
                        break;
                    }
                }
            }
            
            if(sendToBuddy) {
                // see if there is an existing chat open with this buddy
                iChatChat *buddyChat = nil;
                for(iChatChat *chat in [service chats]) {
                    NSArray *participants = [chat participants];
                    if(([participants count] == 1) && [[(iChatBuddy*)[participants lastObject] id] isEqualToString: [sendToBuddy id]]) {
                        buddyChat = chat;
                        break;
                    }
                }
                
                @try {
                    if(buddyChat) {
                        [iChat send: message to: buddyChat];
                    } else {
                        [iChat send: message to: sendToBuddy];
                    }
                }
                @catch (NSException * e) {
                    log(LOG_GENERAL, @"Could not send chat message: %@", e);
                    return NO;
                }
                
                return YES;
                
            } else {
                log(LOG_GENERAL, @"Could not locate buddy \"%@\"!", buddyName);
            }
        }
    }
    
    if(!foundService) {
        log(LOG_GENERAL, @"Could not find active iChat service!");
    }
    
    return NO;
}
    
- (BOOL)sendLogEntries: (NSArray*)logEntries toiChatBuddy: (NSString*)buddyName {
    NSMutableString *message = [NSMutableString string];
    for(ChatLogEntry *chatEntry in logEntries) {
        [message appendFormat: @"%@\n", [chatEntry wellFormattedText]];
    }
    return [self sendMessage: message toiChatBuddy: buddyName];
}

- (BOOL)sendLogEntry: (ChatLogEntry*)logEntry toiChatBuddy: (NSString*)buddyName {
    if(!logEntry) return NO;
    return [self sendLogEntries: [NSArray arrayWithObject: logEntry] toiChatBuddy: buddyName];
}

- (BOOL)sendMessage: (NSString*)message toEmailAddress: (NSString*)emailAddress {
    if(![message length] || ![emailAddress length])
        return NO;

    if([NSMailDelivery hasDeliveryClassBeenConfigured]) {
        MailApplication *mail = [SBApplication applicationWithBundleIdentifier:@"com.apple.Mail"];
        
        // create a new outgoing message object
        NSString *subject = [NSString stringWithFormat: @"PG Chat Log: %@", [[PlayerDataController sharedController] playerName]];
        MailOutgoingMessage *emailMessage = [[[[mail classForScriptingClass:@"outgoing message"] alloc] initWithProperties: [NSDictionary dictionaryWithObjectsAndKeys:
                                                                                                                             subject,       @"subject",
                                                                                                                             message,       @"content", nil]] autorelease];
        
        // add the object to the mail app
        [[mail outgoingMessages] addObject: emailMessage];
        
        // create a new recipient and add it to the recipients list
        MailToRecipient *theRecipient = [[[[mail classForScriptingClass:@"to recipient"] alloc] initWithProperties: [NSDictionary dictionaryWithObject: emailAddress forKey: @"address"]] autorelease];
        [emailMessage.toRecipients addObject: theRecipient];
        
        // send the message
        @try {
            if([emailMessage send]) {
                return YES;
            } else {
                log(LOG_GENERAL, @"Email message could not be sent!");
            }
        }
        @catch (NSException * e) {
            log(LOG_GENERAL, @"Email message could not be sent! %@", e);
            return NO;
        }
    } else {
        log(LOG_GENERAL, @"No account is configured in Mail!");
    }
    return NO;
}

- (BOOL)sendLogEntries: (NSArray*)logEntries toEmailAddress: (NSString*)emailAddress {
    NSMutableString *message = [NSMutableString string];
    for(ChatLogEntry *chatEntry in logEntries) {
        [message appendFormat: @"%@\n", [chatEntry wellFormattedText]];
    }
    return [self sendMessage: message toEmailAddress: emailAddress];
}

- (BOOL)sendLogEntry: (ChatLogEntry*)logEntry toEmailAddress: (NSString*)emailAddress {
    if(!logEntry) return NO;
    return [self sendLogEntries: [NSArray arrayWithObject: logEntry] toEmailAddress: emailAddress];
}

#pragma mark -


- (IBAction)openRelayPanel: (id)sender {
	[NSApp beginSheet: relayPanel
	   modalForWindow: [self.view window]
		modalDelegate: nil
	   didEndSelector: nil //@selector(sheetDidEnd: returnCode: contextInfo:)
		  contextInfo: nil];
}

- (IBAction)closeRelayPanel: (id)sender {
    [NSApp endSheet: relayPanel returnCode: 1];
    [relayPanel orderOut: nil];
}

- (void)addChatAction: (ChatAction*)action {
    int num = 2;
    BOOL done = NO;
    if(![action isKindOfClass: [ChatAction class]]) return;
    if(![[action name] length]) return;
    
    // check to see if a route exists with this name
    NSString *originalName = [action name];
    while(!done) {
        BOOL conflict = NO;
        for(ChatAction *anAction in self.chatActions) {
            if( [[anAction name] isEqualToString: [action name]]) {
                [action setName: [NSString stringWithFormat: @"%@ %d", originalName, num++]];
                conflict = YES;
                break;
            }
        }
        if(!conflict) done = YES;
    }
    
    // save this route into our array
    [chatActionsController addObject: action];
    //[self willChangeValueForKey: @"chatActions"];
    //[_routes addObject: routeSet];
    //[self didChangeValueForKey: @"chatActions"];

    // update the current route
    //changeWasMade = YES;
    //[self setCurrentRouteSet: routeSet];
    //[waypointTable reloadData];
    
    // log(LOG_GENERAL, @"Added route: %@", [routeSet name]);
}

- (IBAction)createChatAction: (id)sender {
    // make sure we have a valid name
    NSString *actionName = [sender stringValue];
    if( [actionName length] == 0) {
        NSBeep();
        return;
    }
    
    // create a new route
    [self addChatAction: [ChatAction chatActionWithName: actionName]];
    [sender setStringValue: @""];
}


- (IBAction)something: (id)sender {
    NSPredicate *predicate = [[[ruleEditor predicate] retain] autorelease];
    NSLog(@"%@", predicate);
    
    if([_chatLog count] && predicate) {
        NSArray *newArray = [_chatLog filteredArrayUsingPredicate: predicate];
        NSLog(@"%@", newArray);
    }
}

- (IBAction)sendEmail: (id)sender {
    if([NSMailDelivery hasDeliveryClassBeenConfigured]) {
        ChatAction *chatAction = [[chatActionsController selectedObjects] lastObject];
        NSPredicate *predicate = [chatAction predicate];
        
        if([_chatLog count] && predicate) {
            NSArray *newArray = [_chatLog filteredArrayUsingPredicate: predicate];
            if([newArray count]) {
                return;
            }
        }
    } else {
        log(LOG_GENERAL, @"Mail delivery is NOT configured.");
    }
}


- (void)clearWhisperHistory{
	[_whisperHistory removeAllObjects];
}

// The key is our player's name!
- (void)addWhisper: (ChatLogEntry *)entry{
	
	NSString *key = [entry playerName];
	// Lets store that we got whispered!
	NSNumber *numWhispers = nil;
	if ( ![_whisperHistory objectForKey: key] ){
		numWhispers = [NSNumber numberWithInt:1];
	}
	else{
		numWhispers = [NSNumber numberWithInt:[[_whisperHistory objectForKey: key] intValue] + 1];
	}
	[_whisperHistory setObject: numWhispers forKey: key];
	
	BOOL checkWhispers = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"AlarmWhispered"] boolValue];

	// Lets check to see if the numWhispers is too high!
	if ( checkWhispers ){
		if ( [numWhispers intValue] >= [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"AlarmWhisperedTimes"] intValue] ){
			[[NSSound soundNamed: @"alarm"] play];
			log(LOG_GENERAL, @"[Chat] You have been whispered %@ times by %@. Last message: %@", numWhispers, [entry playerName], [entry text] );
		}
	}
}

#pragma mark -
#pragma mark TableView Delegate & Datasource

- (int)numberOfRowsInTableView:(NSTableView *)aTableView {
	if ( aTableView == chatLogTable )
		return [_chatLog count];
	else if ( aTableView == whisperLogTable )
		return [_whisperLog count];
	
	return 0;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
	
	// chat log
	if ( aTableView == chatLogTable ){
		
		if((rowIndex == -1) || (rowIndex >= [_chatLog count]))
			return nil;
    

        ChatLogEntry *entry = [_chatLog objectAtIndex: rowIndex];
        // [%u:%@] [%@] 
        // entry.relativeOrder, entry.timeStamp, entry.sequence, 
        return [NSString stringWithFormat: @"[%@] %@", [_timestampFormat stringFromDate: [entry dateStamp]], [entry wellFormattedText]];
	}
	else if ( aTableView == whisperLogTable ){
		if((rowIndex == -1) || (rowIndex >= [_whisperLog count]))
			return nil;
		
		
        ChatLogEntry *entry = [_whisperLog objectAtIndex: rowIndex];
        // [%u:%@] [%@] 
        // entry.relativeOrder, entry.timeStamp, entry.sequence, 
        return [NSString stringWithFormat: @"[%@] %@", [_timestampFormat stringFromDate: [entry dateStamp]], [entry wellFormattedText]];
	}
    
    return nil;
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    return NO;
}

- (BOOL)tableViewCopy: (NSTableView*)tableView {
	if ( tableView == chatLogTable ){
		NSIndexSet *rowIndexes = [tableView selectedRowIndexes];
		if([rowIndexes count] == 0) {
			return NO;
		}
		NSPasteboard *pboard = [NSPasteboard generalPasteboard];
		[pboard declareTypes: [NSArray arrayWithObjects: NSStringPboardType, nil] owner: nil];
		
		NSMutableString *stringVal = [NSMutableString string];
		int row = [rowIndexes firstIndex];
		while(row != NSNotFound) {
			[stringVal appendFormat: @"%@\n", [[_chatLog objectAtIndex: row] wellFormattedText]];
			row = [rowIndexes indexGreaterThanIndex: row];
		}
		[pboard setString: stringVal forType: NSStringPboardType];
	}
    
    return YES;
}


@end
