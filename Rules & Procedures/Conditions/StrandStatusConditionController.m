//
//  StrandStatusConditionController.m
//  Pocket Gnome
//
//  Created by Josh on 2/10/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "StrandStatusConditionController.h"
#import "ConditionController.h"

@implementation StrandStatusConditionController

- (id) init
{
    self = [super init];
    if (self != nil) {
        if(![NSBundle loadNibNamed: @"StrandStatus" owner: self]) {
            log(LOG_GENERAL, @"Error loading StrandStatus.nib.");
            
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
    
    Condition *condition = [Condition conditionWithVariety: VarietyStrandStatus 
                                                      unit: UnitNone
                                                   quality: [qualityPopUp selectedTag]
                                                comparator: CompareNone
                                                     state: StateNone
                                                      type: TypeNone
                                                     value: nil];
    [condition setEnabled: self.enabled];
    
    return condition;
}

- (void)setStateFromCondition: (Condition*)condition {
    [super setStateFromCondition: condition];
	
    if( [condition variety] != VarietyStrandStatus) return;
	
	[qualityPopUp selectItemWithTag: [condition quality]];
    
    [self validateState: nil];
}

@end
