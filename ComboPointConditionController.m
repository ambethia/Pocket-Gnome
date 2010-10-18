//
//  ComboPointConditionController.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 5/7/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import "ComboPointConditionController.h"


@implementation ComboPointConditionController

- (id) init {
    self = [super init];
    if (self != nil) {
        if(![NSBundle loadNibNamed: @"ComboPointCondition" owner: self]) {
            log(LOG_GENERAL, @"Error loading ComboPointCondition.nib.");
            
            [self release];
            self = nil;
        }
    }
    return self;
}

- (IBAction)validateState: (id)sender {

    // correct the quantity
    int quantity = [valueText intValue];
    if(quantity < 0) { quantity = 0; [valueText setIntValue: 0]; }
    if(quantity > 5) { quantity = 5; [valueText setIntValue: 5]; }

    // correct compare segment
    if( (quantity == 0) && ([[comparatorPopUp selectedItem] tag] == CompareLess)) {
        [comparatorPopUp selectItemWithTag: CompareEqual];
    }
    if( (quantity == 5) && ([[comparatorPopUp selectedItem] tag] == CompareMore)) {
        [comparatorPopUp selectItemWithTag: CompareEqual];
    }
}

- (Condition*)condition {
    [self validateState: nil];
    
    id value = [NSNumber numberWithInt: [valueText intValue]];
    
    Condition *condition = [Condition conditionWithVariety: VarietyComboPoints 
                                                      unit: UnitPlayer 
                                                   quality: QualityComboPoints
                                                comparator: [[comparatorPopUp selectedItem] tag] 
                                                     state: StateNone
                                                      type: TypeNone
                                                     value: value];
    [condition setEnabled: self.enabled];
    
    return condition;
}

- (void)setStateFromCondition: (Condition*)condition {
    [super setStateFromCondition: condition];

    if( [condition variety] != VarietyComboPoints) return;
    
    //[unitSegment selectSegmentWithTag: [condition unit]];
    //[qualitySegment selectSegmentWithTag: [condition quality]];
    //[comparatorSegment selectSegmentWithTag: [condition comparator]];

    if(![comparatorPopUp selectItemWithTag: [condition comparator]]) {
        [comparatorPopUp selectItemWithTag: CompareMore];
    }
    
    if( [condition value] )
        [valueText setIntValue: [[condition value] intValue]];
    else
        [valueText setIntValue: 0];
}


@end
