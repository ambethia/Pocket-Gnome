//
//  CombatCountConditionController.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 8/17/08.
//  Copyright 2008 Jon Drummond. All rights reserved.
//

#import "CombatCountConditionController.h"


@implementation CombatCountConditionController

- (id) init {
    self = [super init];
    if (self != nil) {
        if(![NSBundle loadNibNamed: @"CombatCount" owner: self]) {
            log(LOG_GENERAL, @"Error loading CombatCount.nib.");
            
            [self release];
            self = nil;
        }
    }
    return self;
}

- (IBAction)validateState: (id)sender {
    if( ([comparatorSegment selectedTag] == CompareLess) && ([valueText intValue] == 0)) {
        [comparatorSegment selectSegmentWithTag: CompareEqual];
        NSBeep();
    }
    
    if([valueText intValue] < 0) {
        [valueText setIntValue: 0];
    }
}

- (Condition*)condition {
    [self validateState: nil];
    
    int value = [valueText intValue];
    if(value < 0) value = 0;
    
    Condition *condition = [Condition conditionWithVariety: VarietyCombatCount 
                                                      unit: UnitPlayer
                                                   quality: QualityNone
                                                comparator: [comparatorSegment selectedTag]
                                                     state: value
                                                      type: TypeNone
                                                     value: nil];
    [condition setEnabled: self.enabled];
    
    return condition;
}

- (void)setStateFromCondition: (Condition*)condition {
    [super setStateFromCondition: condition];

    if( [condition variety] != VarietyCombatCount) return;
    
    [comparatorSegment selectSegmentWithTag: [condition comparator]];
    [valueText setStringValue: [NSString stringWithFormat: @"%d", [condition state]]];

    [self validateState: nil];
}

@end
