//
//  TotemConditionController.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 7/8/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import "TotemConditionController.h"


@implementation TotemConditionController

- (id) init {
    self = [super init];
    if (self != nil) {
        if(![NSBundle loadNibNamed: @"TotemCondition" owner: self]) {
            log(LOG_GENERAL, @"Error loading TotemCondition.nib.");
            
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
    
    Condition *condition = [Condition conditionWithVariety: VarietyTotem 
                                                      unit: UnitPlayer
                                                   quality: QualityTotem
                                                comparator: [[comparatorPopUp selectedItem] tag]
                                                     state: 0
                                                      type: TypeString
                                                     value: [valueText stringValue]];
    [condition setEnabled: self.enabled];
    
    return condition;
}

- (void)setStateFromCondition: (Condition*)condition {
    [super setStateFromCondition: condition];

    if( [condition variety] != VarietyTotem) return;
    
    //[unitSegment selectSegmentWithTag: [condition unit]];
        
    if(![comparatorPopUp selectItemWithTag: [condition comparator]]) {
        [comparatorPopUp selectItemWithTag: CompareExists];
    }
    
    if([condition value]) {
        [valueText setStringValue: [condition value]];
    } else {
        [valueText setStringValue: @""];
    }
    
    [self validateState: nil];
}
@end
