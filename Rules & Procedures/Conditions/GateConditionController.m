//
//  GateConditionController.m
//  Pocket Gnome
//
//  Created by Josh on 2/9/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "GateConditionController.h"
#import "ConditionController.h"

@implementation GateConditionController

- (id) init
{
    self = [super init];
    if (self != nil) {
        if(![NSBundle loadNibNamed: @"GateCondition" owner: self]) {
            log(LOG_GENERAL, @"Error loading GateCondition.nib.");
            
            [self release];
            self = nil;
        }
    }
    return self;
}

- (IBAction)validateState: (id)sender {
	
}

- (Condition*)condition {
    [self validateState: nil];
    
    Condition *condition = [Condition conditionWithVariety: VarietyGate 
                                                      unit: UnitNone
                                                   quality: [qualityPopUp selectedTag]
                                                comparator: [comparatorSegment selectedTag]
                                                     state: StateNone
                                                      type: TypeNone
                                                     value: nil];
    [condition setEnabled: self.enabled];
    
    return condition;
}

- (void)setStateFromCondition: (Condition*)condition {
    [super setStateFromCondition: condition];
	
    if( [condition variety] != VarietyGate) return;
	
	[comparatorSegment selectSegmentWithTag: [condition comparator]];
	[qualityPopUp selectItemWithTag: [condition quality]];
    
    [self validateState: nil];
}

@end
