//
//  ChatLogController.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 4/3/09.
//  Copyright 2009 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Controller;
@class ChatLogEntry;
@class OffsetController;

#define WhisperReceived		@"WhisperReceived"

@interface ChatLogController : NSObject {
    IBOutlet Controller *controller;
	IBOutlet OffsetController *offsetController;
    
    IBOutlet NSView *view;
    IBOutlet NSTableView *chatLogTable, *whisperLogTable;
    IBOutlet NSPredicateEditor *ruleEditor;
    IBOutlet NSArrayController *chatActionsController;
    IBOutlet NSPanel *relayPanel;
	
	IBOutlet NSButton *enableGrowlNotifications;

    NSUInteger passNumber;
    BOOL _shouldScan, _lastPassFoundChat, _lastPassFoundWhisper;
    NSMutableArray *_chatLog, *_chatActions, *_whisperLog;
    NSSize minSectionSize, maxSectionSize;
    NSDateFormatter *_timestampFormat;
    NSSortDescriptor *_passNumberSortDescriptor;
    NSSortDescriptor *_relativeOrderSortDescriptor;
	NSMutableDictionary *_whisperHistory;				// Tracks player name with # of whispers
}

// Controller interface
@property (readonly) NSView *view;
@property (readonly) NSString *sectionTitle;
@property NSSize minSectionSize;
@property NSSize maxSectionSize;

- (IBAction)something: (id)sender;
- (IBAction)createChatAction: (id)sender;
- (IBAction)sendEmail: (id)sender;

- (IBAction)openRelayPanel: (id)sender;
- (IBAction)closeRelayPanel: (id)sender;

- (BOOL)sendLogEntry: (ChatLogEntry*)logEntry toiChatBuddy: (NSString*)buddyName;
- (BOOL)sendLogEntries: (NSArray*)logEntries toiChatBuddy: (NSString*)buddyName;

- (BOOL)sendLogEntry: (ChatLogEntry*)logEntry toEmailAddress: (NSString*)emailAddress;
- (BOOL)sendLogEntries: (NSArray*)logEntries toEmailAddress: (NSString*)emailAddress;

- (void)clearWhisperHistory;

@property (readonly, retain) NSMutableArray *chatActions;

@property (readwrite, assign) BOOL shouldScan;
@property (readwrite, assign) BOOL lastPassFoundChat;

@end
