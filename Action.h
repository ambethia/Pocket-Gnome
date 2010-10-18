//
//  Action.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 9/6/08.
//  Copyright 2008 Jon Drummond. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum ActionType {
    ActionType_None				= 0,
    ActionType_Spell			= 1,
    ActionType_Item				= 2,
    ActionType_Macro			= 3,
    ActionType_Delay			= 4,
    ActionType_InteractNPC		= 5,
	ActionType_Jump				= 6,
	ActionType_SwitchRoute		= 7,
	ActionType_QuestTurnIn		= 8,
	ActionType_QuestGrab		= 9,
	ActionType_Vendor			= 10,
	ActionType_Mail				= 11,
	ActionType_Repair			= 12,
	ActionType_ReverseRoute		= 13,
	ActionType_CombatProfile	= 14,
    ActionType_InteractObject	= 15,
	ActionType_JumpToWaypoint	= 16,
    ActionType_Max,
} ActionType;

@class RouteSet;

@interface Action : NSObject <NSCoding, NSCopying>  {
    ActionType	_type;
    id			_value;
	BOOL        _enabled;
}

- (id)initWithType: (ActionType)type value: (id)value;
+ (id)actionWithType: (ActionType)type value: (id)value;
+ (id)action;

@property (readwrite, assign) ActionType type;
@property (readwrite, copy) id value;

@property BOOL enabled;

// in order to play nice with old code
@property (readonly) float      delay;
@property (readonly) UInt32     actionID;

- (RouteSet*)route;

@end
