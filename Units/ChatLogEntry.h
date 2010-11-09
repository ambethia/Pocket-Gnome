//
//  ChatLogController.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 4/3/09.
//  Copyright 2009 Savory Software, LLC. All rights reserved.
//


#import <Cocoa/Cocoa.h>


@interface ChatLogEntry : NSObject {
    NSDate *_dateStamp;
    NSNumber *_sequence;
    NSNumber *_timeStamp;
    NSDictionary *_attributes;


    NSUInteger _passNumber, _relativeOrder;
}

+ (ChatLogEntry*)entryWithSequence: (NSInteger)sequence timeStamp: (NSInteger)timeStamp attributes: (NSDictionary*)attribs;

+ (NSString*)nameForChatType: (NSString*)type;


@property (readwrite, assign) NSUInteger passNumber;
@property (readwrite, assign) NSUInteger relativeOrder;

@property (readwrite, retain) NSDate *dateStamp;        // date when PG finds the chat, not when it was actually sent
@property (readwrite, retain) NSNumber *timeStamp;      // number embedded by wow; isn't always right... i'm not actually sure what it is
@property (readwrite, retain) NSNumber *sequence;
@property (readwrite, retain) NSDictionary *attributes;

@property (readonly) NSString *type;
@property (readonly) NSString *typeName;
@property (readonly) NSString *typeVerb;
@property (readonly) NSString *channel;
@property (readonly) NSString *playerName;
@property (readonly) NSString *text;

@property (readonly) BOOL isEmote;
@property (readonly) BOOL isSpoken;
@property (readonly) BOOL isWhisper;
@property (readonly) BOOL isWhisperSent;
@property (readonly) BOOL isWhisperReceived;
@property (readonly) BOOL isChannel;

@property (readonly) NSArray *whisperTypes;

@property (readonly) NSString *wellFormattedText;

@end
