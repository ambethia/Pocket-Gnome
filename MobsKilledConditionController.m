//
//  MobsKilledConditionController.m
//  Pocket Gnome
//
//  Created by Josh on 1/23/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "MobsKilledConditionController.h"
#import "ConditionController.h"

#import "BetterSegmentedControl.h"

@implementation MobsKilledConditionController


- (id) init
{
    self = [super init];
    if (self != nil) {
        if(![NSBundle loadNibNamed: @"MobsKilledCondition" owner: self]) {
            log(LOG_GENERAL, @"Error loading MobsKilledCondition.nib.");
            
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
    
    int mobKillCount = [killCountText intValue];
    
    id value = nil;
    if( [typeSegment selectedTag] == TypeValue )
        value = [NSNumber numberWithInt: [mobText intValue]];
    if( [typeSegment selectedTag] == TypeString )
        value = [mobText stringValue];
    
    Condition *condition = [Condition conditionWithVariety: VarietyMobsKilled 
                                                      unit: UnitNone
                                                   quality: QualityNone
                                                comparator: [comparatorSegment selectedTag]
                                                     state: mobKillCount
                                                      type: [typeSegment selectedTag]
                                                     value: value];
    [condition setEnabled: self.enabled];
    
    return condition;
}

- (void)setStateFromCondition: (Condition*)condition {
    [super setStateFromCondition: condition];
	
    if( [condition variety] != VarietyMobsKilled) return;
	
	[comparatorSegment selectSegmentWithTag: [condition comparator]];
    [mobText setStringValue: [NSString stringWithFormat: @"%@", [condition value]]];
    [killCountText setStringValue: [NSString stringWithFormat: @"%d", [condition state]]];
    [typeSegment selectSegmentWithTag: [condition type]];
    
    [self validateState: nil];
}


@end
