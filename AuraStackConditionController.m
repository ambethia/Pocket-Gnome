//
//  AuraStackConditionController.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 7/1/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import "AuraStackConditionController.h"


@implementation AuraStackConditionController

- (id) init {
    self = [super init];
    if (self != nil) {
        if(![NSBundle loadNibNamed: @"AuraStackCondition" owner: self]) {
            log(LOG_GENERAL, @"Error loading AuraStackCondition nib.");
            
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
    
    int stackCount = [stackText intValue];
    
    id value = nil;
    if( [typeSegment selectedTag] == TypeValue )
        value = [NSNumber numberWithInt: [auraText intValue]];
    if( [typeSegment selectedTag] == TypeString )
        value = [auraText stringValue];
    
    Condition *condition = [Condition conditionWithVariety: VarietyAuraStack 
                                                      unit: [[unitPopUp selectedItem] tag]
                                                   quality: [[qualityPopUp selectedItem] tag]
                                                comparator: [[comparatorPopUp selectedItem] tag]
                                                     state: stackCount
                                                      type: [typeSegment selectedTag]
                                                     value: value];
    [condition setEnabled: self.enabled];
    
    return condition;
}

- (void)setStateFromCondition: (Condition*)condition {
    [super setStateFromCondition: condition];

    if( [condition variety] != VarietyAuraStack) return;
    
    if(![unitPopUp selectItemWithTag: [condition unit]]) {
        [qualityPopUp selectItemWithTag: UnitPlayer];
    }

    if(![qualityPopUp selectItemWithTag: [condition quality]]) {
        [qualityPopUp selectItemWithTag: QualityBuff];
    }
    
    if(![comparatorPopUp selectItemWithTag: [condition comparator]]) {
        [comparatorPopUp selectItemWithTag: CompareMore];
    }
    
    [stackText setStringValue: [NSString stringWithFormat: @"%d", [condition state]]];
    [auraText setStringValue: [NSString stringWithFormat: @"%@", [condition value]]];
    
    [typeSegment selectSegmentWithTag: [condition type]];
    
    [self validateState: nil];
    
    //if([condition type] == TypeValue)
    //else
    // [valueText setStringValue: [condition value]];
}

@end
