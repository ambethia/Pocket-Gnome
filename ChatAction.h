//
//  ChatAction.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 4/5/09.
//  Copyright 2009 Savory Software, LLC. All rights reserved.
//

// THIS CLASS IS IN NO WAY READY FOR ANYTHING.

#import <Cocoa/Cocoa.h>


@interface ChatAction : NSObject <NSCopying> {
    NSString *_name;
    NSPredicate *_predicate;
    BOOL _actionStopBot, _actionStartBot;
    BOOL _actionQuit, _actionHearth;
    BOOL _actionEmail, _actionIM;
    NSString *_emailAddress, *_imName;
}

+ (ChatAction*)chatActionWithName: (NSString*)name;

@property (readwrite, retain) NSString *name;
@property (readwrite, retain) NSPredicate *predicate;

@property (readwrite, assign) BOOL actionStopBot;
@property (readwrite, assign) BOOL actionHearth;
@property (readwrite, assign) BOOL actionQuit;
@property (readwrite, assign) BOOL actionStartBot;
@property (readwrite, assign) BOOL actionEmail;
@property (readwrite, assign) BOOL actionIM;

@property (readwrite, retain) NSString *emailAddress;
@property (readwrite, retain) NSString *imName;

@end
