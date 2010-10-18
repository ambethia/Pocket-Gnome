//
//  Rule.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 1/4/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Action.h"

/*typedef enum RuleResult {
    ResultNone      = 0,
    ResultSpell     = 1,
    ResultItem      = 2,
    ResultMacro     = 3,
    ResultSpecial   = 4,
} ResultType;*/

typedef enum TargetType {
	TargetNone = 0,
	TargetSelf = 1,
	TargetEnemy = 2,
	TargetFriend = 3,	
	TargetAdd = 4,
	TargetPet = 5,
	TargetFriendlies = 6,
	TargetPat = 7,
} TargetType;

@interface Rule : NSObject <NSCoding, NSCopying> {
    BOOL _matchAll;
    NSString *_name;
    NSMutableArray *_conditionsList;
    
    Action *_action;
	int _target;
    
    //ResultType _resultType;
    //unsigned _actionID;
}

@property (readwrite, copy) NSString *name;
@property BOOL isMatchAll;
@property (readwrite, copy) Action *action;
//@property ResultType resultType;
//@property unsigned actionID;
@property (readwrite, retain) NSArray *conditions;
@property (readwrite, assign) int target;

// play nice methods
@property (readonly) ActionType resultType;
@property (readonly) UInt32 actionID;

@end
