//
//  DurabilityConditionController.m
//  Pocket Gnome
//
//  Created by Josh on 1/13/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "DurabilityConditionController.h"
#import "ConditionController.h"
#import "Condition.h"

#import "BetterSegmentedControl.h"

@implementation DurabilityConditionController

- (id) init
{
    self = [super init];
    if (self != nil) {
        if(![NSBundle loadNibNamed: @"DurabilityCondition" owner: self]) {
            log(LOG_GENERAL, @"Error loading DurabilityCondition.nib.");
            
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
    
    Condition *condition = [Condition conditionWithVariety: VarietyDurability 
                                                      unit: UnitNone
                                                   quality: QualityNone
                                                comparator: [comparatorSegment selectedTag]
                                                     state: StateNone
                                                      type: TypeValue
                                                     value: [NSNumber numberWithInt:[quantityText intValue]]];
    [condition setEnabled: self.enabled];
    
    return condition;
}

- (void)setStateFromCondition: (Condition*)condition {
    [super setStateFromCondition: condition];
    if( [condition variety] != VarietyDurability) return;
    
    [comparatorSegment selectSegmentWithTag: [condition comparator]];

    [quantityText setStringValue: [[condition value] stringValue]];
}

@end
