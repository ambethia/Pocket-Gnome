//
//  SpellCooldownConditionController.m
//  Pocket Gnome
//
//  Created by Josh on 12/7/09.
//  Copyright 2009 Savory Software, LLC. All rights reserved.
//

#import "SpellCooldownConditionController.h"


@implementation SpellCooldownConditionController

- (id) init {
    self = [super init];
    if (self != nil) {
        if(![NSBundle loadNibNamed: @"SpellCooldown" owner: self]) {
            log(LOG_GENERAL, @"Error loading SpellCooldown.nib.");
            
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
    
    id value = nil;
    if( [typeSegment selectedTag] == TypeValue )
        value = [NSNumber numberWithInt: [valueText intValue]];
    if( [typeSegment selectedTag] == TypeString )
        value = [valueText stringValue];
    
    Condition *condition = [Condition conditionWithVariety: VarietySpellCooldown 
                                                      unit: UnitNone
                                                   quality: QualityNone
                                                comparator: [comparatorSegment selectedTag]
                                                     state: StateNone
                                                      type: [typeSegment selectedTag]
                                                     value: value];
    [condition setEnabled: self.enabled];
    
    return condition;
}

- (void)setStateFromCondition: (Condition*)condition {
    [super setStateFromCondition: condition];
	
    if( [condition variety] != VarietySpellCooldown) return;
    
    [typeSegment selectSegmentWithTag: [condition type]];
	[comparatorSegment selectSegmentWithTag: [condition comparator]];
	[valueText setStringValue:[NSString stringWithFormat:@"%@", [condition value]]];
	
    [self validateState: nil];
}

@end
