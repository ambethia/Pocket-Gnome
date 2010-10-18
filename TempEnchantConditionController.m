//
//  TempEnchantConditionController.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 7/20/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import "TempEnchantConditionController.h"


@implementation TempEnchantConditionController

- (id) init {
    self = [super init];
    if (self != nil) {
        if(![NSBundle loadNibNamed: @"TempEnchantCondition" owner: self]) {
            log(LOG_GENERAL, @"Error loading TempEnchantCondition.nib.");
            
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
    
    Condition *condition = [Condition conditionWithVariety: VarietyTempEnchant 
                                                      unit: UnitPlayer
                                                   quality: [qualitySegment selectedTag]
                                                comparator: [[comparatorPopUp selectedItem] tag]
                                                     state: StateNone
                                                      type: TypeNone
                                                     value: nil];
    [condition setEnabled: self.enabled];
    
    return condition;
}

- (void)setStateFromCondition: (Condition*)condition {
    [super setStateFromCondition: condition];

    if( [condition variety] != VarietyTempEnchant) return;
    
    [qualitySegment selectSegmentWithTag: [condition quality]];
        
    if(![comparatorPopUp selectItemWithTag: [condition comparator]]) {
        [comparatorPopUp selectItemWithTag: CompareDoesNotExist];
    }
    
    [self validateState: nil];
}

@end
