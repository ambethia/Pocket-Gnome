//
//  StatusRuleController.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 1/3/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import "StatusConditionController.h"
#import "ConditionController.h"
#import "BetterSegmentedControl.h"


@implementation StatusConditionController

- (id) init {
    self = [super init];
    if (self != nil) {
        if(![NSBundle loadNibNamed: @"StatusCondition" owner: self]) {
            log(LOG_GENERAL, @"Error loading StatusCondition.nib.");
            previousState = 1;
            [self release];
            self = nil;
        }
    }
    return self;
}

- (IBAction)validateState: (id)sender {
    if( ([[unitPopUp selectedItem] tag] != UnitPlayer) && ([stateSegment selectedTag] == StateIndoors)) {
        NSBeep();
        if(previousState == StateIndoors) {
            [unitPopUp selectItemWithTag: UnitPlayer];
        } else {
            [stateSegment selectSegmentWithTag: previousState];
        }
        return;
    }
    
    previousState = [stateSegment selectedTag];
}

- (Condition*)condition {
    [self validateState: nil];
    
    Condition *condition = [Condition conditionWithVariety: VarietyStatus 
                                                      unit: [[unitPopUp selectedItem] tag]
                                                   quality: QualityNone
                                                comparator: [comparatorSegment selectedTag] 
                                                     state: [stateSegment selectedTag]
                                                      type: TypeNone
                                                     value: nil];
    [condition setEnabled: self.enabled];
    
    return condition;
}

- (void)setStateFromCondition: (Condition*)condition {
    [super setStateFromCondition: condition];
    if( [condition variety] != VarietyStatus) return;
    
    if(![unitPopUp selectItemWithTag: [condition unit]]) {
        [unitPopUp selectItemWithTag: UnitPlayer];
    }
    [comparatorSegment selectSegmentWithTag: [condition comparator]];
    [stateSegment selectSegmentWithTag: [condition state]];
}

@end
