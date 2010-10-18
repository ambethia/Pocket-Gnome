//
//  ProximityCountConditionController.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 8/17/08.
//  Copyright 2008 Jon Drummond. All rights reserved.
//

#import "ProximityCountConditionController.h"


@implementation ProximityCountConditionController

- (id) init {
    self = [super init];
    if (self != nil) {
        if(![NSBundle loadNibNamed: @"ProximityCount" owner: self]) {
            log(LOG_GENERAL, @"Error loading ProximityCount.nib.");
            
            [self release];
            self = nil;
        }
    }
    return self;
}

- (IBAction)validateState: (id)sender {
    if( ([comparatorSegment selectedTag] == CompareLess) && ([countText intValue] == 0)) {
        [comparatorSegment selectSegmentWithTag: CompareEqual];
        NSBeep();
    }
    
    if([countText intValue] < 0) {
        [countText setIntValue: 0];
    }
    if([distanceText floatValue] < 0.0f) {
        [distanceText setFloatValue: 0.0f];
    }
}

- (Condition*)condition {
    [self validateState: nil];
    
    Condition *condition = [Condition conditionWithVariety: VarietyProximityCount 
                                                      unit: [unitSegment selectedTag]
                                                   quality: QualityNone
                                                comparator: [comparatorSegment selectedTag]
                                                     state: [countText intValue]
                                                      type: TypeValue
                                                     value: [NSNumber numberWithFloat: [distanceText floatValue]]];
    [condition setEnabled: self.enabled];
    
    return condition;
}

- (void)setStateFromCondition: (Condition*)condition {
    [super setStateFromCondition: condition];

    if( [condition variety] != VarietyProximityCount) return;
    
    [unitSegment selectSegmentWithTag: [condition unit]];
    [comparatorSegment selectSegmentWithTag: [condition comparator]];

    [countText setIntValue: [condition state]];
    [distanceText setObjectValue: [condition value]];

    [self validateState: nil];
}

@end
