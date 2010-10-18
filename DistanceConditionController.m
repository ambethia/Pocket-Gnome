//
//  DistanceConditionController.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 1/18/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import "DistanceConditionController.h"
#import "ConditionController.h"
#import "BetterSegmentedControl.h"


@implementation DistanceConditionController

- (id) init {
    self = [super init];
    if (self != nil) {
        if(![NSBundle loadNibNamed: @"DistanceCondition" owner: self]) {
            log(LOG_GENERAL, @"Error loading DistanceCondition.nib.");
            
            [self release];
            self = nil;
        }
    }
    return self;
}

- (IBAction)validateState: (id)sender {
    //[qualitySegment selectSegmentWithTag: QualityDistance];
}

- (Condition*)condition {
    [self validateState: nil];
    
    id value = [NSNumber numberWithFloat: [valueText floatValue]];
    
    Condition *condition = [Condition conditionWithVariety: VarietyDistance 
                                                      unit: UnitTarget
                                                   quality: QualityDistance
                                                comparator: [[comparatorPopUp selectedItem] tag] 
                                                     state: StateNone
                                                      type: TypeNone
                                                     value: value];
    [condition setEnabled: self.enabled];
    
    return condition;
}

- (void)setStateFromCondition: (Condition*)condition {
    [super setStateFromCondition: condition];

    if( [condition variety] != VarietyDistance) return;
    
    //[unitSegment selectSegmentWithTag: [condition unit]];
    //[qualitySegment selectSegmentWithTag: [condition quality]];
    //[comparatorSegment selectSegmentWithTag: [condition comparator]];
    
    if(![comparatorPopUp selectItemWithTag: [condition comparator]]) {
        [comparatorPopUp selectItemWithTag: CompareMore];
    }
    
    if( [condition value] )
        [valueText setStringValue: [[condition value] stringValue]];
    else
        [valueText setStringValue: @"10.0"];
}

@end
