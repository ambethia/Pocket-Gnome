//
//  QuestConditionController.m
//  Pocket Gnome
//
//  Created by Josh on 1/13/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "QuestConditionController.h"


@implementation QuestConditionController

- (id) init
{
    self = [super init];
    if (self != nil) {
        if(![NSBundle loadNibNamed: @"QuestCondition" owner: self]) {
            log(LOG_GENERAL, @"Error loading QuestCondition.nib.");
            
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
    
    Condition *condition = [Condition conditionWithVariety: VarietyQuest 
                                                      unit: UnitNone
                                                   quality: QualityNone
                                                comparator: CompareNone
                                                     state: StateNone
                                                      type: TypeValue
                                                     value: nil];
    [condition setEnabled: self.enabled];
    
    return condition;
}

- (void)setStateFromCondition: (Condition*)condition {
    [super setStateFromCondition: condition];
    if( [condition variety] != VarietyQuest) return;

}

@end
