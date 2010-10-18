//
//  ChatAction.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 4/5/09.
//  Copyright 2009 Savory Software, LLC. All rights reserved.
//

#import "ChatAction.h"


@implementation ChatAction

- (id) init
{
    self = [super init];
    if (self != nil) {
        self.name = nil;
        self.predicate = nil;
        self.emailAddress = nil;
        self.imName = nil;
    }
    return self;
}

- (void) dealloc
{
    self.name = nil;
    self.predicate = nil;
    self.emailAddress = nil;
    self.imName = nil;
    [super dealloc];
}

+ (ChatAction*)chatActionWithName: (NSString*)name {
    ChatAction *newAction = [[ChatAction alloc] init];
    newAction.name = name;
    return [newAction autorelease];
}

- (id)copyWithZone: (NSZone*)zone {
    ChatAction *newAction = [[ChatAction alloc] init];
    newAction.name = self.name;
    newAction.predicate = self.predicate;
    newAction.actionStopBot = self.actionStopBot;
    newAction.actionStartBot = self.actionStartBot;
    newAction.actionHearth = self.actionHearth;
    newAction.actionQuit = self.actionQuit;
    newAction.actionEmail = self.actionEmail;
    newAction.actionIM = self.actionIM;
    newAction.emailAddress = self.emailAddress;
    newAction.imName = self.imName;
    return newAction;
}

- (id)initWithCoder:(NSCoder *)decoder
{
	self = [self init];
	if(self) {
        self.name = [decoder decodeObjectForKey: @"Name"];
        self.predicate = [decoder decodeObjectForKey: @"Predicate"];
	}
	return self;
}

-(void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject: self.name forKey: @"Name"];
    [coder encodeObject: self.predicate forKey: @"Predicate"];
}


@synthesize name = _name;
@synthesize predicate = _predicate;
@synthesize actionStopBot = _actionStopBot;
@synthesize actionHearth = _actionHearth;
@synthesize actionQuit = _actionQuit;
@synthesize actionStartBot = _actionStartBot;
@synthesize actionEmail = _actionEmail;
@synthesize actionIM = _actionIM;

@synthesize emailAddress = _emailAddress;
@synthesize imName = _imName;


@end
